import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'graphics_screen.dart';
import 'news_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/drawer_section.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
      _isLoading = false;
    });
  }

  /// Según el índice, se muestra la pantalla correspondiente.
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return GraphicsScreen();
      case 2:
        return NewsScreen();
      case 3:
        return _userId != null
            ? NotificationsScreen(userId: _userId!)
            : Center(child: CircularProgressIndicator());
      case 4:
        return ProfileScreen();
      default:
        return HomeScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF228B22).withOpacity(0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF228B22).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isSelected ? activeIcon : icon,
            key: ValueKey<bool>(isSelected),
            size: isSelected ? 28 : 24,
          ),
        ),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: List.generate(5, (index) => _buildScreen(index)),
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black12, width: 0.3)),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF33404F),
            selectedItemColor: const Color(0xFF228B22),
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedIndex,
            elevation: 8,
            iconSize: 26,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              height: 1.8,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              height: 1.8,
            ),
            onTap: _onItemTapped,
            items: [
              _buildNavItem(
                  0, Icons.home_outlined, Icons.home_filled, 'Inicio'),
              _buildNavItem(
                  1, Icons.bar_chart_outlined, Icons.bar_chart, 'Gráficas'),
              _buildNavItem(
                  2, Icons.article_outlined, Icons.article, 'Noticias'),
              _buildNavItem(3, Icons.notifications_outlined,
                  Icons.notifications, 'Notificaciones'),
              _buildNavItem(4, Icons.person_outlined, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
