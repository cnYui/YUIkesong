import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.images, required this.username, required this.avatar});

  static const routeName = '/post-detail';

  final List<String> images;
  final String username;
  final String avatar;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: StitchColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '帖子详情',
          style: TextStyle(
            color: StitchColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) {
                    return Image.network(widget.images[index], fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                final selected = index == _currentImageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 12 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : const Color(0xFFCED1D6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.avatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: StitchColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '今天的穿搭分享：简约与质感并存，轻松应对通勤与休闲场景。',
              style: TextStyle(fontSize: 14, color: StitchColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                _ActionIcon(icon: Icons.favorite_border, label: '点赞'),
                SizedBox(width: 20),
                _ActionIcon(icon: Icons.mode_comment_outlined, label: '评论'),
                SizedBox(width: 20),
                _ActionIcon(icon: Icons.share_outlined, label: '分享'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '热门评论',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: StitchColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const _CommentPlaceholder(),
            const _CommentPlaceholder(),
            const _CommentPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: StitchColors.textPrimary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: StitchColors.textPrimary),
        ),
      ],
    );
  }
}

class _CommentPlaceholder extends StatelessWidget {
  const _CommentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 14, backgroundColor: Color(0xFFE5E7EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('用户A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('好看！很适合春秋季，颜色也很耐看。', style: TextStyle(fontSize: 13, color: StitchColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
