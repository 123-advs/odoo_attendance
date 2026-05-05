class EmployeeModel {
  EmployeeModel({
    required this.id,
    required this.name,
    this.workEmail,
    this.jobTitle,
    this.department,
    this.mobilePhone,
  });

  final int id;
  final String name;
  final String? workEmail;
  final String? jobTitle;
  final String? department;
  final String? mobilePhone;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: (json['id'] as num).toInt(),
      name: _str(json['name']) ?? 'Nhân viên',
      workEmail: _str(json['work_email']),
      jobTitle: _str(json['job_title']) ?? _m2oName(json['job_id']),
      department: _m2oName(json['department_id']),
      mobilePhone:
          _str(json['mobile_phone']) ?? _str(json['work_phone']),
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
}
