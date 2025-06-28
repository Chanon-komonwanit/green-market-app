import 'package:cloud_firestore/cloud_firestore.dart';
// lib/models/project_question.dart

class ProjectQuestion {
  final String id;
  final String projectId;
  final String userId;
  final String userName;
  final String question;
  final Timestamp createdAt;
  final String? answer;
  final Timestamp? answeredAt;
  final String? answeredByUserId;
  final String? answeredByName;

  ProjectQuestion({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userName,
    required this.question,
    required this.createdAt,
    this.answer,
    this.answeredAt,
    this.answeredByUserId,
    this.answeredByName,
  });

  factory ProjectQuestion.fromMap(Map<String, dynamic> map) {
    return ProjectQuestion(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      question: map['question'] as String,
      createdAt: map['createdAt'] as Timestamp,
      answer: map['answer'] as String?,
      answeredAt: map['answeredAt'] as Timestamp?,
      answeredByUserId: map['answeredByUserId'] as String?,
      answeredByName: map['answeredByName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'userId': userId,
      'userName': userName,
      'question': question,
      'createdAt': createdAt,
      'answer': answer,
      'answeredAt': answeredAt,
      'answeredByUserId': answeredByUserId,
      'answeredByName': answeredByName,
    };
  }
}
