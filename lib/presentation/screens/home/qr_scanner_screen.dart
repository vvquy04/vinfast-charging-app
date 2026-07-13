import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../providers/charging_provider.dart';
import '../../providers/station_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedStationId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // Mặc định chọn trạm đầu tiên trong danh sách nếu có
    final stations = context.read<StationProvider>().stations;
    if (stations.isNotEmpty) {
      _selectedStationId = stations.first.stationId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chargingProvider = context.read<ChargingProvider>();
    final activeBooking = chargingProvider.activeBooking;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['stationId'] != null) {
      _selectedStationId = args['stationId'] as int;
    } else if (activeBooking != null) {
      _selectedStationId = activeBooking['station']['stationId'] as int;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final chargingProvider = context.watch<ChargingProvider>();
    final activeBooking = chargingProvider.activeBooking;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        title: const Text(
          'Quét mã QR sạc xe',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // 1. Simulated Viewfinder Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Di chuyển kính ngắm vào mã QR trên trụ sạc',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                
                // Scanner Frame Box
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.white.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Moving Laser Line Animation
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Positioned(
                            top: _animation.value * 230 + 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2979FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2979FF).withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Viewfinder corner marks
                      _buildCornerMark(top: 0, left: 0),
                      _buildCornerMark(top: 0, right: 0),
                      _buildCornerMark(bottom: 0, left: 0),
                      _buildCornerMark(bottom: 0, right: 0),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Show notification if user has an active booking
                if (activeBooking != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.5)),
                    ),
                    child: Text(
                      'Đang quét mã để nhận chỗ tại trạm:\n${activeBooking['station']['stationName']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 13, height: 1.4),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Chưa có lịch đặt trước. Quét mã sẽ sạc xe trực tiếp.',
                    style: TextStyle(color: AppColors.silver, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),

          // 2. Bottom Tester Simulation panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text(
                        'Bộ giả lập quét QR (Dành cho thử nghiệm)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Text(
                    'Chọn trạm sạc xe điện VinFast để mô phỏng quét thành công:',
                    style: TextStyle(color: AppColors.silver, fontSize: 12),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Station Selector Dropdown
                  if (stationProvider.stations.isEmpty)
                    const Text('Đang tải danh sách trạm sạc mẫu...', style: TextStyle(color: AppColors.gray))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedStationId,
                          dropdownColor: Colors.black,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: stationProvider.stations.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.stationId,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedStationId = val;
                            });
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: AppSizes.md),

                  // Simulate Success Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _selectedStationId == null || chargingProvider.isLoading
                          ? null
                          : () async {
                              final matchedStation = stationProvider.stations.firstWhere(
                                (s) => s.stationId == _selectedStationId,
                              );

                              // 1. Nếu có Booking PENDING cho trạm này
                              if (activeBooking != null &&
                                  activeBooking['station']['stationId'] == _selectedStationId) {
                                final bool ok = await chargingProvider.startCharging(
                                  _selectedStationId!,
                                  activeBooking['connectorType'] ?? 'CCS2',
                                  activeBooking['connectorType'] == 'AC Type 2' ? 11.0 : 150.0,
                                );
                                if (ok && mounted) {
                                  Navigator.pushReplacementNamed(context, '/charging_status');
                                }
                              } 
                              // 2. Sạc trực tiếp không đặt chỗ
                              else {
                                if (mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/payment_checkout',
                                    arguments: {
                                      'stationId': matchedStation.stationId,
                                      'stationName': matchedStation.name,
                                      'address': matchedStation.address,
                                    },
                                  );
                                }
                              }
                            },
                      child: chargingProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                            )
                          : const Text(
                              'Giả lập Quét thành công',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCornerMark({double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
