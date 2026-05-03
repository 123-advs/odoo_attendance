import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:odoo_attendance/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final tempDir = Directory.systemTemp.createTempSync('odoo_attendance_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory' ||
          call.method == 'getApplicationSupportDirectory' ||
          call.method == 'getTemporaryDirectory') {
        return tempDir.path;
      }
      return null;
    });
    await GetStorage.init();
  });

  testWidgets('App boots into Splash with logo and progress indicator',
      (tester) async {
    await tester.pumpWidget(const OdooAttendanceApp());
    await tester.pump();

    expect(find.text('Chấm công Odoo'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsAtLeastNWidgets(1));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
