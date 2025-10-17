import 'package:flutter/material.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class TutorialsScreen extends StatelessWidget {
  const TutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'TUTORIALES'),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_lesson_outlined,
                size: 64,
                color: BrandColors.primaryOrange,
              ),
              SizedBox(height: 16),
              Text(
                'TUTORIALES',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.primaryWhite,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Próximamente...',
                style: TextStyle(
                  fontSize: 16,
                  color: BrandColors.grayMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
