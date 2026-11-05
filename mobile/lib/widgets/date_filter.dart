import 'package:flutter/material.dart';

DateTime localDay(DateTime value) {
  final d = value.toLocal();
  return DateTime(d.year, d.month, d.day);
}

bool inDateRange(DateTime? date, DateTimeRange? range) {
  if (range == null) return true;
  if (date == null) return false;
  final day = localDay(date);
  return !day.isBefore(localDay(range.start)) &&
      !day.isAfter(localDay(range.end));
}

String displayDay(DateTime value) {
  final d = value.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class DateFilterBar extends StatelessWidget {
  const DateFilterBar(
      {super.key,
      required this.value,
      required this.onChanged,
      this.label = 'Ngày đặt đơn'});
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final String label;
  static Map<String, DateTimeRange?> presets(DateTime now) {
    final today = localDay(now);
    return {
      'Tất cả ngày': null,
      'Hôm nay': DateTimeRange(start: today, end: today),
      '7 ngày gần đây': DateTimeRange(
        start: DateTime(today.year, today.month, today.day - 6),
        end: today,
      ),
      '30 ngày gần đây': DateTimeRange(
        start: DateTime(today.year, today.month, today.day - 29),
        end: today,
      ),
      'Tháng này':
          DateTimeRange(start: DateTime(today.year, today.month), end: today),
    };
  }

  @override
  Widget build(BuildContext context) {
    final options = presets(DateTime.now());
    final selected =
        options.entries.where((e) => e.value == value).firstOrNull?.key ??
            'Chọn khoảng ngày';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_month_outlined),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                isDense: true,
                items: [
                  for (final name in [...options.keys, 'Chọn khoảng ngày'])
                    DropdownMenuItem(value: name, child: Text(name))
                ],
                onChanged: (name) async {
                  if (name == null) return;
                  if (name != 'Chọn khoảng ngày') {
                    onChanged(options[name]);
                    return;
                  }
                  final today = localDay(DateTime.now());
                  final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: today,
                      initialDateRange: value,
                      helpText: 'Chọn khoảng ngày',
                      saveText: 'Áp dụng',
                      cancelText: 'Hủy');
                  if (range != null) onChanged(range);
                }),
          ),
        ),
        if (value != null)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${displayDay(value!.start)} – ${displayDay(value!.end)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF738078),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => onChanged(null),
                child: const Text('Bỏ lọc ngày'),
              )
            ],
          )
      ],
    );
  }
}
