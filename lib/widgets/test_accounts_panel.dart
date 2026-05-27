import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_constants.dart';
import '../core/auth_provider.dart';

class TestAccountsPanel extends StatelessWidget {
  const TestAccountsPanel({
    super.key,
    required this.accounts,
    required this.title,
  });

  final List<TestAccount> accounts;
  final String title;

  Future<void> _signIn(BuildContext context, TestAccount account) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithTestAccount(account);
    if (!ok && context.mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.blue[700], size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Войти в один тап (без регистрации)',
            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
          ),
          const SizedBox(height: 10),
          for (final account in accounts) ...[
            OutlinedButton.icon(
              onPressed: auth.loading ? null : () => _signIn(context, account),
              icon: const Icon(Icons.login, size: 18),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  account.name,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.blue[200]!),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
