// lib/screens/status_picker.dart
// مطابق 100% للصورة المرجعية: دوائر ملوّنة + إطار أزرق للمحدد
import 'package:flutter/material.dart';
import '../models/models.dart';

extension UserStatusFs on UserStatus {
  String get fsValue => name;
}

class StatusPicker extends StatelessWidget {
  final UserStatus current;
  final Function(UserStatus) onSelect;
  const StatusPicker({super.key, required this.current, required this.onSelect});

  // (status, dotColor, label, labelColor)
  static const _items = [
    (UserStatus.available, Color(0xFF4CAF50), 'متاح',   Color(0xFF4CAF50)),
    (UserStatus.away,      Color(0xFFFFC107), 'بالخارج', Color(0xFFFFC107)),
    (UserStatus.phone,     Color(0xFF000000), 'هاتف',   Color(0xFF26C6DA)),
    (UserStatus.busy,      Color(0xFFF44336), 'مشغول',  Color(0xFFF44336)),
    (UserStatus.driving,   Color(0xFFF44336), 'سيارة',  Color(0xFFF44336)),
    (UserStatus.eating,    Color(0xFFFFA726), 'طعام',   Color(0xFFFFA726)),
  ];

  static const _emojis = ['', '', '📱', '', '🚗', '🍔'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
              const Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_heart_outlined, color: Color(0xFF4A90D9), size: 20),
                    SizedBox(width: 8),
                    Text('تغيير حالتك', style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 32),
            ]),
            const SizedBox(height: 16),
            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final (status, dotColor, label, labelColor) = _items[i];
                final isSelected = current == status;
                return GestureDetector(
                  onTap: () { onSelect(status); Navigator.pop(context); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4A90D9) : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dot or emoji
                        status == UserStatus.phone || status == UserStatus.driving || status == UserStatus.eating
                          ? Text(_emojis[i], style: const TextStyle(fontSize: 28))
                          : Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                        const SizedBox(height: 6),
                        Text(label, style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
