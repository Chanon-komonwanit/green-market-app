// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:green_market/models/news_article.dart';
import 'package:green_market/utils/constants.dart'; // Assuming AppTextStyles and AppColors are here
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // If you want to open external links

class NewsArticleDetailPage extends StatelessWidget {
  final NewsArticle article;

  const NewsArticleDetailPage({super.key, required this.article});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Consider showing a SnackBar or dialog to the user if launching fails
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.source,
            style: AppTextStyles.title.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              article.title,
              style: AppTextStyles.headline
                  .copyWith(color: AppColors.primaryDarkGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'เผยแพร่โดย: ${article.source} - ${DateFormat('dd MMM yyyy', 'th_TH').format(article.publishedDate)}',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.modernGrey),
            ),
            const Divider(height: 32, thickness: 1),
            if (article.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    article.imageUrl!,
                    width: double.infinity,
                    height: 220, // Slightly increased height
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 220,
                        // ignore: deprecated_member_use
                        color: AppColors.lightModernGrey.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 220,
                      // ignore: deprecated_member_use
                      color: AppColors.lightModernGrey.withOpacity(0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              size: 50, color: AppColors.modernGrey),
                          const SizedBox(height: 8),
                          Text("ไม่สามารถโหลดรูปภาพได้",
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.modernDarkGrey))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Text(
              article
                  .summary, // For now, we'll display the summary as main content
              style: AppTextStyles.body.copyWith(
                  fontSize: 17,
                  height: 1.55,
                  color: AppColors.modernDarkGrey), // Slightly adjusted style
            ),
            const SizedBox(height: 16),
            // Placeholder for full article content if available
            Text(
              "เนื้อหาข่าวฉบับเต็มจะแสดงที่นี่ (หากมีข้อมูลเพิ่มเติมจาก API หรือแหล่งข้อมูล). "
              "สำหรับตอนนี้ เราจะแสดงเพียงบทสรุปเท่านั้น "
              "คุณสามารถเพิ่มเนื้อหาเพิ่มเติมได้ตามต้องการ หรืออาจจะมีปุ่ม 'อ่านเพิ่มเติม' เพื่อไปยังแหล่งข่าวต้นฉบับ",
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.modernDarkGrey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            // Button to open original source if article.originalUrl is available
            // For this example, we'll assume NewsArticle model might have an 'originalUrl' field.
            // If not, you can adapt this to use article.source or another relevant field if it's a URL.
            if (article.originalUrl != null && article.originalUrl!.isNotEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _launchURL(article.originalUrl!);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightTeal,
                      foregroundColor: AppColors.white),
                  child: const Text('อ่านเพิ่มเติมจากแหล่งข่าว'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                    child: Text("ไม่มีลิงก์ไปยังแหล่งข่าวต้นฉบับ",
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.modernGrey))),
              ),
          ],
        ),
      ),
    );
  }
}
