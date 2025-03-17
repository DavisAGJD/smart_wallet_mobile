import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../services/api_service_notifications.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiServiceNotifications _apiService = ApiServiceNotifications();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications =
          await _apiService.getNotificationsByUser(widget.userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener las notificaciones: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la notificación: $e')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _apiService.updateNotification(notificationId, {'leida': 1});
      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['leida'] = 1;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al marcar la notificación como leída: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tamaño de pantalla para adaptar márgenes y fuentes
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.04;
    final verticalPadding = size.height * 0.01;
    final titleFontSize = size.width * 0.05;
    final subtitleFontSize = size.width * 0.04;
    final containerPadding = size.width * 0.04;
    final marginVertical = size.height * 0.015;
    final marginHorizontal = size.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF228B22),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    'No tienes notificaciones',
                    style: TextStyle(
                        fontSize: size.width * 0.045, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = (notification['leida'] as int) == 1;
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: marginHorizontal,
                        vertical: marginVertical,
                      ),
                      padding: EdgeInsets.all(containerPadding),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.grey.shade200 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color:
                                isRead ? Colors.grey : const Color(0xFF00DDA3),
                            size: size.width * 0.06,
                          ),
                          SizedBox(width: horizontalPadding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['mensaje'] ?? 'Sin mensaje',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: verticalPadding),
                                Text(
                                  notification['fecha'] ?? 'Sin fecha',
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.red, size: size.width * 0.06),
                            onPressed: () =>
                                _deleteNotification(notification['id']),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.check_circle,
                              color: isRead
                                  ? Colors.grey
                                  : const Color(0xFF00DDA3),
                              size: size.width * 0.06,
                            ),
                            onPressed: () => _markAsRead(notification['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
