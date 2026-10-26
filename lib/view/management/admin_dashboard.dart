import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';
import 'package:ondolbom_admin/vm/management/admin_records_vm.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});
  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  static const labels = ['사용자 관리', '가족 공간 관리', '문의 내역', '자주 묻는 질문', '공지사항'];
  static const sections = ['users', 'rooms', 'questions', 'faq', 'notices'];
  int selected = 0;
  int page = 0;
  void select(int index) => setState(() {
    selected = index;
    page = 0;
  });

  Widget navigation() => Container(
    width: 250,
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: ListView(
      children: [
        const SizedBox(height: 20),
        const Text(
          '온돌봄',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF915031),
          ),
        ),
        const Text('운영센터', style: TextStyle(color: Color(0xFF888580))),
        const SizedBox(height: 30),
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: selected == i
                    ? const Color(0xFFF5EEE7)
                    : Colors.white,
                foregroundColor: const Color(0xFF4D4843),
                side: const BorderSide(color: Color(0xFFECE5DE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => select(i),
              child: Text(labels[i]),
            ),
          ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(adminAuthVmProvider);
            return Column(
              children: [
                OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => ref.read(adminAuthVmProvider.notifier).signOut(),
                  child: const Text('로그아웃'),
                ),
                if (state.hasError) const Text('로그아웃하지 못했습니다. 다시 시도해 주세요.'),
              ],
            );
          },
        ),
      ],
    ),
  );

  String value(Map<String, dynamic> row, String key) =>
      row[key]?.toString() ?? '미등록';
  Widget record(Map<String, dynamic> row) {
    switch (selected) {
      case 0:
        final name = value(row, 'name');
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFB9C9A4),
            child: Text(name.characters.take(2).toString()),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${value(row, 'user_email')}\n${value(row, 'phone')}'),
        );
      case 1:
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          title: Text('${value(row, 'care_recipient_name')} 님의 돌봄 공간'),
          subtitle: Text(
            '참여자 ${value(row, 'member_count')}명 · 생성일 ${value(row, 'created_at')}',
          ),
        );
      case 2:
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(value(row, 'question_title')),
          subtitle: Text(
            '${value(row, 'user_name')} · ${value(row, 'questioned_at')} · 답변 ${value(row, 'answer_count')}개',
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(value(row, 'question_content')),
              ),
            ),
          ],
        );
      default:
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(value(row, 'notice_title')),
          subtitle: Text(value(row, 'notice_created_at')),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(value(row, 'notice_content')),
              ),
            ),
          ],
        );
    }
  }

  Widget content() {
    // FAQ 저장 구조 확인 전에는 임의 데이터나 별도 저장소를 만들지 않는다.
    if (selected == 3) return const SizedBox.shrink();
    final request = (section: sections[selected], page: page);
    final data = ref.watch(adminRecordsProvider(request));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('목록을 불러오지 못했습니다. 로그인 상태와 서버 연결을 확인해 주세요.'),
            TextButton(
              onPressed: () => ref.invalidate(adminRecordsProvider(request)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (records) => ListView(
        children: [
          Text(
            '${labels[selected]} · ${page + 1}페이지',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (records.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('표시할 데이터가 없습니다.'),
            ),
          for (final row in records.items) ...[
            record(row),
            const Divider(color: Color(0xFFF0ECE7)),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: page == 0 ? null : () => setState(() => page--),
                child: const Text('이전'),
              ),
              Text('${page + 1}'),
              TextButton(
                onPressed: records.hasMore
                    ? () => setState(() => page++)
                    : null,
                child: const Text('다음'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7F3),
        drawer: wide ? null : Drawer(child: navigation()),
        appBar: wide ? null : AppBar(title: const Text('온돌봄 운영센터')),
        body: Row(
          children: [
            if (wide) navigation(),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 76,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        const Text(
                          '온돌봄 운영센터',
                          style: TextStyle(color: Color(0xFF8E8982)),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: '새로고침',
                          onPressed: selected == 3
                              ? null
                              : () => ref.invalidate(
                                  adminRecordsProvider((
                                    section: sections[selected],
                                    page: page,
                                  )),
                                ),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(wide ? 32 : 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labels[selected],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (wide)
                          const Text(
                            '운영 대시보드',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        wide ? 32 : 16,
                        0,
                        wide ? 32 : 16,
                        32,
                      ),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFEFE9E2)),
                      ),
                      child: content(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
