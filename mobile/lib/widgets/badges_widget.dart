import 'package:flutter/material.dart';

class BadgeItem {
  final String title;
  final String icon;
  final bool isEarned;
  final String description;

  BadgeItem({
    required this.title,
    required this.icon,
    required this.isEarned,
    required this.description,
  });
}

class BadgesWidget extends StatelessWidget {
  const BadgesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<BadgeItem> badges = [
      BadgeItem(
        title: 'Responsável',
        icon: '🛡️',
        isEarned: true,
        description: 'Todas as vacinas em dia nos últimos 6 meses.',
      ),
      BadgeItem(
        title: 'Super Tutor',
        icon: '🏆',
        isEarned: true,
        description: 'Perfil do pet 100% preenchido.',
      ),
      BadgeItem(
        title: 'Explorador',
        icon: '🌍',
        isEarned: false,
        description: 'Primeira viagem planejada pelo app.',
      ),
      BadgeItem(
        title: 'Nutricionista',
        icon: '🥦',
        isEarned: false,
        description: 'Escaneou 3 rótulos de ração diferentes.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Conquistas de Tutor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Opacity(
                  opacity: badge.isEarned ? 1.0 : 0.4,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: badge.isEarned 
                              ? const Color(0xFF7C3AED).withOpacity(0.1) 
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: badge.isEarned 
                              ? Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)) 
                              : null,
                        ),
                        child: Text(badge.icon, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: badge.isEarned ? FontWeight.bold : FontWeight.normal,
                          color: badge.isEarned ? const Color(0xFF7C3AED) : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
