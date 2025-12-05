// lib/widgets/hashtag_text_widget.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../screens/hashtag_feed_screen.dart';

/// Widget สำหรับแสดงข้อความที่มี hashtag และ mentions
/// ทำให้ hashtag และ @ คลิกได้
class HashtagTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const HashtagTextWidget({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: style ?? AppTextStyles.body,
        children: _buildTextSpans(context),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(#\w+|@\w+|\S+|\s+)');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final word = match.group(0)!;

      if (word.startsWith('#')) {
        // Hashtag - คลิกได้
        spans.add(
          TextSpan(
            text: word,
            style: (style ?? AppTextStyles.body).copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final hashtag = word.substring(1); // เอา # ออก
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HashtagFeedScreen(hashtag: hashtag),
                  ),
                );
              },
          ),
        );
      } else if (word.startsWith('@')) {
        // Mention - คลิกได้
        spans.add(
          TextSpan(
            text: word,
            style: (style ?? AppTextStyles.body).copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // TODO: Navigate to user profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ดูโปรไฟล์ $word')),
                );
              },
          ),
        );
      } else {
        // ข้อความธรรมดา
        spans.add(
          TextSpan(
            text: word,
            style: style ?? AppTextStyles.body,
          ),
        );
      }
    }

    return spans;
  }
}
