import 'package:flutter/material.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'ENTERPRISE'),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 64,
                color: BrandColors.primaryOrange,
              ),
              SizedBox(height: 16),
              Text(
                'ENTERPRISE',
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
