import 'package:flutter/material.dart';

import '../main.dart';
import '../models/stitch_tab.dart';
import '../services/auth_service.dart';
import '../state/current_recommendation_store.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }

  static const _recommendations = [
    _Recommendation(
      title: '休闲街头风',
      subtitle: 'AI生成穿搭',
      images: [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuApweC_IRzecAv0S0RzevdL2C4LpmEH8lxnRpYmTwNHgXBFs1YxYahW5f5xjumsq6H6r9LZ92isNkaNDBtbzoSJvKMDGc5JxZyteXjzR54ZIidnq2Niwv1492BdIDczcbcRRw_IAGmi_TfrBn3ke-RCX-O9siCEcEkmENofPwr7bACoCERZJqE4dVlv6Ha3VlnQpd7iMxRZqF4B66iQeVSqCUXdPIvnqk4ncAgEOLu5tlQm65edTkyhDTDbvOUdysLs91-6I6Eu6zU',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBc4BKS_D8IMC1vgVyjwjEF-FZJsTd-pu8kr-rinUcXUr-rDoSMU2wWwHZnfHK39KMcOR5OGkgra8VyBT8zdP2hC82FBOSv-yYogLwNEne9lQdGzasE21pF8B5yf48oSAPj-JpdA1f6UZiHKzM7cFjBzfG5jSCLsNK4giFmdryxUH5U4M8782DmHG4UwQSNrtNlQvvtHiXUiFmkK81lLg-3UmzCZpFCtUwAzU9Qye-8eRdN619f6xD10p0rOnTvpV7VCX1itw3HueI',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBPloNa5aNoXRrDpKQ6XS2WIbCE3T5C8XmUuMRpyYS-j95-jwYStDf2Ljgg5a-icm12ypyEPAL-8jFaUcO0W25bZvKD0snBs5mxELx6lsOwZsB8THD2p6HxbMdUY_oMrTzjGZmzsuAvypuLA9cWyRdWw8MhuaXBfcx8pvsnqeZP56p8KDaHEKamDgVJE1fiylCjsShlEbSB2TFJpTiwWukXk64E6ZrlmvkpSnl-EORr7CyytZE3TLVzmoOdg0sa_KxiTmgJnZ6DpHg',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB7mykjxnzJyz1m2JQZm5i49X5nUAls9eyn_pYPyP_LLKKYa7XCF0oMU96gwGQBs40FUS0X2tS-RBPekTi-zcJ9ThiSW0uvZG4AYYf0hMJXIZCcIunGxDO3-1EIuIo9OMmzE-u2Y0xPDHl3VvpnYvige-k3v1Ew5D8Qtl1n4b3MedlQHZJdntr7M-MHSOtFBSVfqnuT9eqekzOluNghKszCrsbjBDAHmzKI-YJr5mWqlqsTZQUBaEA0At69gFHjLdQgeTp2Zx0Z_Js',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAc8pm5bvbuy7LrXPoX0D-msljlHWuELh8cS-je007GMkKeULCSPVGiCF8n1B363jp92gY-YOcwLBF_FuKHm9s-8C-2_LLPeoi13Q1OPDCJypMB1PhYyridvCDRZ8A1ZabZUO6SOB1ZO42n5RCaffMROdXBkGGdjkSsClX_AobowKlN6Ll7YqoKryKpuxOiGBtlkJj8OLbPogd5BMKyUTOCmcrCzM1mm9xnHty9rzvWKpUmVpDz4szWB7vdRuyj3XixV4LKa_rde4M',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBqbrYufRlUaPDGEIg45sHxeFp2umPUZH1N9GHa0P9J6Jf8jrpilITqCP6rTNcjkwP4r_Z9QKvnkiX52bHRZZIJxL9IoQY2ueD23NTYdvgYYqz4-eY3F5U9UV68wvJTVq89hdU8s-KkBMBW0lvk7G_W17bK3XhCmf3cj3YhIRmN1EFodxHnUbN0eGwMiBGWT9cuSwkzsrN1D-hxJTm0x_Qph8lLd0NDZiXNs7zw2jjMhObzM8mj1KgKUWJzULVEd7Tr_s8u6Kk1G2A',
      ],
    ),
    _Recommendation(
      title: '职场精英装',
      subtitle: 'AI生成穿搭',
      images: [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDEY40ebw5io9194H7bDF20RZWQm8Z5XnJm8VZZ5N2J9Ftu3NEFsRLLUmKU9yTlJh-Gwg0tlXvXTX_Y2kBX93ciL1bBEMUbpytNNPig9Zha1ipOhA-KinpMpghpx7qAs4HQPhtnOF8Z3Bo42bSJHy76zXJIB8NO2f8Bh-wpr1qfbPsfYs1iGn6GxL1mj9nHGD75tPYchuXUpJ_7BGmeNvrbubtrgPEwE6ZwbTe0F_fpckcHsiVCHG04X-9y4tVTfV0Y6r_oUjvMCv8',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDlR4u_zYKI1yNt_vj-LY79jdOuFtWyDtiKkAeLucxiIrpHUzD9MDvR8pYcebpv20ek5z32WHIqcwRn2ZvopbMUCmurcLII927ZL5rpi-5-YasZayljzwPL9W8VQDMY6UuRL5hWwqtuEV0tAIJi9w9ipVoQJIEVkKkCzSS2DKS2K8UpYCKVB4pttcydbVkTo0MWoWVml7r6s1Sd3HheKO40_xona6JOOlsUwoVDDobroIIGPL-cLmItQMnfRjbA5pmi4Z2g6bcjNAg',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB2mGaXRPi7NtXFSA5fjKPjWNFJLVnmb2EQwhzg6k0UeJU9QKoPbpmbEuIvP9CQqS6C9n8e1CuEXwYQev9tnVbHAEd6uFc9n22YgQ2btJRg31W7nE_DTnjJ54JLBoWz0PWHTPiDV4oPLHoXwEAHPHgaFzJh9XJv7c0qVcn4TY9DIUNXeYUEaIEeSoy6ZCISexhLbaJXQDNwwDvZHDhLIGMOtb-NBGz4ZQU_T_uNCaI7MHoarT6As1GOr_4zvQmippvPg3UXja0vHg4',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBPloNa5aNoXRrDpKQ6XS2WIbCE3T5C8XmUuMRpyYS-j95-jwYStDf2Ljgg5a-icm12ypyEPAL-8jFaUcO0W25bZvKD0snBs5mxELx6lsOwZsB8THD2p6HxbMdUY_oMrTzjGZmzsuAvypuLA9cWyRdWw8MhuaXBfcx8pvsnqeZP56p8KDaHEKamDgVJE1fiylCjsShlEbSB2TFJpTiwWukXk64E6ZrlmvkpSnl-EORr7CyytZE3TLVzmoOdg0sa_KxiTmgJnZ6DpHg',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA6fVFlsBoQimKoT3s9SniLo-I8P8-zVmLPAi6Np2KiGoruYuUBeZ7L9pqq4OFU6yd0c9rruQ6lbpUGSqZABpDfvWqedmba7cQJAd-0oFSsZXmpXNwj7jlJ5yJHe--GY2pcO7kPNhDKc-bgGxbXIMzdEMSUN-W6JPLzxndubZCkcOjkK9vVMpQJ8Tbj_WxxFFX3SxSuecynD1bBtDxYulrCsRsZTUmrAgJ60FGMSv3swE28-0UssK8xHMj3e8P_02a0b3t9iuSjRB0',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBqbrYufRlUaPDGEIg45sHxeFp2umPUZH1N9GHa0P9J6Jf8jrpilITqCP6rTNcjkwP4r_Z9QKvnkiX52bHRZZIJxL9IoQY2ueD23NTYdvgYYqz4-eY3F5U9UV68wvJTVq89hdU8s-KkBMBW0lvk7G_W17bK3XhCmf3cj3YhIRmN1EFodxHnUbN0eGwMiBGWT9cuSwkzsrN1D-hxJTm0x_Qph8lLd0NDZiXNs7zw2jjMhObzM8mj1KgKUWJzULVEd7Tr_s8u6Kk1G2A',
      ],
    ),
    _Recommendation(
      title: '周末舒适风',
      subtitle: 'AI生成穿搭',
      images: [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuApweC_IRzecAv0S0RzevdL2C4LpmEH8lxnRpYmTwNHgXBFs1YxYahW5f5xjumsq6H6r9LZ92isNkaNDBtbzoSJvKMDGc5JxZyteXjzR54ZIidnq2Niwv1492BdIDczcbcRRw_IAGmi_TfrBn3ke-RCX-O9siCEcEkmENofPwr7bACoCERZJqE4dVlv6Ha3VlnQpd7iMxRZqF4B66iQeVSqCUXdPIvnqk4ncAgEOLu5tlQm65edTkyhDTDbvOUdysLs91-6I6Eu6zU',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCyou_Ay7EGZcINUmwokf-hngteoAjHo4HOlKKKqfTrT0AodgDSkgkPpAH88_at3v8JpCG7ZB620gj2LPl33CL2w5Ms4aeN8kUAJO3XAqRnc40WOo9SSMw9Z3-L_HVhmcH8bneD_jOtH4rMcmCl9ZKxr7D222WtDgHthFLTiMVmwBiUiIhCJL_-Ax6zVt5i9VFnLi5o213juz1pvOvU66ZZ0zgmtR24SCFel65oOmWZD7NjJsrvjOu6ZVA6N7IM0PXRMTi7j5_yVeM',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD1LKL49mzR0AI5YsGvt3azlURRDnkM_KSzTjF2T6obJ4UGE4Z8OkGWDir0ty0HK_586Nh-5P88l1J5E65_KO5s_SVIt72Y2CpAi1ntHbipSGQa5GsfKNDpDMGiIB1UR9nRb18Tti9h1UwDq_AaXek0KyL-Fb7jT3kz79RkaaYF74gN-s0cRCBT-FJfPoEhbSCnGB-ULNgGavVYcVJvqwNWkryVyShD5_uF8nAboaVNSX0GRI-XfYGpY_Rz_Sc_JTbyhX1csbZ0aFA',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB2mGaXRPi7NtXFSA5fjKPjWNFJLVnmb2EQwhzg6k0UeJU9QKoPbpmbEuIvP9CQqS6C9n8e1CuEXwYQev9tnVbHAEd6uFc9n22YgQ2btJRg31W7nE_DTnjJ54JLBoWz0PWHTPiDV4oPLHoXwEAHPHgaFzJh9XJv7c0qVcn4TY9DIUNXeYUEaIEeSoy6ZCISexhLbaJXQDNwwDvZHDhLIGMOtb-NBGz4ZQU_T_uNCaI7MHoarT6As1GOr_4zvQmippvPg3UXja0vHg4',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA6fVFlsBoQimKoT3s9SniLo-I8P8-zVmLPAi6Np2KiGoruYuUBeZ7L9pqq4OFU6yd0c9rruQ6lbpUGSqZABpDfvWqedmba7cQJAd-0oFSsZXmpXNwj7jlJ5yJHe--GY2pcO7kPNhDKc-bgGxbXIMzdEMSUN-W6JPLzxndubZCkcOjkK9vVMpQJ8Tbj_WxxFFX3SxSuecynD1bBtDxYulrCsRsZTUmrAgJ60FGMSv3swE28-0UssK8xHMj3e8P_02a0b3t9iuSjRB0',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuB7mykjxnzJyz1m2JQZm5i49X5nUAls9eyn_pYPyP_LLKKYa7XCF0oMU96gwGQBs40FUS0X2tS-RBPekTi-zcJ9ThiSW0uvZG4AYYf0hMJXIZCcIunGxDO3-1EIuIo9OMmzE-u2Y0xPDHl3VvpnYvige-k3v1Ew5D8Qtl1n4b3MedlQHZJdntr7M-MHSOtFBSVfqnuT9eqekzOluNghKszCrsbjBDAHmzKI-YJr5mWqlqsTZQUBaEA0At69gFHjLdQgeTp2Zx0Z_Js',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF6C6C70)),
                        const SizedBox(width: 8),
                        Text(
                          '上海',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D2D2F),
                            letterSpacing: -0.15,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedBuilder(
                      animation: AuthService(),
                      builder: (context, _) {
                        final nickname = AuthService().nickname ?? '用户';
                        return Text(
                          '${_getGreeting()}，$nickname',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F1F21),
                            letterSpacing: -0.15,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '25°C，局部多云',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F1F21),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '今天穿一件轻薄外套最合适！',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6C6C70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.cloud_outlined,
                            size: 48,
                            color: StitchColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '今日推荐',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F21),
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: size.height * 0.42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (_, index) {
                        final item = _recommendations[index];
                        return SizedBox(
                          width: 220,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE6E6EA),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        color: const Color(0xFFF5F5F7),
                                        child: GridView.builder(
                                          padding: const EdgeInsets.all(8),
                                          primary: false,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                mainAxisSpacing: 8,
                                                crossAxisSpacing: 8,
                                                childAspectRatio: 1,
                                              ),
                                          itemCount: item.images.length,
                                          itemBuilder: (context, gridIndex) {
                                            final imageUrl =
                                                item.images[gridIndex];
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F1F21),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6C6C70),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1F1F21,
                                        ),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () {
                                        // 保存当前推荐的衣服组合
                                        CurrentRecommendationStore.setRecommendation(
                                          CurrentRecommendation(
                                            title: item.title,
                                            clothingImages: item.images,
                                          ),
                                        );
                                        // 跳转到AI试穿室
                                        StitchShellCoordinator.selectTab(
                                          StitchTab.fittingRoom,
                                        );
                                      },
                                      child: const Text(
                                        '立即试穿',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
              variant: BottomNavVariant.home,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _Recommendation {
  const _Recommendation({
    required this.title,
    required this.subtitle,
    required this.images,
  });

  final String title;
  final String subtitle;
  final List<String> images;
}
