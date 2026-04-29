import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _isLoading = false;

    Future<void> _signIn() async {
        setState(() => _isLoading = true);
        try {
            await Supabase.instance.client.auth.signInWithPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
            );
        } on AuthException catch (e) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent));
            }
        } finally {
            if (mounted) setState(() => _isLoading = false);
        }
    }

    @override
    void dispose() {
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Authentication')),
            body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const Text('Travel App Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 40),
                        TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                            keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                            obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                        onPressed: _signIn,
                                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                                        child: const Text('Sign In', style: TextStyle(fontSize: 18)),
                                    ),
                    ],
                ),
            ),
        );
    }
}