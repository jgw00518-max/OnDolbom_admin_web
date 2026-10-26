import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

class AdminRecords {
  const AdminRecords(this.items, this.hasMore);
  final List<Map<String, dynamic>> items;
  final bool hasMore;
}

final adminRecordsProvider = FutureProvider.autoDispose
    .family<AdminRecords, ({String section, int page})>((ref, request) async {
      final user = ref.watch(firebaseAuthProvider).currentUser;
      if (user == null) throw const AdminAuthError('다시 로그인해 주세요.');
      final client = ref.watch(httpClientProvider);
      final base = ref.watch(apiBaseUrlProvider).replaceAll(RegExp(r'/+$'), '');
      for (var attempt = 0; attempt < 2; attempt++) {
        final token = await user.getIdToken(attempt == 1);
        final response = await client
            .get(
              Uri.parse(
                '$base/admin/management/${request.section}?offset=${request.page * 30}',
              ),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 401 && attempt == 0) continue;
        if (response.statusCode != 200) {
          throw AdminAuthError(switch (response.statusCode) {
            401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
            403 => '관리자 권한을 확인해 주세요.',
            _ => '데이터를 불러오지 못했습니다. 서버 연결을 확인해 주세요.',
          });
        }
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AdminRecords(
          (data['items'] as List).cast<Map<String, dynamic>>(),
          data['has_more'] as bool,
        );
      }
      throw const AdminAuthError('다시 로그인해 주세요.');
    });
