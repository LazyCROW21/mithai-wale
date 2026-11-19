import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/network/api_client.dart';
import '../../l10n/l10n.dart';

/// Login screen. One layout for all breakpoints: a centred, width-constrained card.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the router's auth redirect moves us to the home screen.
      await ref.read(authProvider.notifier).signIn(
            franchiseCode: _code.text,
            username: _username.text,
            password: _password.text,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.isNetwork
            ? l10n.authNetworkError
            : (e.isUnauthorized ? l10n.authInvalidCredentials : l10n.errorGeneric);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.authFieldRequired : null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.cake_outlined, size: 48, color: cs.primary),
                          const SizedBox(height: 12),
                          Text(
                            l10n.appName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.authLoginSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _code,
                            enabled: !_busy,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: l10n.authFranchiseCode,
                              prefixIcon: const Icon(Icons.storefront_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _username,
                            enabled: !_busy,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.username],
                            decoration: InputDecoration(
                              labelText: l10n.authUsername,
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.authPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: _required,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: cs.error)),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_busy ? l10n.authSigningIn : l10n.authSignIn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
