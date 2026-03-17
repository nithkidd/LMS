import 'package:firebase_database/firebase_database.dart';

class FirebaseHelper {
  FirebaseHelper._privateConstructor();
  static final FirebaseHelper instance = FirebaseHelper._privateConstructor();

  FirebaseDatabase get _database => FirebaseDatabase.instance;

  void enableOfflineCapabilities() {
    _database.setPersistenceEnabled(true);
    _database.setPersistenceCacheSizeBytes(10000000); // 10MB
  }

  DatabaseReference get schoolsRef => _database.ref('schools');
  DatabaseReference get classesRef => _database.ref('classes');
  DatabaseReference get subjectsRef => _database.ref('subjects');
  DatabaseReference get teachersRef => _database.ref('teachers');
  DatabaseReference get classTeacherSubjectRef => _database.ref('class_teacher_subject');
  DatabaseReference get studentsRef => _database.ref('students');
  DatabaseReference get assignmentsRef => _database.ref('assignments');
  DatabaseReference get scoresRef => _database.ref('scores');
}
