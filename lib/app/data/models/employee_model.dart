import 'dart:convert';

import 'attendance_model.dart' show parseOdooDateTime;

class EmployeeModel {
  EmployeeModel({
    required this.id,
    required this.name,
    this.workEmail,
    this.jobTitle,
    this.department,
    this.mobilePhone,
    this.faceEnrolled = false,
    this.faceEmbedding,
    this.faceEnrolledAt,
  });

  final int id;
  final String name;
  final String? workEmail;
  final String? jobTitle;
  final String? department;
  final String? mobilePhone;

  /// Computed on Odoo side from `face_embedding` non-null/non-empty.
  final bool faceEnrolled;

  /// L2-normalized 192-d vector parsed from `face_embedding` JSON.
  /// Null when employee hasn't enrolled or the JSON is malformed.
  final List<double>? faceEmbedding;
  final DateTime? faceEnrolledAt;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: (json['id'] as num).toInt(),
      name: _str(json['name']) ?? 'Nhân viên',
      workEmail: _str(json['work_email']),
      jobTitle: _str(json['job_title']) ?? _m2oName(json['job_id']),
      department: _m2oName(json['department_id']),
      mobilePhone:
          _str(json['mobile_phone']) ?? _str(json['work_phone']),
      faceEnrolled: json['face_enrolled'] == true,
      faceEmbedding: _parseEmbedding(json['face_embedding']),
      faceEnrolledAt: parseOdooDateTime(json['face_enrolled_at']),
    );
  }

  // Odoo returns `false` for null fields. Treat that and empty as null.
  static String? _str(dynamic v) {
    if (v == null || v == false) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  // Many2one fields come as [id, display_name].
  static String? _m2oName(dynamic v) {
    if (v is List && v.length >= 2) {
      final s = v[1]?.toString();
      if (s == null || s.isEmpty) return null;
      return s;
    }
    return null;
  }

  static List<double>? _parseEmbedding(dynamic v) {
    if (v == null || v == false) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded
            .whereType<num>()
            .map((n) => n.toDouble())
            .toList(growable: false);
      }
    } catch (_) {
      // malformed JSON in DB — treat as not enrolled
    }
    return null;
  }
}
