const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();

// CORS Handler สำหรับ Storage
exports.handleStorageCORS = functions.https.onRequest((req, res) => {
    return cors(req, res, () => {
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, HEAD, OPTIONS');
        res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Goog-Upload-Protocol');
        res.status(200).send('CORS enabled');
    });
});

// ==================== AUTO-CLEANUP SCHEDULER ====================

/**
 * รันทุกวันเวลา 3:00 AM (GMT+7) เพื่อลบ live streams ที่หมดอายุ
 * 
 * นโยบาย:
 * - Live streams ทั่วไป: เก็บ 7 วัน หลังจบ → ลบ
 * - Archived streams: เก็บถาวร (ไม่ลบ)  
 * - Deleted streams: ลบทันที
 */
exports.cleanupExpiredStreams = functions.pubsub
    .schedule('0 3 * * *') // ทุกวัน 3:00 AM
    .timeZone('Asia/Bangkok')
    .onRun(async (context) => {
        console.log('🔄 Starting expired streams cleanup...');

        const now = admin.firestore.Timestamp.now();
        const db = admin.firestore();

        // หา streams ที่หมดอายุแล้ว
        const expiredStreams = await db.collection('live_streams')
            .where('autoDeleteEnabled', '==', true)
            .where('deleteAt', '<=', now)
            .where('status', '==', 'ended')
            .get();

        console.log(`📊 Found ${expiredStreams.size} expired streams`);

        let deletedCount = 0;
        let errorCount = 0;

        for (const doc of expiredStreams.docs) {
            try {
                await deleteStream(doc.id, doc.data());
                deletedCount++;
            } catch (error) {
                console.error(`❌ Error deleting stream ${doc.id}:`, error);
                errorCount++;
            }
        }

        console.log(`✅ Cleanup completed: ${deletedCount} deleted, ${errorCount} errors`);

        return {
            success: true,
            deletedCount,
            errorCount,
        };
    });

async function deleteStream(streamId, streamData) {
    const db = admin.firestore();
    const storage = admin.storage();

    // ลบวิดีโอจาก Storage
    if (streamData.recordedVideoUrl) {
        try {
            const bucket = storage.bucket();
            const url = streamData.recordedVideoUrl;
            const filePath = url.split('/o/')[1]?.split('?')[0];
            if (filePath) {
                await bucket.file(decodeURIComponent(filePath)).delete();
            }
        } catch (error) {
            console.warn(`Could not delete video:`, error.message);
        }
    }

    // ลบ subcollections
    const collections = ['comments', 'viewers', 'likes'];
    for (const collName of collections) {
        const snapshot = await db.collection('live_streams').doc(streamId).collection(collName).limit(500).get();
        const batch = db.batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
    }

    // อัพเดทสถานะเป็น deleted
    await db.collection('live_streams').doc(streamId).update({
        status: 'deleted',
        recordedVideoUrl: admin.firestore.FieldValue.delete(),
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

// ==================== STORAGE SIZE MONITORING ====================

/**
 * ติดตามขนาด Storage และส่งการแจ้งเตือนเมื่อใกล้เต็ม
 * รันทุกวัน
 */
exports.monitorStorageSize = functions.pubsub
    .schedule('0 0 * * *') // ทุกวัน 00:00
    .timeZone('Asia/Bangkok')
    .onRun(async (context) => {
        console.log('📊 Monitoring storage size...');

        const bucket = admin.storage().bucket();

        try {
            const [files] = await bucket.getFiles({ prefix: 'live_streams/' });

            let totalSize = 0;
            for (const file of files) {
                const [metadata] = await file.getMetadata();
                totalSize += parseInt(metadata.size || 0);
            }

            const totalSizeGB = (totalSize / (1024 ** 3)).toFixed(2);

            console.log(`📦 Total live streams storage: ${totalSizeGB} GB`);

            if (totalSize > 4.5 * 1024 ** 3) {
                console.warn('⚠️ WARNING: Storage usage over 4.5GB!');
            }

            await admin.firestore().collection('storage_stats').add({
                totalSizeBytes: totalSize,
                totalSizeGB: parseFloat(totalSizeGB),
                fileCount: files.length,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });

            return { success: true, totalSizeGB, fileCount: files.length };
        } catch (error) {
            console.error('Error monitoring storage:', error);
            throw error;
        }
    });
