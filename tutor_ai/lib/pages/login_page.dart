// lib/pages/login_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // <- your existing service

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      // Route to your existing home (keep it simple—adjust to your app)
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      // Parse DRF/SimpleJWT style errors if present
      var msg = 'Login failed. Check your email/password.';
      final s = e.toString();
      final i = s.indexOf('{');
      if (i != -1) {
        try {
          final m = jsonDecode(s.substring(i)) as Map<String, dynamic>;
          if (m['detail'] is String) msg = m['detail'];
        } catch (_) {}
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final isNarrow = size.width < 520;

    return Scaffold(
      body: Stack(
        children: [
          // 1) Soft gradient background with subtle vignette
          const _SoftBackground(),
          // 2) Decorative tiny bubbles (kids/parents images)
          const _AvatarBubbles(),
          // 3) Centered glass card
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.7), width: 1),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            spreadRadius: -6,
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ],
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 18 : 28,
                            vertical: isNarrow ? 18 : 28,
                          ),
                          child: Form(
                            key: _form,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo & headline
                                const SizedBox(height: 4),
                                const Icon(Icons.school_outlined, size: 44),
                                const SizedBox(height: 8),
                                Text('Welcome to Tutor AI',
                                    style: t.titleLarge),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign in to continue',
                                  style: t.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                                const SizedBox(height: 20),
                                // Email
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.email,
                                    AutofillHints.username
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.alternate_email),
                                  ),
                                  validator: (v) {
                                    final x = (v ?? '').trim();
                                    if (x.isEmpty) return 'Email is required';
                                    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                        .hasMatch(x);
                                    if (!ok) return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Password
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _signIn(),
                                  autofillHints: const [AutofillHints.password],
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      icon: Icon(_obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) {
                                    if ((v ?? '').isEmpty)
                                      return 'Password is required';
                                    if ((v ?? '').length < 6)
                                      return 'Use at least 6 characters';
                                    return null;
                                  },
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: t.bodyMedium?.copyWith(
                                              color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _loading ? null : _signIn,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Text('Sign in'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    // Keep behavior minimal (you'll wire it later)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Forgot password coming soon')),
                                    );
                                  },
                                  child: const Text('Forgot password?'),
                                ),
                                const SizedBox(height: 4),
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
          ),
          // 4) Subtle brand mark at bottom
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.7,
                child: Text(
                  'Brighter Roots • Tutor AI',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Decorative background ----------

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -1.0),
          end: Alignment(0.9, 1.0),
          colors: [
            Color(0xFFEEF2FF), // soft indigo-50
            Color(0xFFFDF7E3), // warm cream
            Color(0xFFF5FBF7), // mint hint
          ],
        ),
      ),
      child: Container(),
    );
  }
}

// Tiny circular “bubbles” with kids/parents images placed around the card.
// Use super-small assets to keep bandwidth low.
class _AvatarBubbles extends StatelessWidget {
  const _AvatarBubbles();

  @override
  Widget build(BuildContext context) {
    // Positions tuned for both phone/tablet; adjust as you like.
    return IgnorePointer(
      child: Stack(
        children: const [
          _Bubble(
              asset: 'assets/avatars/kid1.png', size: 48, top: 64, left: 24),
          _Bubble(
              asset: 'assets/avatars/parent1.png',
              size: 56,
              top: 120,
              right: 24),
          _Bubble(
              asset: 'assets/avatars/kid2.png',
              size: 44,
              bottom: 120,
              left: 36),
          _Bubble(
              asset: 'assets/avatars/parent2.png',
              size: 50,
              bottom: 80,
              right: 40),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String asset;
  final double size;
  final double? top, left, right, bottom;

  const _Bubble({
    required this.asset,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            spreadRadius: -2,
            color: Colors.black.withOpacity(0.12),
          )
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          // If asset missing, show a neutral icon—keeps UI graceful.
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 20, color: Colors.black38),
          ),
        ),
      ),
    );

    return Positioned(
        top: top, left: left, right: right, bottom: bottom, child: bubble);
  }
}
