import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pata/auth/auth_service.dart';

class ProfileMenu extends ConsumerStatefulWidget {
  const ProfileMenu({super.key});

  @override
  ConsumerState<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends ConsumerState<ProfileMenu> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: _user?.photoURL != null
            ? ClipOval(
                child: Image.network(
                  _user!.photoURL!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 16, color: Colors.white);
                  },
                ),
              )
            : const Icon(Icons.person, size: 16, color: Colors.white),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Déconnexion'),
              content: const Text('Voulez-vous vraiment vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await authService.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Déconnecté avec succès')),
              );
            }
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'info',
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _user?.displayName ?? 'Utilisateur',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                _user?.email ?? 'email@exemple.com',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Se déconnecter', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}