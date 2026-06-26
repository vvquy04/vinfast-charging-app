import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/station_provider.dart';
import '../../../../core/constants/app_colors.dart';

class StationFilterBottomSheet extends StatefulWidget {
  const StationFilterBottomSheet({super.key});

  @override
  State<StationFilterBottomSheet> createState() => _StationFilterBottomSheetState();
}

class _StationFilterBottomSheetState extends State<StationFilterBottomSheet> {
  String? _selectedConnector;
  int? _selectedPower;
  double? _selectedRating;

  final List<String> _connectorOptions = const ['AC', 'DC', 'CCS2', 'CHAdeMO', 'Type2'];
  final List<int> _powerOptions = const [0, 7, 22, 50, 100, 150, 250, 350];

  @override
  void initState() {
    super.initState();
    final provider = context.read<StationProvider>();
    _selectedConnector = provider.connectorType;
    _selectedPower = provider.minPowerKw;
    _selectedRating = provider.minRating;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StationProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Handle bar ────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Title ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedConnector = null;
                    _selectedPower = null;
                    _selectedRating = null;
                  });
                },
                child: const Text(
                  'Xóa bộ lọc',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Connector Type ────────────────────
          const Text(
            'Loại cổng sạc',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _connectorOptions.map((type) {
              final isSelected = _selectedConnector == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedConnector = isSelected ? null : type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.smoke,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── Min Power ─────────────────────────
          Text(
            'Công suất tối thiểu: ${_selectedPower ?? 0} kW',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _powerOptions.map((kw) {
              final isSelected = (_selectedPower ?? 0) == kw;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPower = kw == 0 ? null : kw;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.smoke,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    kw == 0 ? 'Tất cả' : '≥ $kw kW',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ─── Min Rating ────────────────────────
          Text(
            'Đánh giá tối thiểu: ${_selectedRating?.toStringAsFixed(0) ?? 'Tất cả'} ⭐',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = (i + 1).toDouble();
              final isSelected = (_selectedRating ?? 0) >= star;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = _selectedRating == star ? null : star;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : AppColors.lightGray,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // ─── Apply Button ──────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                provider.applyFilters(
                  connectorType: _selectedConnector,
                  minPowerKw: _selectedPower,
                  minRating: _selectedRating,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Áp dụng bộ lọc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
