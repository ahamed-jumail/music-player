import 'package:ajs_music_player/pages/home_page.dart';
import 'package:ajs_music_player/pages/offline_page.dart';
import 'package:ajs_music_player/pages/online_page.dart';
import 'package:flutter/material.dart';

class ParentPage extends StatefulWidget {
  const ParentPage({super.key});

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  int _index = 0;

  late final List<Widget> _pages = [
    HomePage(onNavigate: _changeTab),
    const OfflinePage(),
    OnlinePage(onNavigate: _changeTab),
  ];

  void _changeTab(int index) {
    if (index == _index) {
      return;
    }

    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: (_index == 0 || _index == 2)
          ? null
          : _navigationBar(),
    );
  }

  Widget _navigationBar() {
    return NavigationBar(
      height: 72,
      selectedIndex: _index,
      backgroundColor: const Color(0xff111111),
      indicatorColor: const Color(0xff00E5FF).withValues(alpha: .18),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: _changeTab,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.grey),
          selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
          label: 'HOME',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_music_outlined, color: Colors.grey),
          selectedIcon: Icon(Icons.library_music, color: Colors.white),
          label: 'OFFLINE',
        ),
        NavigationDestination(
          icon: Icon(Icons.cloud_outlined, color: Colors.grey),
          selectedIcon: Icon(Icons.cloud, color: Colors.white),
          label: 'ONLINE',
        ),
      ],
    );
  }
}
