import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'memory_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  Future<void> syncReflections() async {
    if (!_isEnabled) return;
    
    try {
      final reflections = await MemoryService.instance.getAllReflections();
      final batch = _firestore.batch();
      
      for (var reflection in reflections) {
        final docRef = _firestore.collection('reflections').doc(reflection['id']);
        batch.set(docRef, {
          ...reflection,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      // Sync failed, will retry later
    }
  }

  Future<void> syncHazards() async {
    if (!_isEnabled) return;
    
    try {
      final hazards = await MemoryService.instance.getAllHazards();
      final batch = _firestore.batch();
      
      for (var hazard in hazards) {
        final docRef = _firestore.collection('hazards').doc(hazard['id']);
        batch.set(docRef, {
          ...hazard,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      // Sync failed
    }
  }

  Future<void> syncLessons() async {
    if (!_isEnabled) return;
    
    try {
      final lessons = await MemoryService.instance.getAllLessons();
      final batch = _firestore.batch();
      
      for (var lesson in lessons) {
        final docRef = _firestore.collection('lessons').doc(lesson['id']);
        batch.set(docRef, {
          ...lesson,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      // Sync failed
    }
  }

  Future<String?> uploadRecording(String localPath, String fileName) async {
    if (!_isEnabled) return null;
    
    try {
      final ref = _storage.ref().child('recordings').child(fileName);
      await ref.putFile(io.File(localPath));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> syncAll() async {
    await Future.wait([
      syncReflections(),
      syncHazards(),
      syncLessons(),
    ]);
  }

  Stream<QuerySnapshot> watchReflections() {
    return _firestore.collection('reflections').snapshots();
  }

  Stream<QuerySnapshot> watchHazards() {
    return _firestore.collection('hazards').snapshots();
  }

  Stream<QuerySnapshot> watchLessons() {
    return _firestore.collection('lessons').snapshots();
  }
}
