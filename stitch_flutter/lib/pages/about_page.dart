import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const routeName = '/about';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '关于我们',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.diamond, size: 72, color: StitchColors.primary),
            const SizedBox(height: 16),
            const Text(
              '穿搭助手',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StitchColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '版本 1.0.0',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            const Text(
              '穿搭助手是一款基于Gemini API的智能穿衣应用，致力于为用户提供个性化的每日穿搭推荐、高效的衣物管理方案以及创新的AI试穿体验。我们相信，每个人都应该轻松展现自己的独特风格。',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: const [
                  _LinkRow(label: '隐私政策'),
                  Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _LinkRow(label: '用户协议'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '联系我们: contact@example.com',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            const Text(
              '© 2024 Your Company. All Rights Reserved.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: StitchColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B1B6)),
          ],
        ),
      ),
    );
  }
}
