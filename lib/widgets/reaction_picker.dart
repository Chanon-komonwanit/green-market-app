// lib/widgets/reaction_picker.dart
import 'package:flutter/material.dart';
import '../models/post_type.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String reaction) onReactionSelected;

  const ReactionPicker({super.key, required this.onReactionSelected});

  @override
  Widget build(BuildContext context) {
    final reactions = [
      Reaction.like,
      Reaction.love,
      Reaction.care,
      Reaction.wow,
      Reaction.haha,
      Reaction.sad,
      Reaction.angry,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((reaction) {
          return GestureDetector(
            onTap: () => onReactionSelected(reaction),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                Reaction.getEmoji(reaction),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
