import 'package:flutter/material.dart';
import '../../../../data/models/connector_type_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class ConnectorTypeCard extends StatelessWidget {
  final ConnectorTypeModel connector;

  const ConnectorTypeCard({
    super.key,
    required this.connector,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = connector.totalPorts > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.silver),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.electrical_services_rounded, color: AppColors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connector.type,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Công suất: ${connector.powerKw} kW',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: available ? AppColors.primary.withOpacity(0.1) : AppColors.lightGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${connector.totalPorts} cổng',
              style: TextStyle(
                  color: available ? AppColors.primary : AppColors.gray,
                  fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
