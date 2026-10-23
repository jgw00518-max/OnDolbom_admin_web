/// 서버에서 관리자 권한까지 확인한 결과. Firebase 사용자와 구분한다.
class AdminUser {
  const AdminUser({required this.id, this.email});
  final String id;
  final String? email;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['admin_id'] as String,
    email: json['admin_email'] as String?,
  );
}
