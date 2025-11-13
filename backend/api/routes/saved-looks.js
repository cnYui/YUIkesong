// 保存穿搭相关接口
import { v4 as uuidv4 } from 'uuid';

export function setupSavedLooksRoutes(app, supabase, authenticateToken) {
  // 创建保存穿搭
  app.post('/saved-looks', authenticateToken, async (req, res) => {
    try {
      const { cover_image_url, clothing_image_urls = [], ai_task_id, recommendation_id } = req.body;

      if (!cover_image_url) {
        return res.status(400).json({ code: 400, message: '缺少封面图片URL' });
      }

      if (!Array.isArray(clothing_image_urls)) {
        return res.status(400).json({ code: 400, message: '衣物图片URLs必须是数组' });
      }

      const userId = req.user.id;
      const savedLookId = uuidv4();

      // 创建保存穿搭记录
      const { data: savedLook, error: savedLookError } = await supabase
        .from('saved_looks')
        .insert({
          id: savedLookId,
          user_id: userId,
          ai_task_id: ai_task_id || null,
          recommendation_id: recommendation_id || null,
          cover_image_url,
          created_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (savedLookError || !savedLook) {
        return res.status(500).json({ code: 500, message: '创建保存穿搭失败' });
      }

      // 如果有衣物图片，创建关联记录
      if (clothing_image_urls.length > 0) {
        console.log('开始保存衣物关联，衣物图片URLs:', clothing_image_urls);
        
        // 先根据图片URL获取对应的衣物ID
        const { data: wardrobeItems, error: itemsError } = await supabase
          .from('wardrobe_items')
          .select('id, image_path')
          .eq('user_id', userId)
          .in('image_path', clothing_image_urls);

        console.log('查询到的衣柜物品:', wardrobeItems, '错误:', itemsError);

        if (!itemsError && wardrobeItems && wardrobeItems.length > 0) {
          // 按照原始URL顺序创建关联记录
          const lookItems = clothing_image_urls.map((url, index) => {
            const wardrobeItem = wardrobeItems.find(item => item.image_path === url);
            if (wardrobeItem) {
              return {
                saved_look_id: savedLookId,
                wardrobe_item_id: wardrobeItem.id,
                slot: `slot_${index + 1}`
              };
            }
            return null;
          }).filter(item => item !== null);

          console.log('准备插入的关联记录:', lookItems);

          if (lookItems.length > 0) {
            const { error: insertError } = await supabase
              .from('saved_look_items')
              .insert(lookItems);
            
            if (insertError) {
              console.error('插入衣物关联记录失败:', insertError);
            } else {
              console.log('成功插入', lookItems.length, '条衣物关联记录');
            }
          }
        } else {
          console.warn('未找到匹配的衣柜物品或查询出错');
        }
      }

      res.json({ id: savedLook.id });
    } catch (error) {
      console.error('创建保存穿搭错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取保存穿搭列表
  app.get('/saved-looks', authenticateToken, async (req, res) => {
    try {
      const userId = req.user.id;
      const { page = 1, pageSize = 20 } = req.query;
      
      const pageNum = parseInt(page);
      const sizeNum = parseInt(pageSize);
      const offset = (pageNum - 1) * sizeNum;

      const { data, error, count } = await supabase
        .from('saved_looks')
        .select('id, cover_image_url, created_at', { count: 'exact' })
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .range(offset, offset + sizeNum - 1);

      if (error) {
        return res.status(500).json({ code: 500, message: '获取保存穿搭列表失败' });
      }

      // 获取每个穿搭的衣物图片
      const looksWithItems = await Promise.all(
        (data || []).map(async (look) => {
          const { data: items, error: itemsError } = await supabase
            .from('saved_look_items')
            .select(`
              wardrobe_item_id,
              slot,
              wardrobe_items!inner(image_path)
            `)
            .eq('saved_look_id', look.id)
            .order('slot');

          console.log(`获取穿搭 ${look.id} 的衣物图片:`, { items, itemsError });

          const clothingImageUrls = items ? items.map(item => {
            // 处理wardrobe_items可能是对象或数组的情况
            const imagePath = Array.isArray(item.wardrobe_items) 
              ? item.wardrobe_items[0]?.image_path 
              : item.wardrobe_items?.image_path;
            console.log(`衣物项 ${item.wardrobe_item_id} 的图片路径:`, imagePath);
            return imagePath;
          }).filter(path => path) : [];

          console.log(`穿搭 ${look.id} 最终衣物图片URLs:`, clothingImageUrls);

          return {
            ...look,
            clothing_image_urls: clothingImageUrls
          };
        })
      );

      res.json({
        list: looksWithItems,
        page: pageNum,
        pageSize: sizeNum,
        total: count || 0
      });
    } catch (error) {
      console.error('获取保存穿搭列表错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 删除保存穿搭
  app.delete('/saved-looks/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      console.log(`删除保存穿搭请求: 穿搭ID=${id}, 用户ID=${userId}`);

      // 验证保存穿搭是否存在且属于当前用户
      const { data: savedLook, error: getError } = await supabase
        .from('saved_looks')
        .select('id')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      console.log(`验证穿搭存在性: 结果=${JSON.stringify(savedLook)}, 错误=${JSON.stringify(getError)}`);

      if (getError || !savedLook) {
        console.log(`穿搭不存在或不属于该用户: ID=${id}, 用户ID=${userId}`);
        return res.status(404).json({ code: 404, message: '保存穿搭不存在' });
      }

      // 删除关联的衣物记录
      const { error: itemsDeleteError } = await supabase
        .from('saved_look_items')
        .delete()
        .eq('saved_look_id', id);

      console.log(`删除关联衣物记录: 错误=${JSON.stringify(itemsDeleteError)}`);

      // 删除保存穿搭记录
      const { error: deleteError } = await supabase
        .from('saved_looks')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);

      console.log(`删除穿搭记录: 错误=${JSON.stringify(deleteError)}`);

      if (deleteError) {
        return res.status(500).json({ code: 500, message: '删除保存穿搭失败' });
      }

      console.log(`删除成功: ID=${id}`);
      res.json({ ok: true });
    } catch (error) {
      console.error('删除保存穿搭错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 发布保存穿搭到社区
  app.post('/saved-looks/:id/publish', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // 获取保存穿搭信息
      const { data: savedLook, error: getError } = await supabase
        .from('saved_looks')
        .select(`
          *,
          saved_look_items!inner(
            wardrobe_item_id,
            slot,
            wardrobe_items!inner(image_path)
          )
        `)
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (getError || !savedLook) {
        return res.status(404).json({ code: 404, message: '保存穿搭不存在' });
      }

      // 获取用户资料
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('nickname')
        .eq('id', userId)
        .single();

      if (profileError || !profile) {
        return res.status(500).json({ code: 500, message: '获取用户资料失败' });
      }

      // 创建社区帖子
      const postId = uuidv4();
      const { data: post, error: postError } = await supabase
        .from('community_posts')
        .insert({
          id: postId,
          user_id: userId,
          cover_image_url: savedLook.cover_image_url,
          description: `${profile.nickname} 分享了一套穿搭`,
          visibility: 'public',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (postError || !post) {
        return res.status(500).json({ code: 500, message: '创建社区帖子失败' });
      }

      // 创建帖子图片记录
      const postImages = [
        {
          id: uuidv4(),
          post_id: postId,
          image_url: savedLook.cover_image_url,
          sort_order: 0
        }
      ];

      // 添加衣物图片
      if (savedLook.saved_look_items && savedLook.saved_look_items.length > 0) {
        savedLook.saved_look_items.forEach((item, index) => {
          postImages.push({
            id: uuidv4(),
            post_id: postId,
            image_url: item.wardrobe_items.image_path,
            sort_order: index + 1
          });
        });
      }

      await supabase
        .from('community_post_images')
        .insert(postImages);

      res.json({ post_id: post.id });
    } catch (error) {
      console.error('发布保存穿搭错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });
}