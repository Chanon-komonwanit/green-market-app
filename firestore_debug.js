// Add this to browser console to debug Firestore data directly
// Go to Firebase Console -> Firestore -> Run query manually

// JavaScript code to run in browser console:
console.log('Starting Firestore Debug...');

// Query all products
db.collection('products').get().then((snapshot) => {
    console.log('=== ALL PRODUCTS ===');
    console.log('Total products:', snapshot.size);

    snapshot.forEach((doc) => {
        const data = doc.data();
        console.log('Product ID:', doc.id);
        console.log('  Name:', data.name);
        console.log('  Status:', data.status);
        console.log('  isApproved:', data.isApproved);
        console.log('  sellerId:', data.sellerId);
        console.log('  createdAt:', data.createdAt);
        console.log('  approvedAt:', data.approvedAt);
        console.log('---');
    });
});

// Query approved products by status
db.collection('products').where('status', '==', 'approved').get().then((snapshot) => {
    console.log('=== APPROVED PRODUCTS (by status) ===');
    console.log('Count:', snapshot.size);

    snapshot.forEach((doc) => {
        const data = doc.data();
        console.log('Approved Product:', data.name, '(ID:', doc.id, ')');
    });
});

// Query approved products by isApproved field
db.collection('products').where('isApproved', '==', true).get().then((snapshot) => {
    console.log('=== APPROVED PRODUCTS (by isApproved) ===');
    console.log('Count:', snapshot.size);

    snapshot.forEach((doc) => {
        const data = doc.data();
        console.log('Approved Product:', data.name, '(ID:', doc.id, ')');
    });
});

// Query product requests
db.collection('product_requests').get().then((snapshot) => {
    console.log('=== PRODUCT REQUESTS ===');
    console.log('Total requests:', snapshot.size);

    snapshot.forEach((doc) => {
        const data = doc.data();
        console.log('Request ID:', doc.id);
        console.log('  Status:', data.status);
        console.log('  ProcessedAt:', data.processedAt);
        if (data.productData) {
            console.log('  Product Name:', data.productData.name);
        }
        console.log('---');
    });
});

console.log('Debug queries submitted. Check results above.');
