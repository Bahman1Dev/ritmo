// lib/features/sports/presentation/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

/// صفحه پیشرفت — در حال توسعه
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RitmoTheme.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'پیشرفت',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'صفحه پیشرفت — در حال توسعه',
          style: TextStyle(
            color: Colors.white54,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}
