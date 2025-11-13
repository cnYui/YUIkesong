import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models/stitch_tab.dart';
import '../services/api_service.dart';
import '../state/wardrobe_selection_store.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';
import 'add_clothing_page.dart';
import 'ai_fitting_room_page.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final Set<int> _selectedIndices = {};

  static const _categories = ['全部', '上装', '下装', '连衣裙', '外套', '鞋履', '配饰', '包包'];

  List<Map<String, dynamic>> _clothingItems = [];
  bool _isLoading = true;
  String? _error;

  int _selectedCategoryIndex = 0;

  List<Map<String, dynamic>> get _filteredItems {
    final selected = _categories[_selectedCategoryIndex];
    if (selected == '全部') return _clothingItems;
    return _clothingItems.where((item) => item['category'] == selected).toList();
  }

  List<Map<String, dynamic>> get _selectedItems {
    return _selectedIndices.map((index) => _clothingItems[index]).toList();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      // 更新全局store
      WardrobeSelectionStore.setSelections(_selectedIndices);
      // 保存图片路径映射（使用image_path用于后端匹配）
      final imageMap = <int, String>{};
      for (var i = 0; i < _clothingItems.length; i++) {
        // 使用image_path而不是image_url，因为后端需要用这个字段匹配
        imageMap[i] = _clothingItems[i]['image_path'] ?? '';
      }
      WardrobeSelectionStore.setItemImages(imageMap);
    });
  }

  Future<void> _openSearchPage() async {
    final resultIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => WardrobeSearchPage(
          entries: List.generate(
            _clothingItems.length,
            (index) => WardrobeSearchEntry(index: index, itemData: _clothingItems[index]),
          ),
        ),
      ),
    );
    if (resultIndex != null) {
      setState(() {
        _selectedIndices.add(resultIndex);
        _selectedCategoryIndex = 0;
      });
    }
  }

  Future<void> _openFilterPage() async {
    final selectedCategory = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WardrobeFilterPage(
          categories: _categories,
          initialCategory: _categories[_selectedCategoryIndex],
        ),
      ),
    );
    if (selectedCategory != null) {
      final categoryIndex = _categories.indexOf(selectedCategory);
      if (categoryIndex != -1) {
        setState(() => _selectedCategoryIndex = categoryIndex);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadClothingItems();
  }

  Future<void> _loadClothingItems() async {
    try {
      // 检查用户是否已登录
      if (!ApiService.isAuthenticated) {
        setState(() {
          _error = '请先登录以查看您的衣柜';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService.getClothingItems();
      final List<dynamic> list = response['list'] ?? [];
      setState(() {
        _clothingItems = List<Map<String, dynamic>>.from(list);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载衣物失败: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载衣物失败: $e')),
      );
    }
  }

  Future<void> _navigateToAddClothing() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddClothingPage(),
      ),
    );
    
    // 如果添加成功，刷新数据
    if (result != null) {
      _loadClothingItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 72,
                  backgroundColor: const Color(0xFFF7F7F7),
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            '我的衣柜',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: StitchColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CircleIcon(Icons.search, onTap: _openSearchPage),
                            const SizedBox(width: 8),
                            _CircleIcon(Icons.tune, onTap: _openFilterPage),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    categories: _categories,
                    selectedIndex: _selectedCategoryIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  sliver: _isLoading
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      : _error != null
                          ? const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('加载衣物失败，请重试'),
                                ),
                              ),
                            )
                          : _clothingItems.isEmpty
                              ? const SliverToBoxAdapter(
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text('还没有添加任何衣物'),
                                    ),
                                  ),
                                )
                              : SliverGrid(
                                  delegate: SliverChildBuilderDelegate((context, index) {
                                    final item = _filteredItems[index];
                                    final itemIndex = _clothingItems.indexOf(item);
                                    final isSelected = _selectedIndices.contains(itemIndex);
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _toggleSelection(itemIndex),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                    ),
                                                    child: Image.network(
                                                      item['image_url'] ?? '',
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      height: 28,
                                                      width: 28,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius: BorderRadius.circular(
                                                          16,
                                                        ),
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
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['name'] ?? '未命名',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: StitchColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    );
                                  }, childCount: _filteredItems.length),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 20,
                                        crossAxisSpacing: 20,
                                        childAspectRatio: 0.78,
                                      ),
                                ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: _selectedIndices.isEmpty ? 120 : 210,
            child: FloatingActionButton(
              onPressed: _navigateToAddClothing,
              backgroundColor: Colors.white,
              foregroundColor: StitchColors.textPrimary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_a_photo, size: 28),
            ),
          ),
          if (_selectedIndices.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 96,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
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
                              ..._selectedItems.map((item) {
                                final itemIndex = _clothingItems.indexOf(item);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _toggleSelection(itemIndex),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item['image_url'] ?? '',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (_selectedItems.length < 3)
                                Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFF9CA3AF),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          if (StitchShellCoordinator.isReady) {
                            StitchShellCoordinator.selectTab(StitchTab.fittingRoom);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AiFittingRoomPage(
                                  currentTab: StitchTab.fittingRoom,
                                  onTabSelected: (tab) {
                                    Navigator.of(context).pop();
                                    StitchShellCoordinator.selectTab(tab);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          '一键生成',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StitchBottomNav(
              currentTab: widget.currentTab,
              onTabSelected: widget.onTabSelected,
              variant: BottomNavVariant.wardrobe,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon(this.icon, {this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 44,
          width: 44,
          child: Icon(icon, color: StitchColors.textPrimary),
        ),
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryHeaderDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(
                right: index == categories.length - 1 ? 0 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categories[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? StitchColors.textPrimary
                          : const Color(0xFF94959B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    width: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? StitchColors.textPrimary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.categories != categories;
  }
}

class WardrobeSearchEntry {
  const WardrobeSearchEntry({required this.index, required this.itemData});

  final int index;
  final Map<String, dynamic> itemData;
}

class WardrobeSearchPage extends StatefulWidget {
  const WardrobeSearchPage({super.key, required this.entries});

  final List<WardrobeSearchEntry> entries;

  @override
  State<WardrobeSearchPage> createState() => _WardrobeSearchPageState();
}

class _WardrobeSearchPageState extends State<WardrobeSearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.entries.where((entry) {
      if (_query.isEmpty) return true;
      final lower = _query.toLowerCase();
      final name = entry.itemData['name'] ?? '';
      final category = entry.itemData['category'] ?? '';
      return name.toLowerCase().contains(lower) ||
          category.toLowerCase().contains(lower);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: StitchColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '查找衣物',
          style: TextStyle(
            color: StitchColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '搜索衣物、类别或关键词',
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const Center(
              child: Text(
                '未找到匹配的衣物',
                style: TextStyle(
                  color: StitchColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return ListTile(
                  onTap: () => Navigator.of(context).pop(entry.index),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      entry.itemData['image_url'] ?? '',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    entry.itemData['name'] ?? '未命名',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    entry.itemData['category'] ?? '未分类',
                    style: const TextStyle(
                      fontSize: 13,
                      color: StitchColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
    );
  }
}

class WardrobeFilterPage extends StatefulWidget {
  const WardrobeFilterPage({
    super.key,
    required this.categories,
    required this.initialCategory,
  });

  final List<String> categories;
  final String initialCategory;

  @override
  State<WardrobeFilterPage> createState() => _WardrobeFilterPageState();
}

class _WardrobeFilterPageState extends State<WardrobeFilterPage> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
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
          icon: const Icon(Icons.close, color: StitchColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '筛选衣物',
          style: TextStyle(
            color: StitchColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _selectedCategory = '全部'),
            child: const Text(
              '重置',
              style: TextStyle(
                color: StitchColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '类别',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: StitchColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.categories.map((category) {
                final selected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : StitchColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  selectedColor: Colors.black,
                  backgroundColor: const Color(0xFFF7F7F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(context).pop(_selectedCategory),
                child: const Text(
                  '应用筛选',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
