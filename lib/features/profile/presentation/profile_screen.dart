import 'package:category_manager/features/profile/presentation/widgets/profile_field.dart';
import 'package:flutter/material.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';
import 'package:category_manager/features/profile/data/models/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final initials = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.forest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFD7EEDC),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: AppTheme.forest,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: const TextStyle(color: Color(0xFFBDDBCE), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Account Details',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ProfileField(
                icon: Icons.badge_outlined,
                label: 'Name',
                value: user.name,
              ),
              const Divider(height: 1),
              ProfileField(
                icon: Icons.alternate_email,
                label: 'Username',
                value: user.username,
              ),
              const Divider(height: 1),
              ProfileField(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 1),
              ProfileField(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phone,
              ),
              const Divider(height: 1),
              ProfileField(
                icon: Icons.language,
                label: 'Website',
                value: user.website,
              ),
              const Divider(height: 1),
              ProfileField(
                icon: Icons.business_outlined,
                label: 'Company',
                value: user.company,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
