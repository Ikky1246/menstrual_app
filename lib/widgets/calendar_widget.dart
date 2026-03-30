import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime initialDate;
  final Map<DateTime, Map<String, dynamic>>? events;
  final Function(DateTime)? onDateSelected;
  final bool showLegend;

  const CalendarWidget({
    super.key,
    required this.initialDate,
    this.events,
    this.onDateSelected,
    this.showLegend = true,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDate;
  late DateTime _selectedDate;
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'id');
  final DateFormat _dayFormat = DateFormat('EEEE', 'id');

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.initialDate;
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildWeekDays(),
          const SizedBox(height: 5),
          _buildCalendarGrid(),
          if (widget.showLegend) ...[
            const SizedBox(height: 15),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month - 1,
                );
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left,
                color: Colors.pink.shade400,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                _monthFormat.format(_focusedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dayFormat.format(_focusedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month + 1,
                );
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                color: Colors.pink.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) {
          return Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    int daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    int firstWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday;
    
    // Adjust for Monday as first day (1 = Monday in Dart)
    firstWeekday = firstWeekday - 1;
    
    List<Widget> dayWidgets = [];
    
    // Empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    
    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(_focusedDate.year, _focusedDate.month, day);
      bool isSelected = currentDate.day == _selectedDate.day &&
                        currentDate.month == _selectedDate.month &&
                        currentDate.year == _selectedDate.year;
      bool isToday = currentDate.day == DateTime.now().day &&
                     currentDate.month == DateTime.now().month &&
                     currentDate.year == DateTime.now().year;
      
      dayWidgets.add(
        _buildDayCell(day, currentDate, isSelected, isToday),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildDayCell(int day, DateTime date, bool isSelected, bool isToday) {
    final event = widget.events?[DateTime(date.year, date.month, date.day)];
    
    Color? backgroundColor;
    if (event != null) {
      switch(event['type']) {
        case 'menstruation':
          backgroundColor = Colors.red.withOpacity(0.2);
          break;
        case 'prediction':
          backgroundColor = Colors.pink.withOpacity(0.2);
          break;
        case 'ovulation':
          backgroundColor = Colors.purple.withOpacity(0.2);
          break;
        case 'fertile':
          backgroundColor = Colors.blue.withOpacity(0.2);
          break;
      }
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(date);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.pink, width: 2)
              : isToday
                  ? Border.all(color: Colors.pink.shade200, width: 1)
                  : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.pink
                  : isToday
                      ? Colors.pink.shade700
                      : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Colors.red, 'Haid'),
          _buildLegendItem(Colors.pink, 'Prediksi'),
          _buildLegendItem(Colors.purple, 'Ovulasi'),
          _buildLegendItem(Colors.blue, 'Masa Subur'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}