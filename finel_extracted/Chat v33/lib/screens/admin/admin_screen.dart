// ============================================================
// Jordan Audio Forum — Admin Screen v24
// ✅ Rooms + Rental Management + Users + Support + Kill-Switch
// ✅ إدارة إيجار الغرف مع عداد تنازلي (تواريخ بداية/نهاية)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/shared_widgets.dart';
import '../home/support_chat_sheet.dart';
import '../home/create_room_sheet.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<RoomModel> _rooms = [];
  List<UserModel> _users = [];
  bool _loadingRooms = false;
  bool _loadingUsers = false;
  final _searchCtrl  = TextEditingController();
  final _lockMsgCtrl = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadRooms();
    // تحديث العداد كل ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _lockMsgCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (_loadingRooms) return;
    setState(() => _loadingRooms = true);
    _rooms = await FirestoreService.instance.getAllRooms();
    if (mounted) setState(() => _loadingRooms = false);
  }

  Future<void> _searchUsers() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() => _loadingUsers = true);
    _users = await FirestoreService.instance.searchUsers(_searchCtrl.text.trim());
    if (mounted) setState(() => _loadingUsers = false);
  }

  int get _liveRoomsCount  => _rooms.where((r) => r.isLive).length;
  int get _rentedRoomsCount => _rooms.where((r) => r.isRented).length;
  int get _totalListeners  => _rooms.fold(0, (s, r) => s + r.listenersCount + r.speakersCount);

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => context.go('/more'),
          ),
          title: const Text('لوحة التحكم',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_outlined,
                    size: 72, color: AppColors.textMuted.withOpacity(0.7)),
                const SizedBox(height: 20),
                const Text('غير مصرح بالدخول',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Text(
                  'لوحة المالك متاحة فقط لحسابات الإدارة المصرّح بها.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        _buildStatsRow(),
        _buildTabs(),
        Expanded(child: TabBarView(controller: _tab, children: [
          _buildRoomsTab(),
          _buildRentalTab(),
          _buildUsersTab(),
          _buildSettingsTab(),
        ])),
      ])),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    decoration: BoxDecoration(
      color: AppColors.primary,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        onPressed: () => context.go('/'),
      ),
      const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'لوحة التحكم',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
        tooltip: 'إنشاء غرفة',
        onPressed: _openAdminCreateRoom,
      ),
      _badge('${_rooms.length} غرفة', AppColors.primaryMuted),
    ]),
  );

  void _openAdminCreateRoom() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => CreateRoomSheet(
        onCreated: (room) async {
          await _loadRooms();
          if (mounted) context.push('/room/${room.id}', extra: true);
        },
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(
      color: Colors.white, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
  );

  // ──────────────────────────────────────────────────────────
  // Stats Row
  // ──────────────────────────────────────────────────────────
  Widget _buildStatsRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      _statCard('الكل', '${_rooms.length}', Icons.grid_view, AppColors.info),
      const SizedBox(width: 8),
      _statCard('مباشر', '$_liveRoomsCount', Icons.circle, AppColors.success),
      const SizedBox(width: 8),
      _statCard('مؤجرة', '$_rentedRoomsCount', Icons.key_rounded, AppColors.warning),
      const SizedBox(width: 8),
      _statCard('مستمعين', '$_totalListeners', Icons.headphones, AppColors.primary),
    ]),
  );

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: color, fontFamily: 'Cairo')),
        Text(label, style: const TextStyle(fontSize: 10,
            color: AppColors.textMuted, fontFamily: 'Cairo')),
      ]),
    ),
  );

  // ──────────────────────────────────────────────────────────
  // Tabs
  // ──────────────────────────────────────────────────────────
  Widget _buildTabs() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderDefault),
    ),
    child: TabBar(
      controller: _tab,
      indicator: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      indicatorPadding: const EdgeInsets.all(4),
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 10),
      tabs: const [
        Tab(text: 'الغرف'),
        Tab(text: 'الإيجار'),
        Tab(text: 'المستخدمين'),
        Tab(text: 'الإعدادات'),
      ],
    ),
  );

  // ──────────────────────────────────────────────────────────
  // Tab 1: Rooms
  // ──────────────────────────────────────────────────────────
  Widget _buildRoomsTab() {
    if (_loadingRooms) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_rooms.isEmpty) return _empty('لا توجد غرف', Icons.grid_view);

    return RefreshIndicator(
      onRefresh: _loadRooms,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rooms.length,
        itemBuilder: (_, i) => _roomCard(_rooms[i]),
      ),
    );
  }

  Widget _roomCard(RoomModel room) {
    final timeLeft = room.rentalTimeLeft;
    final expired  = room.isRentalExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: expired ? AppColors.error.withOpacity(0.5)
              : room.isRented ? AppColors.warning.withOpacity(0.5)
              : AppColors.borderDefault,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(room.categoryIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(room.title, style: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w700,
            fontSize: 14, color: AppColors.textPrimary))),
          if (room.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.success,
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('مباشر', style: TextStyle(
                  color: Colors.white, fontSize: 10, fontFamily: 'Cairo')),
            ),
        ]),
        const SizedBox(height: 4),
        Text('المضيف: ${room.hostName}  •  ${room.speakersCount + room.listenersCount} مستمع',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                color: AppColors.textMuted)),

        // Rental countdown
        if (room.isRented) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: expired ? AppColors.errorMuted : AppColors.warningMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(expired ? Icons.timer_off : Icons.timer,
                  color: expired ? AppColors.error : AppColors.warning, size: 16),
              const SizedBox(width: 6),
              Text(
                expired
                    ? 'انتهى الإيجار!'
                    : _formatDuration(timeLeft),
                style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700,
                  color: expired ? AppColors.error : AppColors.warning,
                ),
              ),
              if (room.renterName != null) ...[
                const Spacer(),
                Text('صاحب الغرفة: ${room.renterName}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                        color: AppColors.textMuted)),
              ],
            ]),
          ),
        ],

        // Actions
        const SizedBox(height: 8),
        Row(children: [
          _actionBtn(
            label: room.isLive ? 'إغلاق' : 'فتح',
            color: room.isLive ? AppColors.error : AppColors.success,
            onTap: () => _toggleRoom(room),
          ),
          const SizedBox(width: 6),
          _actionBtn(
            label: 'إدارة الإيجار',
            color: AppColors.primary,
            onTap: () => _showRentalDialog(room),
          ),
          const SizedBox(width: 6),
          _actionBtn(
            label: 'دخول',
            color: AppColors.info,
            onTap: () => context.push('/room/${room.id}'),
          ),
          const SizedBox(width: 6),
          _actionBtn(
            label: 'تعديل',
            color: AppColors.textSecondary,
            onTap: () => _showEditRoomDialog(room),
          ),
          const SizedBox(width: 6),
          _actionBtn(
            label: 'حذف',
            color: AppColors.error,
            onTap: () => _confirmDeleteRoom(room),
          ),
        ]),
      ]),
    );
  }

  Future<void> _confirmDeleteRoom(RoomModel room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('حذف الغرفة', style: TextStyle(fontFamily: 'Cairo')),
          content: Text(
            'حذف «${room.title}» نهائياً؟ قد تبقى رسائل فرعية في Firestore.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await FirestoreService.instance.deleteRoom(room.id);
      _snack('تم حذف الغرفة');
      await _loadRooms();
    } catch (e) {
      _snack('خطأ: $e', isError: true);
    }
  }

  Future<void> _showEditRoomDialog(RoomModel room) async {
    final titleCtrl = TextEditingController(text: room.title);
    final descCtrl = TextEditingController(text: room.description);
    final capCtrl = TextEditingController(text: room.maxCapacity.toString());
    // ✅ FIX: حقل الأدمن المعين من لوحة التحكم
    final adminUidCtrl = TextEditingController(text: room.designatedRoomAdminUid ?? '');
    final adminNameCtrl = TextEditingController(text: room.designatedRoomAdminName ?? '');
    String category = room.category;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('تعديل الغرفة',
              style: TextStyle(fontFamily: 'Cairo')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الغرفة',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                  ),
                  items: AppConstants.roomCategories
                      .map((c) => DropdownMenuItem(
                            value: c['id']!,
                            child: Text('${c['icon']} ${c['label']}',
                                style: const TextStyle(fontFamily: 'Cairo')),
                          ))
                      .toList(),
                  onChanged: (v) => setDlg(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعة القصوى',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 16),
                // ✅ FIX: حقل الأدمن المعين — UID
                const Text('─── أدمن الغرفة المعيّن ───',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: adminUidCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UID المستخدم (أدمن الغرفة)',
                    hintText: 'الـ UID من Firestore users',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                    hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: adminNameCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الأدمن المعيّن',
                    labelStyle: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () async {
                final cap = int.tryParse(capCtrl.text.trim()) ?? room.maxCapacity;
                try {
                  // ✅ FIX: حفظ الأدمن المعيّن
                  await FirestoreService.instance.updateRoomBasicInfo(
                    room.id,
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    category: category,
                    maxCapacity: cap,
                    designatedRoomAdminUid: adminUidCtrl.text.trim().isEmpty ? null : adminUidCtrl.text.trim(),
                    designatedRoomAdminName: adminNameCtrl.text.trim().isEmpty ? null : adminNameCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _snack('تم تحديث الغرفة');
                    await _loadRooms();
                  }
                } catch (e) {
                  if (mounted) {
                    _snack('خطأ: $e', isError: true);
                  }
                }
              },
              child: const Text('حفظ',
                  style: TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
    capCtrl.dispose();
    adminUidCtrl.dispose();
    adminNameCtrl.dispose();
  }

  Widget _actionBtn({required String label, required Color color, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: TextStyle(
              color: color, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
        ),
      );

  Future<void> _toggleRoom(RoomModel room) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colRooms)
          .doc(room.id)
          .update({'isLive': !room.isLive});
      _loadRooms();
    } catch (e) {
      _snack('حدث خطأ: $e', isError: true);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Rental Dialog
  // ──────────────────────────────────────────────────────────
  void _showRentalDialog(RoomModel room) {
    DateTime startDate = room.rentalStartAt ?? DateTime.now();
    DateTime endDate   = room.rentalExpiresAt ?? DateTime.now().add(const Duration(days: 30));
    final renterCtrl   = TextEditingController(text: room.renterName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إدارة إيجار: ${room.title}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 15,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Renter name
              TextField(
                controller: renterCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'اسم صاحب الغرفة (المستأجر)',
                  labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 16),

              // Start date
              _datePicker(
                label: 'تاريخ البداية',
                value: startDate,
                onPick: (d) => setDlgState(() => startDate = d),
              ),
              const SizedBox(height: 10),

              // End date
              _datePicker(
                label: 'تاريخ الانتهاء',
                value: endDate,
                onPick: (d) => setDlgState(() => endDate = d),
              ),
              const SizedBox(height: 14),

              // Time left preview
              if (endDate.isAfter(DateTime.now()))
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.timer, color: AppColors.warning, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'المدة المتبقية: ${_formatDuration(endDate.difference(DateTime.now()))}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                          color: AppColors.warning, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
            ]),
          ),
          actions: [
            if (room.isRented)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _clearRental(room);
                },
                child: const Text('إلغاء الإيجار',
                    style: TextStyle(color: AppColors.error, fontFamily: 'Cairo')),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(
                  color: AppColors.textMuted, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveRental(room, startDate, endDate, renterCtrl.text.trim());
              },
              child: const Text('حفظ', style: TextStyle(
                  fontFamily: 'Cairo', fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPick,
  }) =>
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          );
          if (d != null) {
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(value),
            );
            if (t != null) {
              onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11,
                  color: AppColors.textMuted, fontFamily: 'Cairo')),
              Text(
                '${value.day}/${value.month}/${value.year}  ${value.hour.toString().padLeft(2,'0')}:${value.minute.toString().padLeft(2,'0')}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ]),
          ]),
        ),
      );

  Future<void> _saveRental(RoomModel room, DateTime start, DateTime end, String renterName) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colRooms)
          .doc(room.id)
          .update({
        'rentalStartAt':   Timestamp.fromDate(start),
        'rentalExpiresAt': Timestamp.fromDate(end),
        'renterName': renterName.isEmpty ? null : renterName,
      });
      _snack('تم حفظ بيانات الإيجار');
      _loadRooms();
    } catch (e) {
      _snack('حدث خطأ: $e', isError: true);
    }
  }

  Future<void> _clearRental(RoomModel room) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colRooms)
          .doc(room.id)
          .update({
        'rentalStartAt':   null,
        'rentalExpiresAt': null,
        'renterName': null,
      });
      _snack('تم إلغاء الإيجار');
      _loadRooms();
    } catch (e) {
      _snack('حدث خطأ: $e', isError: true);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Tab 2: Rental Overview
  // ──────────────────────────────────────────────────────────
  Widget _buildRentalTab() {
    final rented  = _rooms.where((r) => r.isRented).toList();
    final expired = rented.where((r) => r.isRentalExpired).toList();
    final active  = rented.where((r) => !r.isRentalExpired).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (expired.isNotEmpty) ...[
          _sectionTitle('انتهى إيجارها (${expired.length})', AppColors.error),
          ...expired.map((r) => _rentalCard(r)),
          const SizedBox(height: 12),
        ],
        _sectionTitle('إيجار نشط (${active.length})', AppColors.success),
        if (active.isEmpty)
          _empty('لا توجد غرف مؤجرة حالياً', Icons.key_rounded)
        else
          ...active.map((r) => _rentalCard(r)),
      ]),
    );
  }

  Widget _sectionTitle(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(width: 4, height: 18, color: color,
          margin: const EdgeInsets.only(left: 8)),
      Text(text, style: TextStyle(fontFamily: 'Cairo', fontSize: 14,
          fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  Widget _rentalCard(RoomModel room) {
    final timeLeft = room.rentalTimeLeft;
    final expired  = room.isRentalExpired;
    final pct = room.rentalStartAt != null
        ? (room.rentalExpiresAt!.difference(DateTime.now()).inMinutes /
           room.rentalExpiresAt!.difference(room.rentalStartAt!).inMinutes)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expired ? AppColors.error : AppColors.warning,
          width: 1.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(room.categoryIcon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(room.title, style: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w700,
            fontSize: 14, color: AppColors.textPrimary))),
          InkWell(
            onTap: () => _showRentalDialog(room),
            child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
          ),
        ]),
        if (room.renterName != null)
          Text('المستأجر: ${room.renterName}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                  color: AppColors.textSecondary)),
        const SizedBox(height: 8),

        // Progress bar
        if (!expired)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.bgTertiary,
              color: pct < 0.2 ? AppColors.error
                  : pct < 0.5 ? AppColors.warning
                  : AppColors.success,
              minHeight: 6,
            ),
          ),
        const SizedBox(height: 6),

        Row(children: [
          Icon(expired ? Icons.timer_off : Icons.timer,
              size: 14, color: expired ? AppColors.error : AppColors.warning),
          const SizedBox(width: 4),
          Text(
            expired ? 'انتهى الإيجار!' : 'متبقي: ${_formatDuration(timeLeft)}',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700,
                color: expired ? AppColors.error : AppColors.warning),
          ),
          const Spacer(),
          if (room.rentalExpiresAt != null)
            Text(
              'ينتهي: ${room.rentalExpiresAt!.day}/${room.rentalExpiresAt!.month}/${room.rentalExpiresAt!.year}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11,
                  color: AppColors.textMuted),
            ),
        ]),

        if (expired) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _actionBtn(
              label: 'إغلاق الغرفة',
              color: AppColors.error,
              onTap: () => _toggleRoom(room),
            )),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(
              label: 'تجديد الإيجار',
              color: AppColors.success,
              onTap: () => _showRentalDialog(room),
            )),
          ]),
        ],
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tab 3: Users
  // ──────────────────────────────────────────────────────────
  Widget _buildUsersTab() => Column(children: [
    Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو البريد...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              filled: true, fillColor: AppColors.bgSecondary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderDefault)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
            onSubmitted: (_) => _searchUsers(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onPressed: _searchUsers,
          child: const Icon(Icons.search, color: Colors.white, size: 18),
        ),
      ]),
    ),
    Expanded(
      child: _loadingUsers
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _users.isEmpty
              ? _empty('ابحث عن مستخدم', Icons.person_search)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _users.length,
                  itemBuilder: (_, i) => _userCard(_users[i]),
                ),
    ),
  ]);

  Widget _userCard(UserModel user) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: user.isBanned
          ? AppColors.error.withOpacity(0.3) : AppColors.borderDefault),
    ),
    child: Row(children: [
      UserAvatar(imageUrl: user.photoURL, name: user.displayName, size: 40),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(user.displayName, style: const TextStyle(
            fontFamily: 'Cairo', fontWeight: FontWeight.w700,
            fontSize: 13, color: AppColors.textPrimary)),
          if (user.isBanned)
            Container(margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.error,
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('محظور', style: TextStyle(
                  color: Colors.white, fontSize: 9, fontFamily: 'Cairo'))),
        ]),
        Text(user.email, style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
      ])),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
        onSelected: (v) => _handleUserAction(v, user),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'ban',
              child: Text('حظر', style: TextStyle(fontFamily: 'Cairo', color: AppColors.error))),
          if (user.isBanned)
            const PopupMenuItem(value: 'unban',
                child: Text('رفع الحظر', style: TextStyle(fontFamily: 'Cairo', color: AppColors.success))),
        ],
      ),
    ]),
  );

  Future<void> _handleUserAction(String action, UserModel user) async {
    try {
      if (action == 'ban') {
        await FirestoreService.instance.banUser(user.uid, 'حظر من لوحة التحكم');
        _snack('تم حظر ${user.displayName}');
      } else if (action == 'unban') {
        await FirestoreService.instance.unbanUser(user.uid);
        _snack('تم رفع الحظر عن ${user.displayName}');
      }
      _searchUsers();
    } catch (e) {
      _snack('حدث خطأ: $e', isError: true);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Tab 4: Settings / Kill-Switch
  // ──────────────────────────────────────────────────────────
  Widget _buildSettingsTab() {
    final appProv = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Kill switch card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appProv.isLocked
                ? AppColors.error : AppColors.borderDefault),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(appProv.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  color: appProv.isLocked ? AppColors.error : AppColors.success, size: 22),
              const SizedBox(width: 8),
              Text(
                appProv.isLocked ? 'التطبيق محجوب الآن' : 'التطبيق يعمل بشكل طبيعي',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                    color: appProv.isLocked ? AppColors.error : AppColors.success),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _lockMsgCtrl,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'رسالة الحجب (تظهر للمستخدمين)...',
                hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_rounded, size: 16),
                  label: const Text('حجب التطبيق', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await context.read<AppProvider>().setLockState(true,
                        message: _lockMsgCtrl.text.trim().isEmpty
                            ? AppConstants.killSwitchDefaultMsg
                            : _lockMsgCtrl.text.trim());
                    _snack('تم حجب التطبيق');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('فتح التطبيق', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await context.read<AppProvider>().setLockState(false);
                    _snack('تم فتح التطبيق');
                  },
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Support inbox button
        ElevatedButton.icon(
          icon: const Icon(Icons.support_agent_rounded, size: 18),
          label: const Text('صندوق رسائل الدعم', style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SupportAdminInbox(),
              ),
            );
          },
        ),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    if (d.isNegative) return 'انتهى';
    final days    = d.inDays;
    final hours   = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) return '${days}ي ${hours}س ${minutes}د';
    if (hours > 0) return '${hours}س ${minutes}د ${seconds}ث';
    return '${minutes}د ${seconds}ث';
  }

  Widget _empty(String msg, IconData icon) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: AppColors.borderDefault),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(fontFamily: 'Cairo',
          fontSize: 15, color: AppColors.textMuted)),
    ]),
  );

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      duration: const Duration(seconds: 2),
    ));
  }
}
