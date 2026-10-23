import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

/// 사전 발급 계정만 사용한다. 관리자 회원가입 버튼은 제공하지 않는다.
class AdminLoginView extends ConsumerStatefulWidget {
  const AdminLoginView({super.key});
  @override
  ConsumerState<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends ConsumerState<AdminLoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      ref
          .read(adminAuthVmProvider.notifier)
          .signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(adminAuthVmProvider);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          width: 400,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '온돌봄 관리자 로그인',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('사전에 발급된 관리자 계정으로 로그인해 주세요.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  enabled: !operation.isLoading,
                  decoration: const InputDecoration(labelText: '이메일'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) =>
                      !RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(value?.trim() ?? '')
                      ? '이메일을 확인해 주세요.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !operation.isLoading,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  enableSuggestions: false,
                  autocorrect: false,
                  validator: (value) =>
                      value == null || value.isEmpty ? '비밀번호를 입력해 주세요.' : null,
                  onFieldSubmitted: (_) {
                    if (!operation.isLoading) _submit();
                  },
                ),
                if (operation.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      loginErrorMessage(operation.error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: operation.isLoading ? null : _submit,
                  child: Text(operation.isLoading ? '로그인 중…' : '로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
