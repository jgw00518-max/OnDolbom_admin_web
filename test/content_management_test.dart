import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondolbom_admin/view/management/content_manager.dart';
import 'package:ondolbom_admin/view/management/inquiry_status.dart';
import 'package:ondolbom_admin/vm/management/content_vm.dart';

class FakeContentApi extends Fake implements ContentApi {
  final calls = <String>[];
  @override
  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    calls.add(method);
    return {'notice_id': 'n', 'admin_id': 'a'};
  }
}

void main() {
  testWidgets('Notice requires both fields then saves using API', (
    tester,
  ) async {
    final api = FakeContentApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contentApiProvider.overrideWithValue(api)],
        child: const MaterialApp(
          home: Scaffold(body: ContentDialog(faq: false)),
        ),
      ),
    );
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(api.calls, isEmpty);
    await tester.enterText(find.byType(TextField).at(0), 'notice');
    await tester.enterText(find.byType(TextField).at(1), 'body');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(api.calls, ['POST']);
  });
  testWidgets('FAQ missing schema disables creation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentDataProvider.overrideWith(
            (ref, path) async => throw Exception('FAQ DB 적용 대기'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ContentManager(faq: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.textContaining('DB 적용 대기'), findsOneWidget);
  });
  testWidgets('Status missing schema cannot mutate', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: InquiryStatus(row: {'status_supported': false})),
        ),
      ),
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('DB 적용 대기'), findsOneWidget);
  });
}
