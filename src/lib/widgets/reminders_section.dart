import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service_reminders.dart';

class ReminderSection extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const ReminderSection({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<ReminderSection> createState() => _ReminderSectionState();
}

class _ReminderSectionState extends State<ReminderSection> {
  late final ApiServicesGetRecordatorios _apiService;
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiServicesGetRecordatorios();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final recordatorios = await _apiService.getRecordatorio();
      setState(() {
        _reminders = recordatorios
            .map((r) => Reminder(
                  description: r.descripcion,
                  date: r.fecha,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6, // Altura fija
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) return _buildErrorWidget();
    if (_isLoading) return _buildLoadingWidget();
    if (_reminders.isEmpty) return _buildEmptyWidget();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _reminders.length,
            itemBuilder: (context, index) {
              return _buildReminderItem(_reminders[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF228B22)),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No hay recordatorios',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
                foregroundColor: Colors.white,
              ),
              onPressed: _loadReminders,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(Icons.notifications_active, color: Colors.green[700]),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reminder.description,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMM').format(reminder.date),
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        children: [
          _buildMiniCalendar(reminder.date),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(DateTime reminderDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: reminderDate,
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(formatButtonVisible: false),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.green[700],
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          markerSize: 6,
        ),
        selectedDayPredicate: (day) => isSameDay(day, reminderDate),
        onDaySelected: (selectedDay, focusedDay) =>
            widget.onDateSelected(selectedDay),
      ),
    );
  }
}

class Reminder {
  final String description;
  final DateTime date;

  Reminder({
    required this.description,
    required this.date,
  });
}
