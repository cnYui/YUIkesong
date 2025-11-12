import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'add_clothing_save_page.dart';

class AddClothingProcessingPage extends StatefulWidget {
  const AddClothingProcessingPage({
    super.key,
    required this.imageBytes,
    required this.fileName,
  });

  final Uint8List imageBytes;
  final String fileName;

  static const routeName = '/add-clothing-processing';

  @override
  State<AddClothingProcessingPage> createState() =>
      _AddClothingProcessingPageState();
}

class _AddClothingProcessingPageState extends State<AddClothingProcessingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AddClothingSavePage(
            imageBytes: widget.imageBytes,
            fileName: widget.fileName,
          ),
          settings: const RouteSettings(name: AddClothingSavePage.routeName),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        title: const Text(
          'AI处理中...',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 192,
              width: 192,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 192,
                    width: 192,
                    child: CircularProgressIndicator(
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF13C8EC),
                      ),
                      backgroundColor: const Color(0x3313C8EC),
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome,
                    size: 56,
                    color: Color(0xFF13C8EC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '正在提取衣物特征，请稍候',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '这可能需要一点时间...',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
