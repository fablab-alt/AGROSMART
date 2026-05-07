import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/core/theme/theme_cubit.dart';

/// Header widget for the dashboard page with greeting and action buttons
class DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onVoiceAssistantTap;
  final Widget? notificationBadge;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.onNotificationTap,
    this.onVoiceAssistantTap,
    this.notificationBadge,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = _formatDate(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF28A745),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bonjour, $userName!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _ThemeToggleButton(),
                  const SizedBox(width: 8),
                  _NotificationButton(
                    onTap: onNotificationTap,
                    badge: notificationBadge,
                  ),
                  const SizedBox(width: 8),
                  _VoiceAssistantButton(onTap: onVoiceAssistantTap),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return "${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}";
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final isDark = themeMode == ThemeMode.dark;
          return IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              context.read<ThemeCubit>().setTheme(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            tooltip: isDark ? 'Mode clair' : 'Mode sombre',
          );
        },
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? badge;

  const _NotificationButton({this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: onTap,
            tooltip: 'Notifications',
          ),
          if (badge != null) Positioned(right: 8, top: 8, child: badge!),
        ],
      ),
    );
  }
}

class _VoiceAssistantButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _VoiceAssistantButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.mic, color: Colors.white),
        onPressed: onTap,
        tooltip: 'Assistant vocal',
      ),
    );
  }
}
