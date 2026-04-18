import 'package:flutter/material.dart';
import '../../models/room_model.dart';
import '../../theme/app_colors.dart';

class RoomInfoTab extends StatelessWidget {
  final RoomModel room;
  const RoomInfoTab({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final expiry = room.expiresInDays != null ? '${room.expiresInDays} days' : '—';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _section('تفاصيل الغرفة'),
        _row('اسم الغرفة', room.title),
        _row('مالك الغرفة', room.hostName, valueColor: AppColors.colorAdmin),
        _row('سعة الغرفة', '${room.maxCapacity}'),
        _row('تاريخ الانتهاء', expiry),
        _divider(),
        _section('حد الحسابات'),
        _rowColored('ممبر', '15', AppColors.colorMember),
        _rowColored('أدمن', '15', AppColors.colorAdmin),
        _rowColored('سوبر أدمن', '15', AppColors.colorSuperAdmin),
        _rowColored('ماستر', '15', AppColors.colorMaster),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _section(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppColors.bgTertiary,
        child: Text(title,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                fontFamily: 'Cairo', color: AppColors.textPrimary)),
      );

  Widget _divider() => const Divider(height: 1, color: AppColors.borderDefault);

  Widget _row(String label, String value, {Color? valueColor}) => Container(
        color: AppColors.bgSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Cairo')),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13, color: valueColor ?? AppColors.textPrimary,
                  fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _rowColored(String label, String value, Color color) => Container(
        color: AppColors.bgSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14, fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700, color: color))),
          Text(': $value', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: color)),
        ]),
      );
}
