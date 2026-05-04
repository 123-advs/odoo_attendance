import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;

import '../../core/constants/api_constants.dart';
import '../../core/constants/face_constants.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../models/attendance_model.dart';
import '../models/employee_model.dart';

class OdooProvider {
  Dio get _dio => Get.find<ApiService>().dio;
  StorageService get _storage => Get.find<StorageService>();

  Future<int?> login({
    required String login,
    required String password,
  }) async {
    final res = await _dio.post(
      '/web/session/authenticate',
      data: {
        'jsonrpc': '2.0',
        'params': {
          'db': ApiConstants.odooDatabase,
          'login': login,
          'password': password,
        },
      },
    );
    final result = res.data['result'];
    final uid = result?['uid'];
    if (uid is int) {
      final cookies = res.headers.map['set-cookie'] ?? const <String>[];
      for (final c in cookies) {
        final m = RegExp(r'session_id=([^;]+)').firstMatch(c);
        if (m != null) {
          await _storage.writeSessionId(m.group(1)!);
          break;
        }
      }
      await _storage.setUserId(uid);
      return uid;
    }
    return null;
  }

  Future<AttendanceState> fetchAttendanceState(int employeeId) async {
    final empResult = await callKw(
      model: 'hr.employee',
      method: 'read',
      args: [
        [employeeId],
      ],
      kwargs: {
        'fields': ['attendance_state', 'last_attendance_id'],
      },
    );
    if (empResult is! List || empResult.isEmpty) return AttendanceState.empty;

    final emp = empResult.first as Map<String, dynamic>;
    final state =
        emp['attendance_state']?.toString() ?? 'checked_out';

    int? lastId;
    final lastField = emp['last_attendance_id'];
    if (lastField is List && lastField.length >= 2) {
      final raw = lastField.first;
      if (raw is num) lastId = raw.toInt();
    }

    if (lastId == null) {
      return AttendanceState(state: state);
    }

    final attResult = await callKw(
      model: 'hr.attendance',
      method: 'read',
      args: [
        [lastId],
      ],
      kwargs: {
        'fields': ['check_in', 'check_out'],
      },
    );
    if (attResult is! List || attResult.isEmpty) {
      return AttendanceState(state: state, lastId: lastId);
    }
    final att = attResult.first as Map<String, dynamic>;
    return AttendanceState(
      state: state,
      lastId: lastId,
      checkIn: parseOdooDateTime(att['check_in']),
      checkOut: parseOdooDateTime(att['check_out']),
    );
  }

  Future<List<AttendanceRecord>> fetchAttendances({
    required int employeeId,
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await callKw(
      model: 'hr.attendance',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['employee_id', '=', employeeId],
          ['check_in', '>=', formatOdooDateTime(from)],
          ['check_in', '<=', formatOdooDateTime(to)],
        ],
        'fields': ['id', 'check_in', 'check_out', 'worked_hours'],
        'order': 'check_in desc',
      },
    );
    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(AttendanceRecord.fromJson)
          .toList();
    }
    return const [];
  }

  Future<int> checkInAttendance(
    int employeeId, {
    Uint8List? faceImage,
    double? matchScore,
  }) async {
    final ts = formatOdooDateTime(DateTime.now());
    final vals = <String, dynamic>{
      'employee_id': employeeId,
      'check_in': ts,
    };
    if (faceImage != null) {
      vals['face_image_in'] = base64Encode(faceImage);
    }
    if (matchScore != null) {
      vals['face_match_score_in'] = matchScore;
      vals['face_verified_in'] =
          matchScore >= FaceConstants.matchThreshold;
    }
    final result = await callKw(
      model: 'hr.attendance',
      method: 'create',
      args: [vals],
    );
    if (result is num) return result.toInt();
    if (result is List && result.isNotEmpty && result.first is num) {
      return (result.first as num).toInt();
    }
    throw Exception('Không nhận được id attendance từ máy chủ');
  }

  Future<bool> checkOutAttendance(
    int attendanceId, {
    Uint8List? faceImage,
    double? matchScore,
  }) async {
    final ts = formatOdooDateTime(DateTime.now());
    final vals = <String, dynamic>{'check_out': ts};
    if (faceImage != null) {
      vals['face_image_out'] = base64Encode(faceImage);
    }
    if (matchScore != null) {
      vals['face_match_score_out'] = matchScore;
      vals['face_verified_out'] =
          matchScore >= FaceConstants.matchThreshold;
    }
    final result = await callKw(
      model: 'hr.attendance',
      method: 'write',
      args: [
        [attendanceId],
        vals,
      ],
    );
    return result == true;
  }

  Future<bool> enrollFace({
    required int employeeId,
    required Uint8List imageBytes,
    required List<double> embedding,
  }) async {
    final imageB64 = base64Encode(imageBytes);
    final embeddingJson = jsonEncode(embedding);
    final result = await callKw(
      model: 'hr.employee',
      method: 'write',
      args: [
        [employeeId],
        {
          'face_enrolled_image': imageB64,
          'face_embedding': embeddingJson,
          'face_enrolled_at': formatOdooDateTime(DateTime.now()),
        },
      ],
    );
    return result == true;
  }

  Future<bool> updateEmployee(int employeeId, Map<String, dynamic> values) async {
    if (values.isEmpty) return true;
    final result = await callKw(
      model: 'hr.employee',
      method: 'write',
      args: [
        [employeeId],
        values,
      ],
    );
    return result == true;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final result = await callKw(
      model: 'res.users',
      method: 'change_password',
      args: [oldPassword, newPassword],
    );
    return result == true;
  }

  Future<Response<List<int>>> fetchBinary(String path) {
    return _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Future<EmployeeModel?> fetchCurrentEmployee() async {
    final uid = _storage.userId;
    if (uid == null) return null;

    final result = await callKw(
      model: 'hr.employee',
      method: 'search_read',
      kwargs: {
        'domain': [
          ['user_id', '=', uid],
        ],
        'fields': [
          'id',
          'name',
          'work_email',
          'job_title',
          'job_id',
          'department_id',
          'mobile_phone',
          'work_phone',
          'face_enrolled',
          'face_embedding',
          'face_enrolled_at',
        ],
        'limit': 1,
      },
    );

    if (result is List && result.isNotEmpty) {
      return EmployeeModel.fromJson(result.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final uid = _storage.userId;
    if (uid == null) return null;

    final result = await callKw(
      model: 'res.users',
      method: 'read',
      args: [
        [uid],
      ],
      kwargs: {
        'fields': ['id', 'name', 'login', 'email'],
      },
    );

    if (result is List && result.isNotEmpty) {
      return result.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<dynamic> callKw({
    required String model,
    required String method,
    List args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    final res = await _dio.post(
      '/web/dataset/call_kw',
      data: {
        'jsonrpc': '2.0',
        'params': {
          'model': model,
          'method': method,
          'args': args,
          'kwargs': kwargs,
        },
      },
    );
    final data = res.data;
    if (data['error'] != null) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: data['error']['data']?['message'] ?? data['error']['message'],
      );
    }
    return data['result'];
  }
}
