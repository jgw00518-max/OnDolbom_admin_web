import 'package:flutter/material.dart';
import 'package:ondolbom_admin/theme/admin_theme.dart';

/// 운영 화면의 외형만 담당하며 데이터 조회와 액션은 기존 화면에서 전달한다.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.navigation,
    required this.actions,
    required this.child,
  });
  final String title;
  final Widget navigation;
  final List<Widget> actions;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final inset = wide ? 42.0 : 16.0;
      return Scaffold(
        drawer: wide ? null : Drawer(child: navigation),
        appBar: wide ? null : AppBar(title: const Text('온돌봄 운영센터')),
        body: Row(
          children: [
            if (wide) navigation,
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: wide ? 78 : 58,
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AdminColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (wide)
                          const Text(
                            'ADMIN CONSOLE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              color: AdminColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (wide) const SizedBox(width: 12),
                        const Text(
                          '온돌봄 운영센터',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        ...actions,
                        const SizedBox(width: 14),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AdminColors.sage,
                          foregroundColor: AdminColors.ink,
                          child: Text(
                            '관',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      inset,
                      wide ? 34 : 22,
                      inset,
                      26,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '사용자와 서비스 이용 현황을 관리합니다',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AdminColors.muted,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (wide)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AdminColors.border),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              '운영 대시보드',
                              style: TextStyle(
                                fontSize: 11,
                                color: AdminColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(inset, 0, inset, 32),
                      padding: EdgeInsets.all(wide ? 24 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AdminColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D594135),
                            offset: Offset(0, 12),
                            blurRadius: 35,
                          ),
                        ],
                      ),
                      child: Material(color: Colors.white, child: child),
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
