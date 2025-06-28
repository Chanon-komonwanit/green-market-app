import 'package:cloud_firestore/cloud_firestore.dart';
// lib/models/project_update.dart

class ProjectUpdate {
  final String id;
  final String projectId;
  final String title;
  final String updateText;
  final String userId;
  final String userName;
  final Timestamp createdAt;

  ProjectUpdate({
    required this.id,
    required this.projectId,
    required this.title,
    required this.updateText,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory ProjectUpdate.fromMap(Map<String, dynamic> map) {
    return ProjectUpdate(
      id: map['id'] as String,
      projectId: map['projectId'] as String,
      title: map['title'] as String,
      updateText: map['updateText'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'updateText': updateText,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt,
    };
  }
}
