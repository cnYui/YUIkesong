import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../models/stitch_tab.dart';
import '../state/wardrobe_selection_store.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';
import 'add_clothing_processing_page.dart';

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

  static const _items = [
    WardrobeItemData(
      name: '白色T恤',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuApweC_IRzecAv0S0RzevdL2C4LpmEH8lxnRpYmTwNHgXBFs1YxYahW5f5xjumsq6H6r9LZ92isNkaNDBtbzoSJvKMDGc5JxZyteXjzR54ZIidnq2Niwv1492BdIDczcbcRRw_IAGmi_TfrBn3ke-RCX-O9siCEcEkmENofPwr7bACoCERZJqE4dVlv6Ha3VlnQpd7iMxRZqF4B66iQeVSqCUXdPIvnqk4ncAgEOLu5tlQm65edTkyhDTDbvOUdysLs91-6I6Eu6zU',
      category: '上装',
    ),
    WardrobeItemData(
      name: '蓝色牛仔裤',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBc4BKS_D8IMC1vgVyjwjEF-FZJsTd-pu8kr-rinUcXUr-rDoSMU2wWwHZnfHK39KMcOR5OGkgra8VyBT8zdP2hC82FBOSv-yYogLwNEne9lQdGzasE21pF8B5yf48oSAPj-JpdA1f6UZiHKzM7cFjBzfG5jSCLsNK4giFmdryxUH5U4M8782DmHG4UwQSNrtNlQvvtHiXUiFmkK81lLg-3UmzCZpFCtUwAzU9Qye-8eRdN619f6xD10p0rOnTvpV7VCX1itw3HueI',
      category: '下装',
    ),
    WardrobeItemData(
      name: '黑色连衣裙',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDEY40ebw5io9194H7bDF20RZWQm8Z5XnJm8VZZ5N2J9Ftu3NEFsRLLUmKU9yTlJh-Gwg0tlXvXTX_Y2kBX93ciL1bBEMUbpytNNPig9Zha1ipOhA-KinpMpghpx7qAs4HQPhtnOF8Z3Bo42bSJHy76zXJIB8NO2f8Bh-wpr1qfbPsfYs1iGn6GxL1mj9nHGD75tPYchuXUpJ_7BGmeNvrbubtrgPEwE6ZwbTe0F_fpckcHsiVCHG04X-9y4tVTfV0Y6r_oUjvMCv8',
      category: '连衣裙',
    ),
    WardrobeItemData(
      name: '运动鞋',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBPloNa5aNoXRrDpKQ6XS2WIbCE3T5C8XmUuMRpyYS-j95-jwYStDf2Ljgg5a-icm12ypyEPAL-8jFaUcO0W25bZvKD0snBs5mxELx6lsOwZsB8THD2p6HxbMdUY_oMrTzjGZmzsuAvypuLA9cWyRdWw8MhuaXBfcx8pvsnqeZP56p8KDaHEKamDgVJE1fiylCjsShlEbSB2TFJpTiwWukXk64E6ZrlmvkpSnl-EORr7CyytZE3TLVzmoOdg0sa_KxiTmgJnZ6DpHg',
      category: '鞋履',
    ),
    WardrobeItemData(
      name: '太阳镜',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA6fVFlsBoQimKoT3s9SniLo-I8P8-zVmLPAi6Np2KiGoruYuUBeZ7L9pqq4OFU6yd0c9rruQ6lbpUGSqZABpDfvWqedmba7cQJAd-0oFSsZXmpXNwj7jlJ5yJHe--GY2pcO7kPNhDKc-bgGxbXIMzdEMSUN-W6JPLzxndubZCkcOjkK9vVMpQJ8Tbj_WxxFFX3SxSuecynD1bBtDxYulrCsRsZTUmrAgJ60FGMSv3swE28-0UssK8xHMj3e8P_02a0b3t9iuSjRB0',
      category: '配饰',
    ),
    WardrobeItemData(
      name: '手提包',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB7mykjxnzJyz1m2JQZm5i49X5nUAls9eyn_pYPyP_LLKKYa7XCF0oMU96gwGQBs40FUS0X2tS-RBPekTi-zcJ9ThiSW0uvZG4AYYf0hMJXIZCcIunGxDO3-1EIuIo9OMmzE-u2Y0xPDHl3VvpnYvige-k3v1Ew5D8Qtl1n4b3MedlQHZJdntr7M-MHSOtFBSVfqnuT9eqekzOluNghKszCrsbjBDAHmzKI-YJr5mWqlqsTZQUBaEA0At69gFHjLdQgeTp2Zx0Z_Js',
      category: '包包',
    ),
    WardrobeItemData(
      name: '条纹衬衫',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAc8pm5bvbuy7LrXPoX0D-msljlHWuELh8cS-je007GMkKeULCSPVGiCF8n1B363jp92gY-YOcwLBF_FuKHm9s-8C-2_LLPeoi13Q1OPDCJypMB1PhYyridvCDRZ8A1ZabZUO6SOB1ZO42n5RCaffMROdXBkGGdjkSsClX_AobowKlN6Ll7YqoKryKpuxOiGBtlkJj8OLbPogd5BMKyUTOCmcrCzM1mm9xnHty9rzvWKpUmVpDz4szWB7vdRuyj3XixV4LKa_rde4M',
      category: '上装',
    ),
    WardrobeItemData(
      name: '卡其色短裤',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCyou_Ay7EGZcINUmwokf-hngteoAjHo4HOlKKKqfTrT0AodgDSkgkPpAH88_at3v8JpCG7ZB620gj2LPl33CL2w5Ms4aeN8kUAJO3XAqRnc40WOo9SSMw9Z3-L_HVhmcH8bneD_jOtH4rMcmCl9ZKxr7D222WtDgHthFLTiMVmwBiUiIhCJL_-Ax6zVt5i9VFnLi5o213juz1pvOvU66ZZ0zgmtR24SCFel65oOmWZD7NjJsrvjOu6ZVA6N7IM0PXRMTi7j5_yVeM',
      category: '下装',
    ),
    WardrobeItemData(
      name: '印花半身裙',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD1LKL49mzR0AI5YsGvt3azlURRDnkM_KSzTjF2T6obJ4UGE4Z8OkGWDir0ty0HK_586Nh-5P88l1J5E65_KO5s_SVIt72Y2CpAi1ntHbipSGQa5GsfKNDpDMGiIB1UR9nRb18Tti9h1UwDq_AaXek0KyL-Fb7jT3kz79RkaaYF74gN-s0cRCBT-FJfPoEhbSCnGB-ULNgGavVYcVJvqwNWkryVyShD5_uF8nAboaVNSX0GRI-XfYGpY_Rz_Sc_JTbyhX1csbZ0aFA',
      category: '下装',
    ),
    WardrobeItemData(
      name: '高跟鞋',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB2mGaXRPi7NtXFSA5fjKPjWNFJLVnmb2EQwhzg6k0UeJU9QKoPbpmbEuIvP9CQqS6C9n8e1CuEXwYQev9tnVbHAEd6uFc9n22YgQ2btJRg31W7nE_DTnjJ54JLBoWz0PWHTPiDV4oPLHoXwEAHPHgaFzJh9XJv7c0qVcn4TY9DIUNXeYUEaIEeSoy6ZCISexhLbaJXQDNwwDvZHDhLIGMOtb-NBGz4ZQU_T_uNCaI7MHoarT6As1GOr_4zvQmippvPg3UXja0vHg4',
      category: '鞋履',
    ),
    WardrobeItemData(
      name: '羊毛围巾',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDlR4u_zYKI1yNt_vj-LY79jdOuFtWyDtiKkAeLucxiIrpHUzD9MDvR8pYcebpv20ek5z32WHIqcwRn2ZvopbMUCmurcLII927ZL5rpi-5-YasZayljzwPL9W8VQDMY6UuRL5hWwqtuEV0tAIJi9w9ipVoQJIEVkKkCzSS2DKS2K8UpYCKVB4pttcydbVkTo0MWoWVml7r6s1Sd3HheKO40_xona6JOOlsUwoVDDobroIIGPL-cLmItQMnfRjbA5pmi4Z2g6bcjNAg',
      category: '外套',
    ),
    WardrobeItemData(
      name: '双肩背包',
      image:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBqbrYufRlUaPDGEIg45sHxeFp2umPUZH1N9GHa0P9J6Jf8jrpilITqCP6rTNcjkwP4r_Z9QKvnkiX52bHRZZIJxL9IoQY2ueD23NTYdvgYYqz4-eY3F5U9UV68wvJTVq89hdU8s-KkBMBW0lvk7G_W17bK3XhCmf3cj3YhIRmN1EFodxHnUbN0eGwMiBGWT9cuSwkzsrN1D-hxJTm0x_Qph8lLd0NDZiXNs7zw2jjMhObzM8mj1KgKUWJzULVEd7Tr_s8u6Kk1G2A',
      category: '包包',
    ),
  ];

  int _selectedCategoryIndex = 0;

  List<WardrobeItemData> get _filteredItems {
    final selected = _categories[_selectedCategoryIndex];
    if (selected == '全部') return _items;
    return _items.where((item) => item.category == selected).toList();
  }

  List<WardrobeItemData> get _selectedItems {
    return _selectedIndices.map((index) => _items[index]).toList();
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
      // 保存图片映射
      final imageMap = <int, String>{};
      for (var i = 0; i < _items.length; i++) {
        imageMap[i] = _items[i].image;
      }
      WardrobeSelectionStore.setItemImages(imageMap);
    });
  }

  Future<void> _openSearchPage() async {
    final resultIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => WardrobeSearchPage(
          entries: List.generate(
            _items.length,
            (index) => WardrobeSearchEntry(index: index, item: _items[index]),
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
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _filteredItems[index];
                      final itemIndex = _items.indexOf(item);
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
                                        item.image,
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
                            item.name,
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
              onPressed: _showAddPhotoSheet,
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
                                final itemIndex = _items.indexOf(item);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _toggleSelection(itemIndex),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        item.image,
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
                        onPressed: () => StitchShellCoordinator.selectTab(
                          StitchTab.fittingRoom,
                        ),
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

  Future<void> _showAddPhotoSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera,
                    color: Colors.black87,
                  ),
                  title: const Text('拍照添加衣物'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.black87,
                  ),
                  title: const Text('从相册选择衣物'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, maxWidth: 2048);
      if (!mounted) return;
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        if (!mounted) return;
        final message = source == ImageSource.camera ? '已拍摄新衣物' : '已选择相册衣物';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$message：${image.name}')));
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddClothingProcessingPage(
              imageBytes: bytes,
              fileName: image.name,
            ),
            settings: const RouteSettings(
              name: AddClothingProcessingPage.routeName,
            ),
          ),
        );
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败：$err')));
    }
  }
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

class WardrobeItemData {
  const WardrobeItemData({
    required this.name,
    required this.image,
    required this.category,
  });

  final String name;
  final String image;
  final String category;
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
  const WardrobeSearchEntry({required this.index, required this.item});

  final int index;
  final WardrobeItemData item;
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
      return entry.item.name.toLowerCase().contains(lower) ||
          entry.item.category.toLowerCase().contains(lower);
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
                      entry.item.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    entry.item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    entry.item.category,
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
