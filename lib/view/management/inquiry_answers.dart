import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/management/inquiry_vm.dart';

class InquiryAnswers extends ConsumerStatefulWidget {
  const InquiryAnswers({super.key, required this.id, required this.onSaved});
  final int id;
  final VoidCallback onSaved;
  @override
  ConsumerState<InquiryAnswers> createState() => _InquiryAnswersState();
}

class _InquiryAnswersState extends ConsumerState<InquiryAnswers> {
  final controller = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      setState(() => error = '답변을 입력해 주세요.');
      return;
    }
    if (text.runes.any((r) => r > 0xFFFF)) {
      setState(() => error = '현재 DB에서 지원하지 않는 이모지·문자가 포함되어 있습니다.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(inquiryApiProvider).request(widget.id, content: text);
      if (!mounted) return;
      controller.clear();
      ref.invalidate(inquiryAnswersProvider(widget.id));
      widget.onSaved();
    } catch (e) {
      if (mounted) setState(() => error = '답변 저장 결과를 확인해 주세요. $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('관리자 답변', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              tooltip: '답변 새로고침',
              onPressed: () =>
                  ref.invalidate(inquiryAnswersProvider(widget.id)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        ref
            .watch(inquiryAnswersProvider(widget.id))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('답변을 불러오지 못했습니다. 새로고침해 주세요.'),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (items.isEmpty) const Text('등록된 답변이 없습니다.'),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['answered_at']}'),
                          SelectableText('${item['answer_content']}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          enabled: !saving,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: '답변 내용',
            border: OutlineInputBorder(),
          ),
        ),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? '저장 중…' : '답변 등록'),
          ),
        ),
      ],
    ),
  );
}
