import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  final String? userName;
  final String? profileImageUrl;

  const ProfileMenu({
    super.key,
    this.userName,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (userName != null) ...[
              Text(
                userName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        profileImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: Text('View Profile'),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Text('Settings'),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout'),
        ),
      ],
      onSelected: (String value) {
        // Handle menu item selection
        switch (value) {
          case 'profile':
            // Navigate to profile
            break;
          case 'settings':
            // Navigate to settings
            break;
          case 'logout':
            // Handle logout
            break;
        }
      },
    );
  }
} 