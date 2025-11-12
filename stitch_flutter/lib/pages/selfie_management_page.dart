import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SelfieManagementPage extends StatefulWidget {
  const SelfieManagementPage({super.key});

  static const routeName = '/selfie-management';

  @override
  State<SelfieManagementPage> createState() => _SelfieManagementPageState();
}

class _SelfieManagementPageState extends State<SelfieManagementPage> {
  static const _images = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCeBnG-RJYwReA5PdBj2L8GdRunsfgcsYD-XIsWsHttDb89yxpuCuVu8s-QzQkLMX7mfFQLcW73EoaoTpVDU5woG4xjO7jvZmWUAx34yTlV4clAYYdC7xAwrZNSUR6w2g5BndIktVmiBEcXSfHgPl380QrVIuIgx7IW9432fOfndtFwyUCD3U1c-c2tOScs7bIpO673mVlHEr3Db58xFuL1pqF5mz--93cgR-l7WQHHDH9NxScg_S2io9-nEKeH89mWqHq_LZvAg08',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCS2u3ZvCvN8-rEa3SKbw-UGmgDRjbJzSlxSK_uDqyJ7YvCKEjqi8TRyk7c_D_lMOF1Db5UF4lwa9c3tp3EoO3Pip31yNyNnVK_qN1ezNq7oi7ZhHejrmeR8RP5MqI6Yu37xV5N_kfbHhNhHvAjRIVgvZCiMgKhP8aTSR_vGL0rAgM3Fd8HGIQFton5mMn9LuXp192SUNPCg2RmF4guaQ68suFU_JhVovHxM12ZKjq18RBxsVwvc4lo0LLfBtfuJbFaQrzoGgwIHdQ',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDjmvZl1hN2ObnYtB0sNnXmIgxa-wwJFwhTF41vqFtkEvMQ99rEaCJX21vzzlaokb9ZsY5YpL-h7D48BRZffegCpQ4rJne-83edrnUUZt802PzyNJcy8Dr8nXQ3EmGqyMhf0bc2hJJULl9z6Qknmz-xbgPMXLf6v308_dR8fNE5qoAO1EO8lW8BCoxSVNp7zPVlU7tbmmDIQcbLNyq8fQnyxs3PIyEPCjDN0YBPO7Cl03zG5KJyBLyG5GTYOx0wPXavh-Wy7_JypIk',
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '管理我的自拍',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: StitchColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              '选择一张清晰、光线充足、无遮挡的正面自拍，以获得最佳的试穿效果。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: _images.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {},
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 36,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '上传新自拍',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final selected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (selected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
