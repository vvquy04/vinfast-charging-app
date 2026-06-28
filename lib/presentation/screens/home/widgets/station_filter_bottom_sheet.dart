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
  double _minPowerIndex = 0;
  double _maxPowerIndex = 5;
  double? _selectedRating;

  final List<String> _connectorOptions = const ['CCS2 (DC)', 'Type 2 (AC)', 'CHAdeMO'];
  final List<int> _powerValues = const [2, 7, 22, 50, 100, 9999];
  final List<String> _powerLabels = const ['2', '7', '22', '50', '100', '150+'];

  int _findClosestIndex(int kw) {
    if (kw >= 150) return 5;
    if (kw >= 100) return 4;
    if (kw >= 50) return 3;
    if (kw >= 22) return 2;
    if (kw >= 7) return 1;
    return 0;
  }

  String _getPowerLabel(int index) {
    if (index == 5) return '150+ kW';
    return '${_powerValues[index]} kW';
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<StationProvider>();
    _selectedConnector = provider.connectorType;
    _minPowerIndex = _findClosestIndex(provider.minPowerKw ?? 2).toDouble();
    _maxPowerIndex = _findClosestIndex(provider.maxPowerKw ?? 9999).toDouble();
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
                    _minPowerIndex = 0;
                    _maxPowerIndex = 5;
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

          // ─── Min & Max Power Range ─────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Công suất sạc (kW)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              Text(
                '${_getPowerLabel(_minPowerIndex.toInt())} - ${_getPowerLabel(_maxPowerIndex.toInt())}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.smoke,
              trackHeight: 6.0,
              thumbColor: AppColors.white,
              valueIndicatorColor: AppColors.primary,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10.0,
                elevation: 3.0,
              ),
            ),
            child: RangeSlider(
              values: RangeValues(_minPowerIndex, _maxPowerIndex),
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (RangeValues values) {
                setState(() {
                  _minPowerIndex = values.start;
                  _maxPowerIndex = values.end;
                });
              },
            ),
          ),
          // Discrete Labels Row aligned with ticks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _powerLabels.map((label) {
                return Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray,
                  ),
                );
              }).toList(),
            ),
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
                final int minKw = _powerValues[_minPowerIndex.toInt()];
                final int maxKw = _powerValues[_maxPowerIndex.toInt()];

                provider.applyFilters(
                  connectorType: _selectedConnector,
                  minPowerKw: minKw == 2 ? null : minKw,
                  maxPowerKw: maxKw == 9999 ? null : maxKw,
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
