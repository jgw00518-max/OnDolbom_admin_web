import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/management/content_vm.dart';

class ContentManager extends ConsumerStatefulWidget {
  const ContentManager({super.key, required this.faq});
  final bool faq;
  @override
  ConsumerState<ContentManager> createState() => _ContentManagerState();
}

class _ContentManagerState extends ConsumerState<ContentManager> {
  int page = 0;
  String get base => widget.faq ? '/admin/faqs' : '/admin/notices';
  String get path => '$base?offset=${page * 30}';
  String get titleKey => widget.faq ? 'faq_question' : 'notice_title';
  void refresh() => ref.invalidate(contentDataProvider);
  Future<void> open([Map<String, dynamic>? row]) async {
    final detailPath = row == null
        ? null
        : widget.faq
        ? '$base/${Uri.encodeComponent(row['admin_id'] as String)}/${Uri.encodeComponent(row['faq_id'] as String)}'
        : '$base/${Uri.encodeComponent(row['admin_id'] as String)}/${Uri.encodeComponent(row['notice_id'] as String)}';
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ContentDialog(faq: widget.faq, path: detailPath),
    );
    if (changed == true && mounted) refresh();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Text(
            widget.faq ? '자주 묻는 질문' : '공지사항',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            tooltip: '목록 새로고침',
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
          FilledButton(
            onPressed:
                widget.faq && !ref.watch(contentDataProvider(path)).hasValue
                ? null
                : () => open(),
            child: const Text('작성'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ref
            .watch(contentDataProvider(path))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (data) => ListView(
                children: [
                  if ((data['items'] as List).isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('표시할 데이터가 없습니다.'),
                    ),
                  for (final row in data['items'] as List)
                    ListTile(
                      title: Text('${row[titleKey] ?? '미등록'}'),
                      subtitle: Text(
                        '${row[widget.faq ? 'faq_created_at' : 'notice_created_at'] ?? ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => open(Map<String, dynamic>.from(row as Map)),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: page == 0
                            ? null
                            : () => setState(() => page--),
                        child: const Text('이전'),
                      ),
                      Text('${page + 1}'),
                      TextButton(
                        onPressed: data['has_more'] == true
                            ? () => setState(() => page++)
                            : null,
                        child: const Text('다음'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    ],
  );
}

class ContentDialog extends ConsumerStatefulWidget {
  const ContentDialog({super.key, required this.faq, this.path});
  final bool faq;
  final String? path;
  @override
  ConsumerState<ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends ConsumerState<ContentDialog> {
  final title = TextEditingController();
  final body = TextEditingController();
  bool loaded = false;
  bool editing = false;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    editing = widget.path == null;
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final a = title.text.trim();
    final b = body.text.trim();
    if (a.isEmpty ||
        b.isEmpty ||
        a.runes.length > 100 ||
        utf8.encode(b).length > 65535 ||
        '$a$b'.runes.any((r) => r > 0xFFFF)) {
      setState(
        () => error =
            '두 항목을 모두 입력해 주세요. 제목·질문은 100자 이내이며 일부 이모지·너무 긴 본문은 저장할 수 없습니다.',
      );
      return;
    }
    await mutate(widget.path == null ? 'POST' : 'PUT', {
      widget.faq ? 'faq_question' : 'notice_title': a,
      widget.faq ? 'faq_answer' : 'notice_content': b,
    });
  }

  Future<void> mutate(String method, [Map<String, dynamic>? data]) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(contentApiProvider)
          .request(
            widget.path ?? (widget.faq ? '/admin/faqs' : '/admin/notices'),
            method: method,
            body: data,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('삭제 후 사용자 목록에서도 표시되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await mutate('DELETE');
  }

  Widget fields() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (editing) ...[
        TextField(
          controller: title,
          enabled: !busy,
          maxLength: 100,
          decoration: InputDecoration(labelText: widget.faq ? '질문' : '제목'),
        ),
        TextField(
          controller: body,
          enabled: !busy,
          minLines: 5,
          maxLines: 12,
          decoration: InputDecoration(labelText: widget.faq ? '답변' : '본문'),
        ),
      ] else ...[
        SelectableText(
          title.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SelectableText(body.text),
      ],
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
    ],
  );
  @override
  Widget build(BuildContext context) {
    Widget content = fields();
    if (widget.path != null) {
      content = ref
          .watch(contentDataProvider(widget.path!))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(contentDataProvider(widget.path!)),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
            data: (data) {
              if (!loaded) {
                title.text =
                    '${data[widget.faq ? 'faq_question' : 'notice_title'] ?? ''}';
                body.text =
                    '${data[widget.faq ? 'faq_answer' : 'notice_content'] ?? ''}';
                loaded = true;
              }
              return fields();
            },
          );
    }
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(widget.faq ? 'FAQ' : '공지사항'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(child: content),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          if (!editing && loaded) ...[
            TextButton(
              onPressed: busy ? null : remove,
              child: const Text('삭제'),
            ),
            FilledButton(
              onPressed: busy ? null : () => setState(() => editing = true),
              child: const Text('수정'),
            ),
          ],
          if (editing)
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? '저장 중…' : '저장'),
            ),
        ],
      ),
    );
  }
}
