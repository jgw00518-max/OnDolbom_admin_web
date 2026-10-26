import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

class InquiryApi {
  InquiryApi(this.ref);
  final Ref ref;
  Future<Map<String, dynamic>> request(int id, {String? content}) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw const AdminAuthError('다시 로그인해 주세요.');
    final base = ref.read(apiBaseUrlProvider).replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/admin/inquiries/$id/answers');
    final client = ref.read(httpClientProvider);
    final token = await user.getIdToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    // 저장 요청은 응답 유실 시 중복 등록될 수 있으므로 자동 재시도하지 않는다.
    final response =
        await (content == null
                ? client.get(uri, headers: headers)
                : client.post(
                    uri,
                    headers: headers,
                    body: jsonEncode({'content': content}),
                  ))
            .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AdminAuthError(switch (response.statusCode) {
        401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
        403 => '관리자 권한이 없습니다.',
        404 => '삭제되었거나 존재하지 않는 문의입니다.',
        422 => '답변 내용이나 지원하지 않는 문자를 확인해 주세요.',
        _ => '처리 결과를 확인하지 못했습니다. 답변 목록을 새로고침해 주세요.',
      });
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

final inquiryApiProvider = Provider.autoDispose((ref) => InquiryApi(ref));
final inquiryAnswersProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, id) async {
      final result = await ref.watch(inquiryApiProvider).request(id);
      return result['items'] as List<dynamic>;
    });
