import 'package:pata/auth/auth_service.dart';
import 'package:pata/data/repository/transaction_repository.dart';
import 'package:pata/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ← AJOUTER CET IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final repository = ref.read(transactionRepositoryProvider);

    // ✅ Écouter les changements d'authentification
    ref.listen<User?>(authServiceProvider.select((p) => null), (previous, next) {
      // Cette méthode sera appelée quand l'état d'auth change
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade300],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PATA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gérez vos dépenses simplement',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 48),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              final success = await authService.signInWithGoogle();
                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Connexion réussie, chargement des données...')),
                                );
                                await repository.loadFromFirestore();
                                
                                if (context.mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(content: Text('Données synchronisées')),
                                  );
                                  // ✅ FORCER LA REDIRECTION VERS HOME
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                }
                              } else if (context.mounted) {
                                setState(() => _isLoading = false);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Erreur de connexion. Veuillez réessayer.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.g_mobiledata, size: 24),
                            label: const Text(
                              'Se connecter avec Google',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              final success = await authService.signInAnonymously();
                              if (success && context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              } else if (context.mounted) {
                                setState(() => _isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erreur de connexion anonyme'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Continuer sans compte (données locales uniquement)',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}