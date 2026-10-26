import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondolbom_admin/view/management/inquiry_answers.dart';
import 'package:ondolbom_admin/vm/management/inquiry_vm.dart';

void main() {
  testWidgets('Empty and unsupported answers are blocked before submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inquiryAnswersProvider.overrideWith((ref, id) async => [])],
        child: MaterialApp(
          home: Scaffold(body: InquiryAnswers(id: 1, onSaved: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('답변을 입력'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      String.fromCharCode(0x1F600),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.textContaining('지원하지 않는'), findsOneWidget);
  });
}
