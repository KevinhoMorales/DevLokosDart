import 'package:flutter/material.dart';
import '../constants/podcast_seasons.dart';
import '../utils/app_haptics.dart';
import '../utils/brand_colors.dart';

/// Selector de temporada del podcast (extensible vía [PodcastSeasons]).
class SeasonFilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<String>? seasons;

  const SeasonFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.seasons,
  });

  @override
  Widget build(BuildContext context) {
    final items = seasons ?? PodcastSeasons.labels;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        dropdownColor: BrandColors.blackLight,
        style: const TextStyle(
          color: BrandColors.primaryWhite,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        underline: const SizedBox(),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: BrandColors.primaryOrange.withValues(alpha: 0.9),
          size: 20,
        ),
        items: items.map((String season) {
          return DropdownMenuItem<String>(
            value: season,
            child: Text(season),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue == null) return;
          AppHaptics.selection();
          onChanged(newValue);
        },
      ),
    );
  }
}
