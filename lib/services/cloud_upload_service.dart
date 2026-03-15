import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class CloudUploadService {
  static final CloudUploadService _instance = CloudUploadService._internal();
  factory CloudUploadService() => _instance;
  CloudUploadService._internal();

  // Google Drive
  String? _googleDriveAccessToken;
  
  // OneDrive  
  String? _oneDriveAccessToken;

  // Configuration
  void setGoogleDriveToken(String token) {
    _googleDriveAccessToken = token;
  }

  void setOneDriveToken(String token) {
    _oneDriveAccessToken = token;
  }

  bool get isGoogleDriveConfigured => _googleDriveAccessToken != null;
  bool get isOneDriveConfigured => _oneDriveAccessToken != null;

  // Upload to Google Drive
  Future<String?> uploadToGoogleDrive(File file, String folderName) async {
    if (_googleDriveAccessToken == null) return null;

    try {
      // Get folder ID
      final folderId = await _getOrCreateGoogleDriveFolder(folderName);
      if (folderId == null) return null;

      // Upload file
      final fileName = file.path.split('/').last;
      final fileBytes = await file.readAsBytes();
      final mimeType = _getMimeType(fileName);

      final metadata = {
        'name': fileName,
        'parents': [folderId],
      };

      final multipartRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart'),
      );

      multipartRequest.headers['Authorization'] = 'Bearer $_googleDriveAccessToken';
      multipartRequest.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
      multipartRequest.fields['metadata'] = jsonEncode(metadata);

      final response = await multipartRequest.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final fileData = jsonDecode(responseData);
        return fileData['id'];
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<String?> _getOrCreateGoogleDriveFolder(String folderName) async {
    // Search for existing folder
    final searchResponse = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files?q=name="$folderName"%20and%20mimeType="application/vnd.google-apps.folder"'),
      headers: {'Authorization': 'Bearer $_googleDriveAccessToken'},
    );

    if (searchResponse.statusCode == 200) {
      final data = jsonDecode(searchResponse.body);
      if (data['files'].isNotEmpty) {
        return data['files'][0]['id'];
      }
    }

    // Create new folder
    final createResponse = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $_googleDriveAccessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (createResponse.statusCode == 200) {
      final data = jsonDecode(createResponse.body);
      return data['id'];
    }
    return null;
  }

  // Upload to OneDrive
  Future<String?> uploadToOneDrive(File file, String folderName) async {
    if (_oneDriveAccessToken == null) return null;

    try {
      final fileName = file.path.split('/').last;
      final fileBytes = await file.readAsBytes();

      // Get folder ID
      final folderId = await _getOrCreateOneDriveFolder(folderName);
      
      final response = await http.put(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$folderId:/$fileName:/content'),
        headers: {
          'Authorization': 'Bearer $_oneDriveAccessToken',
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['webUrl'];
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<String> _getOrCreateOneDriveFolder(String folderName) async {
    try {
      // Try to get root folder
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root'),
        headers: {'Authorization': 'Bearer $_oneDriveAccessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
    } catch (e) {
      // Handle error
    }
    return 'root';
  }

  // Generic upload to configured cloud
  Future<String?> uploadToCloud(File file, {String? folderName}) async {
    final folder = folderName ?? 'LIORA_Exports';
    
    // Try Google Drive first
    if (isGoogleDriveConfigured) {
      final gdriveId = await uploadToGoogleDrive(file, folder);
      if (gdriveId != null) return gdriveId;
    }
    
    // Try OneDrive
    if (isOneDriveConfigured) {
      final onedriveUrl = await uploadToOneDrive(file, folder);
      if (onedriveUrl != null) return onedriveUrl;
    }
    
    return null;
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
