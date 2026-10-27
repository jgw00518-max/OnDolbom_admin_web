export 'package:ondolbom_admin/view/management/room_detail_dialog.dart';
import 'package:ondolbom_admin/view/management/room_detail_dialog.dart';
import 'package:ondolbom_admin/view/management/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';
import 'package:ondolbom_admin/vm/management/admin_records_vm.dart';
import 'package:ondolbom_admin/view/management/inquiry_answers.dart';
import 'package:ondolbom_admin/view/management/content_manager.dart';
import 'package:ondolbom_admin/view/management/inquiry_status.dart';
import 'package:ondolbom_admin/theme/admin_theme.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});
  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  static const labels = ['사용자 관리', '가족 공간 관리', '문의 내역', '공지사항'];
  static const sections = ['users', 'rooms', 'questions', 'notices'];
  int selected = 0;
  int page = 0;
  String query = '';
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void select(int index) => setState(() {
    selected = index;
    page = 0;
    query = '';
    searchController.clear();
  });

  static const menuIcons = [
    Icons.people_outline_rounded,
    Icons.home_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.campaign_outlined,
  ];

  Widget navigation() {
    final state = ref.watch(adminAuthVmProvider);
    final admin = ref.watch(adminUserProvider).value;
    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -.12,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AdminColors.peach,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                      bottomRight: Radius.circular(13),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    size: 22,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '온돌봄',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '운영센터',
                    style: TextStyle(fontSize: 11, color: AdminColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 52),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 14),
            child: Text(
              'MANAGEMENT',
              style: TextStyle(
                color: AdminColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: selected == i
                            ? AdminColors.cream
                            : Colors.transparent,
                        foregroundColor: selected == i
                            ? AdminColors.ink
                            : AdminColors.muted,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        minimumSize: const Size.fromHeight(47),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: () => select(i),
                      child: Row(
                        children: [
                          Icon(menuIcons[i], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AdminColors.sage,
                foregroundColor: AdminColors.ink,
                child: Text(
                  '관',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '관리자',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      admin?.email ?? admin?.id ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdminColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref.read(adminAuthVmProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('로그아웃', style: TextStyle(fontSize: 12)),
            ),
          ),
          if (state.hasError) const Text('로그아웃하지 못했습니다. 다시 시도해 주세요.'),
        ],
      ),
    );
  }

  String value(Map<String, dynamic> row, String key) =>
      row[key]?.toString() ?? '미등록';
  Widget record(Map<String, dynamic> row) {
    switch (selected) {
      case 0:
        final name = value(row, 'name');
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final person = Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AdminColors.sageLight,
                  foregroundColor: const Color(0xFF60704F),
                  child: Text(
                    name.characters.take(1).toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value(row, 'user_email'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AdminColors.muted,
                        ),
                      ),
                      if (compact)
                        Text(
                          value(row, 'phone'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AdminColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(flex: 21, child: person),
                  if (!compact) ...[
                    Expanded(
                      flex: 12,
                      child: Text(
                        value(row, 'phone'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        value(row, 'registered_at').split('T').first,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminColors.muted,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    flex: compact ? 7 : 5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.sageLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '활성',
                          style: TextStyle(
                            color: Color(0xFF60704F),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 1:
        return ListTile(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) =>
                RoomDetailDialog(id: row['family_room_id'] as String),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          title: Text('${value(row, 'care_recipient_name')} 님의 돌봄 공간'),
          subtitle: Text(
            '참여자 ${value(row, 'member_count')}명 · 생성일 ${value(row, 'created_at')}',
          ),
        );
      case 2:
        return ExpansionTile(
          key: ValueKey(row['question_seq']),
          tilePadding: EdgeInsets.zero,
          title: Text(value(row, 'question_title')),
          subtitle: Text(
            '${value(row, 'user_name')} · ${value(row, 'questioned_at')} · ${(row['answer_count'] as num? ?? 0) > 0 ? '답변 완료' : '답변 대기'} · ${row['processing_status_label'] ?? '처리 상태 DB 적용 대기'}',
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(value(row, 'question_content')),
              ),
            ),
            InquiryAnswers(
              id: row['question_seq'] as int,
              onSaved: () => ref.invalidate(adminRecordsProvider),
            ),
            InquiryStatus(
              key: ValueKey(
                '${row['question_seq']}-${row['processing_status']}-${row['status_updated_at']}',
              ),
              row: row,
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
    if (selected == 3) return const ContentManager(faq: false);
    final request = (section: sections[selected], page: page, query: query);
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
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '현재 페이지에 ${records.items.length}개의 항목이 표시됩니다.',
            style: const TextStyle(fontSize: 11, color: AdminColors.muted),
          ),
          const SizedBox(height: 16),
          if (selected == 0)
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCFAF8),
                    border: Border(
                      top: BorderSide(color: AdminColors.border),
                      bottom: BorderSide(color: AdminColors.border),
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.muted,
                    ),
                    child: Row(
                      children: [
                        const Expanded(flex: 21, child: Text('사용자')),
                        if (!compact) ...[
                          const Expanded(flex: 12, child: Text('연락처')),
                          const Expanded(flex: 10, child: Text('가입일')),
                        ],
                        Expanded(
                          flex: compact ? 7 : 5,
                          child: const Text('상태'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (records.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('표시할 데이터가 없습니다.'),
            ),
          for (final row in records.items) ...[record(row), const Divider()],
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
  Widget build(BuildContext context) => AdminShell(
    title: labels[selected],
    navigation: navigation(),
    actions: [
      IconButton(
        tooltip: '\uC0C8\uB85C\uACE0\uCE68',
        onPressed: selected == 3
            ? null
            : () => ref.invalidate(
                adminRecordsProvider((
                  section: sections[selected],
                  page: page,
                  query: query,
                )),
              ),
        icon: const Icon(Icons.refresh, size: 21),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected == 0 || selected == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => setState(() {
                query = searchController.text.trim();
                page = 0;
              }),
              decoration: InputDecoration(
                labelText: selected == 0
                    ? '이름·이메일·전화번호 검색'
                    : '돌봄 대상자 이름·공간 ID 검색',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: IconButton(
                  tooltip: '검색',
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() {
                    query = searchController.text.trim();
                    page = 0;
                  }),
                ),
              ),
            ),
          ),
        Expanded(child: content()),
      ],
    ),
  );
}
