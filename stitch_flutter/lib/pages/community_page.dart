import 'package:flutter/material.dart';

import '../models/stitch_tab.dart';
import '../theme/app_theme.dart';
import '../widgets/stitch_bottom_nav.dart';
import 'post_detail_page.dart';
import '../state/community_posts_store.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final StitchTab currentTab;
  final ValueChanged<StitchTab> onTabSelected;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedTab = 0;

  static const _posts = [
    [
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAhH1i_cqp2K1cjsRzfwm8AQSQNQXpG6PZULQdnKFI5aJYffJ15-mfQ4I6MKBOW8G8SgWi36PoiQJGMXtLSBllSSvtNfpRbsu1hgPeBurOMU-daP3BPwClC9o9x3OKvqM9P9W0CfFhDWtPfhBwcyqfnOi41txncnv4bwSu5MxOW3sVFkg8rnsRp6PlQHXDTacdgGk_0TxsqA0GLk7xgzzJIGK8ciMDb8znnTalGtZDxLMQta8SKUInzsgAhk6cl18jjMxkRqBrvjKY',
        ],
        username: '时尚小魔女',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD9CmtT00d2Vc4fFrVYdY7SwOdAtTkG41fuZtpPjrnnDspmz0Ad7tBHw-8JoPkY8ZmXcNk1ee77qXhi42UrsZoWcNQkBzCCs1TUGDcBnZp-gwGC73G5nRsFzF9unqI4sPHuttmDAOwn7ex1Z_YYYdhwhwFgu9ZwNMZYScVx_srI5KXLcRpFrawZDbv_P-9cYQwaWC72Yl3EnIRjfrh60Iiupleq8gpVbGhM1CefWgvKWiTjqEVE28Kv086m1TgCXwHxPkAvittYul8',
        aspectRatio: 3 / 4,
      ),
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAnUq0jVj_uETDCvDeGS5SPX9sKB4AWAsv9sH0diKNA0BVnz4RQ2glR89mdYCFpaqH4KwiqquTRkJzjS-e2Hg6xIWZCedG3JUhrPod9oIUWlgDQsDwH0I2HUhoqPMXGB6-wfbP2KxifUqYpcSHURsrsNA-gjy_q-7isZFUThoPHJNHQ9brpW9huLHy5-eTTmGBBch7ETPSXtSFM0P240__qvnOUIN13D9dxsBWqiLyd5RoCrZbUAWMyGB0Gw_yEii2DhvrlbDOzuaU',
        ],
        username: '色彩玩家',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAS9R7wiDb_fP0STKTIlwXjFUXwUxhHehqoAlKi2-iwXZX40poqJHlN1Yt7tguQ7-_G4T8ie1ZHhPJhjrOZTFj5w--hwVT7CzlgfMDfpNEu71zx5qg6CgTeOdze37WusPZPzGpbwbIRR2NGg1MkhOhGP0YzPZMVLQZ8wqYVpSVTZJsJKsUfAieUsVkdZJ0X0dW9TMt5eGBQglE1-U8IOcb9SBOOuKyAMxL4KGeoaINM_U_Lz6tggp1bDVXsy74nTmCViIe8cFc6-8k',
        aspectRatio: 3 / 4,
      ),
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDErJxV7kqabTxiWfOEcUUCpNmwRIY55Fx4lETTPATJPCaP4JRwZqIdjEP9nDHvb7hDUZHkAoOnT2VqZ1XNZIEA1RISjDVuwYgWZtqtYZxzl9ct2ELggbNi7BEMPhGx5hQfQ1aQpiz5PzPQUlGLDF-tXr_8Tvyw2lHllEQRmeN2PADubd99nQY9Ytwo-XHPdaJzMtMbargkmuyKt6kDoN2XKNIKyqvXszkap0AP5nfl10xO-FYxhv1lQprOgsH-RUy7C26mznaCeig',
        ],
        username: '都市丽人',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCwQ3c8V4xXZ2EhlVsL3pOpEDEHF-kCrVBhVwdIa3naGDkU4iQEGpkMYeJSV2woaa7xMrnhTIcQlhVtGRKYSafqylHqD6uo9yNGWZgzOsImJXZ5KLkkUd9Vlf1eK9hVoMYrbSu8fBAW8hX_5KYxTyFirWONVbAqOAGXcfKqFReHAcM_mrRb4kcABEZTGLapCQ3_W4-sve0jrqPfMT2mC2ExA2iAROghm6Te80p80MonlP6ICww6axgC-2HE3l-6zcJ9PBg89lKPg_Y',
        aspectRatio: 4 / 5,
      ),
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAwA9ZyzjWerX_UTBC7zMD_GdryiWDgOT8sLasmfq63LmF6mRB1OrkDDxYlop8wUZovIvzLyg9tzL6qwkWr7puG3Iv9YUic_aHJnwQzoUCCZZ5uAmk9_5Vac-m10A5TQbnKGAPyT-OC1kEh5VwggjjKNuf_g4Eri0cy8rPkCiukf-zn1s-RG5gnzH6OEJTaX64WeGWNIdIS4nI5RjnKILCYsoSwcgPAO82JU25aHSS7jVX3JZ67K7jnfaeZi6SrTDnaCbSwGmeyCBw',
        ],
        username: '复古风尚',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCwQ3c8V4xXZ2EhlVsL3pOpEDEHF-kCrVBhVwdIa3naGDkU4iQEGpkMYeJSV2woaa7xMrnhTIcQlhVtGRKYSafqylHqD6uo9yNGWZgzOsImJXZ5KLkkUd9Vlf1eK9hVoMYrbSu8fBAW8hX_5KYxTyFirWONVbAqOAGXcfKqFReHAcM_mrRb4kcABEZTGLapCQ3_W4-sve0jrqPfMT2mC2ExA2iAROghm6Te80p80MonlP6ICww6axgC-2HE3l-6zcJ9PBg89lKPg_Y',
        aspectRatio: 3 / 4,
      ),
    ],
    [
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBCl4hgUC3P5KV5VyBDbwMJ3fh0W075kGbuc0SzoYYTtcPlL3SDdMKI-seFKxla_CEkqrle9CBnqifsTwNVHEUF42GjDecCwL9p2ZZb2TgdDFrZwc6-dfQxylFWOP_my1WC6yTLWFrcZJq8BBlS-3az-Z7R5njx9Bd_ea8v_UYZTxZVXz_3VFMtAOt2sqTGtS_v77T_voCUlTKMNaXb7asD6Lrpp9P8Nf8H7q7qWhNST2KAIZVsBwFppWXLgwJd1sFlBuh0XU8tiEs',
        ],
        username: '潮流先锋',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAS9R7wiDb_fP0STKTIlwXjFUXwUxhHehqoAlKi2-iwXZX40poqJHlN1Yt7tguQ7-_G4T8ie1ZHhPJhjrOZTFj5w--hwVT7CzlgfMDfpNEu71zx5qg6CgTeOdze37WusPZPzGpbwbIRR2NGg1MkhOhGP0YzPZMVLQZ8wqYVpSVTZJsJKsUfAieUsVkdZJ0X0dW9TMt5eGBQglE1-U8IOcb9SBOOuKyAMxL4KGeoaINM_U_Lz6tggp1bDVXsy74nTmCViIe8cFc6-8k',
        aspectRatio: 3 / 4,
      ),
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC_sQ1-FlO_vICFTVYUs54CpGDU1nDfkb5mdEifhqy5beqYjny9UeQOtF7jUVZKTokDsJ_gxmWNtEHqc_TWJM2kMl6Sc45A3bf86FL7-7gQos45DbySblQOhH8sZiMUXk6qKHMXeCU-Iuy0EKD2OOmZeJnu6WkpqJDMYnreAA-AAKUIiYifapvdn2JCMXB_Wpfv4Z3hE3PUp7c7ZRtBIcLYil7vKNvFd8JRL3tUUX2n1wWkQDtrSZ-UFUxBUFsZsJT46vcZn9hOdXQ',
        ],
        username: '职场穿搭达人',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAS9R7wiDb_fP0STKTIlwXjFUXwUxhHehqoAlKi2-iwXZX40poqJHlN1Yt7tguQ7-_G4T8ie1ZHhPJhjrOZTFj5w--hwVT7CzlgfMDfpNEu71zx5qg6CgTeOdze37WusPZPzGpbwbIRR2NGg1MkhOhGP0YzPZMVLQZ8wqYVpSVTZJsJKsUfAieUsVkdZJ0X0dW9TMt5eGBQglE1-U8IOcb9SBOOuKyAMxL4KGeoaINM_U_Lz6tggp1bDVXsy74nTmCViIe8cFc6-8k',
        aspectRatio: 3 / 4,
      ),
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBefroqPvGL_zkISPg8xHdS2ki1GT1v8pjmuM02ZONT4EFqBbb4YjvoASldXsNViOAwylW4YvYTmkuPPC6KM0vC4doMNr4kq0nI3W6LvRy7eJ5rVStl12gz7GtIh7IQA1tGXWDCmPS4h4GDSPa9esfHB3WmSoprvcLLXjzVbVWfgeKlSJiFXlTELlnirAMm5Mc31D-87OIgl5dq7SlSlwk1aMMn85ipAQ1Q1usBzOUBHl3NhJcXXOACTjzd-_xG-U0EMZ_QnTRREXY',
        ],
        username: '运动女孩',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCwQ3c8V4xXZ2EhlVsL3pOpEDEHF-kCrVBhVwdIa3naGDkU4iQEGpkMYeJSV2woaa7xMrnhTIcQlhVtGRKYSafqylHqD6uo9yNGWZgzOsImJXZ5KLkkUd9Vlf1eK9hVoMYrbSu8fBAW8hX_5KYxTyFirWONVbAqOAGXcfKqFReHAcM_mrRb4kcABEZTGLapCQ3_W4-sve0jrqPfMT2mC2ExA2iAROghm6Te80p80MonlP6ICww6axgC-2HE3l-6zcJ9PBg89lKPg_Y',
        aspectRatio: 4 / 5,
      ),
      _Post(
        images: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDd1H9yUpp57egwBhxNsWvIby8uF1FQLyrjRjk74W4WZnqN5p2Sp4ZwG_31xRlx-QQCMu5VoSjUCfW_6Xq66B03Tp7B360jL1e1pD88pB41uOmNXTA3DERa2WD45jNMdmUYiR2_v69GaL6Yx1pCWfaGaBYw0gaXzngoOK8IYGG5ZTMLlCETTqFB09A6phPX0MngcOETM7lLL2zsmPMQxXfFm9uI9QUvX3TSJP_zOqMuah07KhfIRAvStoiSJKMfIH2Uh8Alf9R2xFc',
        ],
        username: '极简主义者',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCwQ3c8V4xXZ2EhlVsL3pOpEDEHF-kCrVBhVwdIa3naGDkU4iQEGpkMYeJSV2woaa7xMrnhTIcQlhVtGRKYSafqylHqD6uo9yNGWZgzOsImJXZ5KLkkUd9Vlf1eK9hVoMYrbSu8fBAW8hX_5KYxTyFirWONVbAqOAGXcfKqFReHAcM_mrRb4kcABEZTGLapCQ3_W4-sve0jrqPfMT2mC2ExA2iAROghm6Te80p80MonlP6ICww6axgC-2HE3l-6zcJ9PBg89lKPg_Y',
        aspectRatio: 3 / 4,
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          '社区',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: StitchColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: StitchColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 0
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '推荐',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 0
                                  ? Colors.black
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTab == 1
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '关注',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 1
                                  ? Colors.black
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder<List<CommunityPostData>>(
                          valueListenable: CommunityPostsStore.listenable,
                          builder: (context, dynamicPosts, _) {
                            return Column(
                              children: [
                                ...dynamicPosts.map((p) => _PostCard(
                                      post: _Post(
                                        images: p.images,
                                        username: p.username,
                                        avatar: p.avatar,
                                        aspectRatio: 3 / 4,
                                      ),
                                    )),
                                ..._posts[0].map((post) => _PostCard(post: post)),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.1,
                          ),
                          child: Column(
                            children: _posts[1]
                                .map((post) => _PostCard(post: post))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StitchBottomNav(
              currentTab: widget.currentTab,
              onTabSelected: widget.onTabSelected,
              variant: BottomNavVariant.community,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final _Post post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(
                images: post.images,
                username: post.username,
                avatar: post.avatar,
              ),
              ),
            );
          },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: post.aspectRatio,
                child: Image.network(post.images.first, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(post.avatar),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.username,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Post {
  const _Post({
    required this.images,
    required this.username,
    required this.avatar,
    required this.aspectRatio,
  });

  final List<String> images;
  final String username;
  final String avatar;
  final double aspectRatio;
}
