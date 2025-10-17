import 'package:flutter/material.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class PodcastScreen extends StatelessWidget {
  const PodcastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'PODCAST'),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.radio_outlined,
                size: 64,
                color: BrandColors.primaryOrange,
              ),
              SizedBox(height: 16),
              Text(
                'PODCAST',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.primaryWhite,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Organizado por temporadas',
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
