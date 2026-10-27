import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondolbom_admin/model/auth/admin_user.dart';
import 'package:ondolbom_admin/theme/admin_theme.dart';
import 'package:ondolbom_admin/view/management/admin_dashboard.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';
import 'package:ondolbom_admin/vm/management/admin_records_vm.dart';

void main() {
  testWidgets(
    'Dashboard keeps search and room detail at desktop and phone widths',
    (tester) async {
      final boundaryKey = GlobalKey();
      final previewDirectory = Platform.environment['ADMIN_DESIGN_PREVIEW'];
      var theme = buildAdminTheme();
      if (previewDirectory != null) {
        final loader = FontLoader('PreviewKorean')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File('C:/Windows/Fonts/malgun.ttf').readAsBytesSync(),
              ),
            ),
          );
        await tester.runAsync(loader.load);
        final fallback = FontLoader('Ahem')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File('C:/Windows/Fonts/malgun.ttf').readAsBytesSync(),
              ),
            ),
          );
        await tester.runAsync(fallback.load);
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  'C:/Development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await tester.runAsync(icons.load);
        theme = theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'PreviewKorean'),
        );
      }
      final queries = <String>[];
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 960);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminUserProvider.overrideWith(
              (ref) async =>
                  const AdminUser(id: 'admin', email: 'admin@example.com'),
            ),
            adminRecordsProvider.overrideWith((ref, request) async {
              queries.add(request.query);
              return AdminRecords(
                request.section == 'users'
                    ? [
                        for (final name in [
                          '김민지',
                          '이서연',
                          '김준호',
                          '박서윤',
                          '최민준',
                          '이하은',
                        ])
                          {
                            'name': name,
                            'user_email': 'family@example.com',
                            'phone': '010-1234-5678',
                            'registered_at': '2026-10-26T12:00:00',
                          },
                      ]
                    : [
                        {
                          'family_room_id': 'room-1',
                          'care_recipient_name': '김정희',
                          'member_count': 3,
                          'created_at': '2026-10-26',
                        },
                      ],
                false,
              );
            }),
            roomDetailProvider.overrideWith(
              (ref, id) async => {
                'care_recipient_name': '김정희',
                'family_room_id': id,
                'members': [],
              },
            ),
          ],
          child: MaterialApp(
            theme: theme,
            home: RepaintBoundary(
              key: boundaryKey,
              child: const AdminDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> capture(String name) async {
        if (previewDirectory == null) return;
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final screenshot = await boundary.toImage();
          final bytes = await screenshot.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(
            '$previewDirectory/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          screenshot.dispose();
        });
      }

      await capture('admin-desktop');
      await tester.enterText(find.byType(TextField), '민지');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(queries.last, '민지');
      await tester.tap(find.text('가족 공간 관리'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('김정희 님'));
      await tester.pumpAndSettle();
      expect(find.text('가족 공간 세부 정보'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('사용자 관리').first);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('admin-phone');
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('로그아웃'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
