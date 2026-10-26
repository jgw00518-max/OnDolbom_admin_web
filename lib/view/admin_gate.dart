import 'package:ondolbom_admin/view/management/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/view/auth/admin_login_view.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

/// 로그인 복원 → 서버 권한 검사 → 관리 화면 순서로 진입한다.
class AdminGate extends ConsumerWidget {
  const AdminGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final operation = ref.watch(adminAuthVmProvider);
    Widget logout() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (operation.hasError) Text(loginErrorMessage(operation.error!)),
        TextButton(
          onPressed: operation.isLoading
              ? null
              : () => ref.read(adminAuthVmProvider.notifier).signOut(),
          child: Text(operation.isLoading ? '처리 중…' : '로그아웃'),
        ),
      ],
    );
    final body = session.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('로그인 상태를 확인하지 못했습니다.'),
            TextButton(
              onPressed: () => ref.invalidate(authSessionProvider),
              child: const Text('다시 확인'),
            ),
            logout(),
          ],
        ),
      ),
      data: (user) {
        if (user == null) return const AdminLoginView();
        // 권한 오류에서도 관리 화면 내용을 미리 보여주지 않는다.
        return ref
            .watch(adminUserProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error.toString(), textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => ref.invalidate(adminUserProvider),
                      child: const Text('권한 다시 확인'),
                    ),
                    logout(),
                  ],
                ),
              ),
              data: (admin) => admin == null
                  ? const Center(child: Text('관리자 정보를 확인해 주세요.'))
                  : const AdminDashboard(),
            );
      },
    );
    if (session.value != null && ref.watch(adminUserProvider).value != null) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('온돌봄 관리자')),
      body: body,
    );
  }
}
