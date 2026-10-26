import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/management/content_vm.dart';
import 'package:ondolbom_admin/vm/management/admin_records_vm.dart';

class InquiryStatus extends ConsumerStatefulWidget {
  const InquiryStatus({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  ConsumerState<InquiryStatus> createState() => _InquiryStatusState();
}

class _InquiryStatusState extends ConsumerState<InquiryStatus> {
  static const labels = {
    'RECEIVED': '접수',
    'IN_REVIEW': '확인 중',
    'NEEDS_INFO': '추가 확인 필요',
    'RESOLVED': '처리 완료',
  };
  String? selected;
  bool busy = false;
  String? error;
  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(contentApiProvider)
          .request(
            '/admin/inquiries/${widget.row['question_seq']}/status',
            method: 'PATCH',
            body: {
              'processing_status': selected,
              'expected_status': widget.row['processing_status'],
            },
          );
      if (!mounted) return;
      ref.invalidate(adminRecordsProvider);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.row['status_supported'] != true) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('문의 처리 상태: DB 적용 대기 (답변 여부와 별도)'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: widget.row['processing_status'] as String?,
            decoration: const InputDecoration(labelText: '문의 처리 상태'),
            items: [
              for (final entry in labels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: busy
                ? null
                : (value) => setState(() => selected = value),
          ),
          const Text('답변 등록 시 처리 상태는 자동 변경되지 않습니다.'),
          if (widget.row['status_updated_at'] != null)
            Text('마지막 변경: ${widget.row['status_updated_at']}'),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed:
                  busy ||
                      selected == null ||
                      selected == widget.row['processing_status']
                  ? null
                  : save,
              child: Text(busy ? '저장 중…' : '상태 변경'),
            ),
          ),
        ],
      ),
    );
  }
}
