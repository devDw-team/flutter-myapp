import 'dart:io';
import 'package:exif/exif.dart';

class PhotoLocationService {
  static Future<Map<String, double>?> extractLocationFromPhoto(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final data = await readExifFromBytes(bytes);
      
      if (data.isEmpty) {
        return null;
      }

      final latitudeRef = data['GPS GPSLatitudeRef']?.toString();
      final longitudeRef = data['GPS GPSLongitudeRef']?.toString();
      final latitudeData = data['GPS GPSLatitude']?.values;
      final longitudeData = data['GPS GPSLongitude']?.values;

      if (latitudeData == null || longitudeData == null) {
        return null;
      }

      final latitude = _convertDMSToDD(latitudeData, latitudeRef);
      final longitude = _convertDMSToDD(longitudeData, longitudeRef);

      if (latitude == null || longitude == null) {
        return null;
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      print('EXIF 데이터 추출 실패: $e');
      return null;
    }
  }

  static double? _convertDMSToDD(IfdValues dms, String? ref) {
    try {
      final dmsList = dms.toList();
      if (dmsList.length != 3) return null;

      final degrees = (dmsList[0] as Ratio).toDouble();
      final minutes = (dmsList[1] as Ratio).toDouble();
      final seconds = (dmsList[2] as Ratio).toDouble();

      double dd = degrees + (minutes / 60.0) + (seconds / 3600.0);

      if (ref == 'S' || ref == 'W') {
        dd = -dd;
      }

      return dd;
    } catch (e) {
      print('DMS to DD 변환 실패: $e');
      return null;
    }
  }
}