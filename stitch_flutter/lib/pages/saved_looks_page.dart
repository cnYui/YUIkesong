import 'package:flutter/material.dart';

import '../state/saved_looks_store.dart';

class SavedLooksPage extends StatefulWidget {
  const SavedLooksPage({super.key});

  static const routeName = '/saved-looks';

  @override
  State<SavedLooksPage> createState() => _SavedLooksPageState();
}

class _SavedLooksPageState extends State<SavedLooksPage> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '我保存的穿搭',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<SavedLook>>(
        valueListenable: SavedLooksStore.listenable,
        builder: (context, looks, _) {
          final existingIds = looks.map((look) => look.id).toSet();
          if (looks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SizedBox(height: 8),
                  Text(
                    '浏览并管理你保存的穿搭组合，随时重新查看灵感。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  SizedBox(height: 24),
                  Expanded(child: _SavedLooksEmptyView()),
                ],
              ),
            );
          }

          final invalidIds = _selectedIds.where(
            (id) => !existingIds.contains(id),
          );
          if (invalidIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedIds.removeAll(invalidIds));
            });
          }

          final selectedLooks = looks
              .where((look) => _selectedIds.contains(look.id))
              .toList(growable: false);

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '浏览并管理你保存的穿搭组合，随时重新查看灵感。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        itemCount: looks.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.6,
                            ),
                        itemBuilder: (context, index) {
                          final look = looks[index];
                          final isSelected = _selectedIds.contains(look.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(look.id);
                                } else {
                                  _selectedIds.add(look.id);
                                }
                              });
                            },
                            child: _SavedLookCard(
                              look: look,
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedLooks.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _SelectionBar(
                    looks: selectedLooks,
                    onDeletePressed: () => _handleDelete(selectedLooks),
                    onPublishPressed: () =>
                        _handlePublish(selectedLooks.length),
                    onLookTapped: (look) {
                      setState(() => _selectedIds.remove(look.id));
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleDelete(List<SavedLook> looks) {
    if (looks.isEmpty) return;
    for (final look in looks) {
      SavedLooksStore.removeLook(look.id);
    }
    setState(() => _selectedIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除选中的穿搭'), duration: Duration(seconds: 2)),
    );
  }

  void _handlePublish(int count) {
    if (count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已发布$count 套穿搭到社区（示例）'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SavedLooksEmptyView extends StatelessWidget {
  const _SavedLooksEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: Color(0xFFCED1D6)),
          SizedBox(height: 16),
          Text(
            '还没有保存的穿搭',
            style: TextStyle(fontSize: 16, color: Color(0xFF6C6C70)),
          ),
        ],
      ),
    );
  }
}

class _SavedLookCard extends StatelessWidget {
  const _SavedLookCard({required this.look, required this.isSelected});

  final SavedLook look;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  look.resultImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: look.clothingImages.length <= 2
                  ? Row(
                      children: [
                        for (var i = 0; i < look.clothingImages.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: i < look.clothingImages.length - 1
                                    ? 8
                                    : 0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  look.clothingImages[i],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: look.clothingImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              look.clothingImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.looks,
    required this.onDeletePressed,
    required this.onPublishPressed,
    required this.onLookTapped,
  });

  final List<SavedLook> looks;
  final VoidCallback onDeletePressed;
  final VoidCallback onPublishPressed;
  final ValueChanged<SavedLook> onLookTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final look in looks)
                      GestureDetector(
                        onTap: () => onLookTapped(look),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(look.resultImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: onDeletePressed,
              child: const Text(
                '删除',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: onPublishPressed,
              child: const Text(
                '发布社区',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
