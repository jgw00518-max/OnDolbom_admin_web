import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/theme/admin_theme.dart';
import 'package:ondolbom_admin/vm/management/admin_records_vm.dart';

class RoomDetailDialog extends ConsumerWidget {
  const RoomDetailDialog({super.key, required this.id});
  final String id;

  Widget field(String label, dynamic value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AdminColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 7),
      SelectableText(
        '${value ?? '미등록'}',
        style: const TextStyle(
          color: AdminColors.ink,
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget section(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdminColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: AdminColors.muted),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget details(Map<String, dynamic> room) {
    final members = room['members'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(
          '돌봄 대상자 정보',
          Icons.person_outline_rounded,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    field('돌봄 대상자', room['care_recipient_name']),
                    field('생년월일', room['birth_date']),
                  ];
                  return constraints.maxWidth < 380
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            fields[0],
                            const SizedBox(height: 18),
                            fields[1],
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 24),
                            Expanded(child: fields[1]),
                          ],
                        );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(),
              ),
              field('주소', room['care_address']),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: field('특이사항', room['special_notes']),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        section(
          '공간 정보',
          Icons.home_outlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field('공간 ID', room['family_room_id']),
              const SizedBox(height: 18),
              field('생성일', room['created_at']),
            ],
          ),
        ),
        const SizedBox(height: 16),
        section(
          '현재 참여 가족',
          Icons.people_outline_rounded,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
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
                  child: Text(
                    '${members.length}명 참여 중',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF60704F),
                    ),
                  ),
                ),
              ),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    '참여 가족이 없습니다.',
                    style: TextStyle(fontSize: 13, color: AdminColors.muted),
                  ),
                ),
              for (var i = 0; i < members.length; i++) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: AdminColors.sageLight,
                        foregroundColor: const Color(0xFF60704F),
                        child: Text(
                          '${members[i]['name'] ?? '미등록'}'.characters
                              .take(1)
                              .toString(),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${members[i]['name'] ?? '미등록'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: members[i]['is_representative'] == 1
                                        ? AdminColors.cream
                                        : AdminColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    members[i]['is_representative'] == 1
                                        ? '대표 보호자'
                                        : '일반 가족',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AdminColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            SelectableText(
                              '${members[i]['user_email'] ?? '미등록'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Dialog(
    backgroundColor: AdminColors.background,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AdminColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가족 공간 세부 정보',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '돌봄 정보와 참여 가족을 확인합니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ref
                  .watch(roomDetailProvider(id))
                  .when(
                    loading: () => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 32,
                            color: AdminColors.muted,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '공간을 찾을 수 없거나 정보를 불러오지 못했습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AdminColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(roomDetailProvider(id)),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                    data: details,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AdminColors.border)),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
