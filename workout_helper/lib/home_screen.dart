import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'app_colors.dart';
import 'exercise_list_screen.dart';
import 'recents_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accentLight,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${MockData.userName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age ${MockData.age} • ${MockData.gender}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
//Recent Card
            const SizedBox(height: 35),
            const Text(
              'RECENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),

            _AppCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecentsScreen()),
                );
              },
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePlaceholder(icon: Icons.history),
                  SizedBox(height: 12),
                  Text(
                    'Recently completed workouts and stretches',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
//Stretch Card
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 190, //size of the card
                    child: _AppCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ExerciseListScreen(type: 'stretch'),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: AppColors.sticker,
                                child: Image.asset(
                                  'assets/images/stretch_cat.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'STRETCHES',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
//Workout Card
                Expanded(
                  child: SizedBox(
                    height: 190,
                    child: _AppCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ExerciseListScreen(type: 'workout'),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: AppColors.sticker,
                                child: Image.asset(
                                  'assets/images/workout_cat.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'WORKOUTS',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
//Badges Section
            const Text(
              'YOUR BADGES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),

            _AppCard(
              child: _BadgeGrid(badges: MockData.earnedBadges),
            ),
          ],
        ),
      ),
    );
  }
}
//template for UI cards 
class _AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap; //determine if the card is clickable
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final double? height;

  const _AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.color,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double height;
  final IconData icon;

  const _ImagePlaceholder({
    this.height = 72,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 30,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<String> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final unlocked = index < badges.length;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? AppColors.primary : AppColors.accentLight,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? Colors.white : AppColors.primaryDark,
          ),
        );
      },
    );
  }
}