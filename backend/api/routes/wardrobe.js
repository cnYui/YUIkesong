import { createClient } from '@supabase/supabase-js';
import { v4 as uuidv4 } from 'uuid';

export function setupWardrobeRoutes(app, supabase, authenticateToken) {
  // 获取衣物列表
  app.get('/wardrobe', authenticateToken, async (req, res) => {
    try {
      const { category } = req.query;
      console.log('衣柜列表请求: user=', req.user.id, 'category=', category || '全部');
      const t0 = Date.now();
      
      let query = supabase
        .from('wardrobe_items')
        .select('id, image_path, created_at, category_id, metadata')
        .eq('user_id', req.user.id)
        .order('created_at', { ascending: false });

      if (category && category !== '全部') {
        const { data: cat } = await supabase
          .from('wardrobe_categories')
          .select('id')
          .eq('name', category)
          .maybeSingle();
        if (!cat) {
          return res.json({ list: [] });
        }
        query = query.eq('category_id', cat.id);
      }

      const { data, error } = await query;

      if (error) {
        console.error('获取衣物列表失败:', error);
        return res.status(500).json({ code: 500, message: '获取衣物列表失败' });
      }

      const { data: cats } = await supabase
        .from('wardrobe_categories')
        .select('id, name');
      const catMap = Object.fromEntries((cats || []).map(c => [c.id, c.name]));

      const items = (data || []).map((item) => {
        const { data: publicData } = supabase.storage
          .from('wardrobe')
          .getPublicUrl(item.image_path);
        return {
          id: item.id,
          name: item.metadata?.name ?? '未命名',
          category: catMap[item.category_id] ?? null,
          image_path: item.image_path,
          image_url: publicData?.publicUrl || item.image_path,
          created_at: item.created_at
        };
      });

      console.log('衣柜列表返回: count=', items.length, 'elapsed=', Date.now() - t0, 'ms');
      res.json({ list: items });
    } catch (error) {
      console.error('获取衣物列表错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取衣物详情
  app.get('/wardrobe/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      
      const { data, error } = await supabase
        .from('wardrobe_items')
        .select('id, image_path, created_at, category_id, metadata')
        .eq('id', id)
        .eq('user_id', req.user.id)
        .single();

      if (error || !data) {
        return res.status(404).json({ code: 404, message: '衣物不存在' });
      }

      const { data: cat } = await supabase
        .from('wardrobe_categories')
        .select('name')
        .eq('id', data.category_id)
        .maybeSingle();

      const { data: publicDetail } = supabase.storage
        .from('wardrobe')
        .getPublicUrl(data.image_path);

      res.json({
        id: data.id,
        name: data.metadata?.name ?? '未命名',
        category: cat?.name ?? null,
        image_path: data.image_path,
        image_url: publicDetail?.publicUrl || data.image_path,
        created_at: data.created_at
      });
    } catch (error) {
      console.error('获取衣物详情错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取上传URL
  app.post('/wardrobe/upload-url', authenticateToken, async (req, res) => {
    try {
      const { filename, content_type } = req.body;
      
      if (!filename || !content_type) {
        return res.status(400).json({ code: 400, message: '缺少文件名或内容类型' });
      }

      const userId = req.user.id;
      const timestamp = Date.now();
      const safeFilename = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
      const imagePath = `wardrobe/${userId}/${timestamp}_${safeFilename}`;

      console.log('=== 衣物上传调试信息 ===');
      console.log('用户ID:', userId);
      console.log('文件名:', filename);
      console.log('安全文件名:', safeFilename);
      console.log('存储路径:', imagePath);
      console.log('内容类型:', content_type);
      console.log('========================');

      let data;
      let error;
      let attempt = 0;
      const maxAttempts = 3;
      while (attempt < maxAttempts) {
        attempt++;
        console.log(`创建上传URL尝试 #${attempt}`);
        const resp = await supabase.storage
          .from('wardrobe')
          .createSignedUploadUrl(imagePath, { contentType: content_type, upsert: true });
        data = resp.data;
        error = resp.error;
        if (!error && data?.signedUrl) break;
        if (attempt < maxAttempts) {
          await new Promise(r => setTimeout(r, 1000 * attempt));
        }
      }

      if (error) {
        console.error('创建上传URL失败(重试后):', error);
        try {
          const { data: signedData, error: signedError } = await supabase
            .storage
            .from('wardrobe')
            .createSignedUrl(imagePath, 3600);
          if (!signedError && signedData?.signedUrl) {
            let uploadUrl = signedData.signedUrl;
            if (uploadUrl.includes('/object/sign/')) {
              uploadUrl = uploadUrl.replace('/object/sign/', '/object/upload/sign/');
            }
            const { data: publicData } = supabase.storage
              .from('wardrobe')
              .getPublicUrl(imagePath);
            return res.json({
              upload_url: uploadUrl,
              image_path: imagePath,
              image_url: publicData?.publicUrl || imagePath,
              manual_upload: true
            });
          }
        } catch (fallbackErr) {
          console.error('备用上传URL生成失败:', fallbackErr);
        }
        const baseUrl = process.env.SUPABASE_URL?.replace('.supabase.co', '') || 'https://tbjyhqcazhgcmtbdgwpg';
        const directUploadUrl = `${baseUrl}.supabase.co/storage/v1/object/upload/sign/wardrobe/${encodeURIComponent(imagePath)}`;
        const { data: publicData } = supabase.storage
          .from('wardrobe')
          .getPublicUrl(imagePath);
        return res.json({
          upload_url: directUploadUrl,
          image_path: imagePath,
          image_url: publicData?.publicUrl || imagePath,
          manual_upload: true
        });
      }

      const { data: publicData } = supabase.storage
        .from('wardrobe')
        .getPublicUrl(imagePath);

      const imageUrl = publicData?.publicUrl || imagePath;

      console.log('上传URL创建成功');
      res.json({
        upload_url: data.signedUrl,
        image_path: imagePath,
        image_url: imageUrl
      });
    } catch (error) {
      console.error('创建上传URL错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 添加衣物
  app.post('/wardrobe', authenticateToken, async (req, res) => {
    try {
      const { name, category, image_path, is_default = false } = req.body;
      
      if (!name || !category || !image_path) {
        return res.status(400).json({ code: 400, message: '缺少必需参数' });
      }

      const validCategories = ['上装', '下装', '连衣裙', '外套', '鞋履', '配饰'];
      if (!validCategories.includes(category)) {
        return res.status(400).json({ code: 400, message: '无效的衣物类别' });
      }

      console.log('=== 添加衣物调试信息 ===');
      console.log('用户ID:', req.user.id);
      console.log('衣物名称:', name);
      console.log('衣物类别:', category);
      console.log('图片路径:', image_path);
      console.log('是否默认:', is_default);
      console.log('========================');

      // 如果设置为默认，先取消其他默认衣物
      if (is_default) {
        const { error: updateError } = await supabase
          .from('wardrobe_items')
          .update({ is_default: false })
          .eq('user_id', req.user.id)
          .eq('is_default', true);

        if (updateError) {
          console.error('取消其他默认衣物失败:', updateError);
        }
      }

      let categoryId = null;
      if (category) {
        const { data: cat, error: catErr } = await supabase
          .from('wardrobe_categories')
          .select('id')
          .eq('name', category)
          .maybeSingle();
        if (catErr) {
          console.error('类别查询失败:', catErr);
        }
        if (!cat) {
          const { data: newCat, error: newCatErr } = await supabase
            .from('wardrobe_categories')
            .insert({ name: category })
            .select('id')
            .single();
          if (newCatErr) {
            console.error('类别创建失败:', newCatErr);
          } else {
            categoryId = newCat.id;
          }
        } else {
          categoryId = cat.id;
        }
      }

      const insertPayload = {
        id: uuidv4(),
        user_id: req.user.id,
        category_id: categoryId,
        image_path,
        metadata: { name }
      };
      console.log('准备插入衣物记录: id=', insertPayload.id, 'category_id=', categoryId);

      const { error: insertError } = await supabase
        .from('wardrobe_items')
        .insert(insertPayload);

      if (insertError) {
        console.error('添加衣物失败:', insertError);
        return res.status(500).json({ code: 500, message: '添加衣物失败' });
      }

      const { data: inserted, error: fetchInsertedError } = await supabase
        .from('wardrobe_items')
        .select('id, image_path, created_at, category_id, metadata')
        .eq('id', insertPayload.id)
        .single();

      if (fetchInsertedError || !inserted) {
        console.error('添加衣物失败:', fetchInsertedError);
        return res.status(500).json({ code: 500, message: '添加衣物失败' });
      }

      const { data: publicData } = supabase.storage
        .from('wardrobe')
        .getPublicUrl(image_path);

      const { data: cat } = await supabase
        .from('wardrobe_categories')
        .select('name')
        .eq('id', inserted.category_id)
        .maybeSingle();

      console.log('衣物创建成功: id=', inserted.id);
      res.json({
        id: inserted.id,
        name: inserted.metadata?.name ?? '未命名',
        category: cat?.name ?? null,
        image_path: inserted.image_path,
        image_url: publicData?.publicUrl || inserted.image_path,
        created_at: inserted.created_at
      });
    } catch (error) {
      console.error('添加衣物错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 更新衣物
  app.put('/wardrobe/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { name, category, is_default } = req.body;
      
      const updates = {};
      if (name !== undefined) updates.name = name;
      if (category !== undefined) updates.category = category;

      if (Object.keys(updates).length === 0) {
        return res.status(400).json({ code: 400, message: '没有有效的更新字段' });
      }

      

      if (updates.category !== undefined) {
        const { data: cat2 } = await supabase
          .from('wardrobe_categories')
          .select('id')
          .eq('name', updates.category)
          .maybeSingle();
        let catId2 = cat2?.id || null;
        if (!catId2) {
          const { data: newCat2 } = await supabase
            .from('wardrobe_categories')
            .insert({ name: updates.category })
            .select('id')
            .single();
          catId2 = newCat2.id;
        }
        updates.category_id = catId2;
        delete updates.category;
      }

      if (updates.name !== undefined) {
        updates.metadata = { name: updates.name };
        delete updates.name;
      }

      const { data, error } = await supabase
        .from('wardrobe_items')
        .update(updates)
        .eq('id', id)
        .eq('user_id', req.user.id)
        .select('id, image_path, created_at, category_id, metadata')
        .single();

      if (error || !data) {
        return res.status(404).json({ code: 404, message: '衣物不存在或更新失败' });
      }

      const { data: publicUpd } = supabase.storage
        .from('wardrobe')
        .getPublicUrl(data.image_path);

      const { data: catUpd } = await supabase
        .from('wardrobe_categories')
        .select('name')
        .eq('id', data.category_id)
        .maybeSingle();

      res.json({
        id: data.id,
        name: data.metadata?.name ?? '未命名',
        category: catUpd?.name ?? null,
        image_path: data.image_path,
        image_url: publicUpd?.publicUrl || data.image_path,
        created_at: data.created_at
      });
    } catch (error) {
      console.error('更新衣物错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 删除衣物
  app.delete('/wardrobe/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      
      console.log('=== 删除衣物调试信息 ===');
      console.log('用户ID:', req.user.id);
      console.log('衣物ID:', id);
      console.log('删除时间:', new Date().toISOString());
      console.log('========================');

      // 先获取衣物信息以删除图片文件
      const { data: clothing, error: fetchError } = await supabase
        .from('wardrobe_items')
        .select('image_path')
        .eq('id', id)
        .eq('user_id', req.user.id)
        .single();

      if (fetchError || !clothing) {
        return res.status(404).json({ code: 404, message: '衣物不存在' });
      }

      // 删除数据库记录
      const { error: deleteError } = await supabase
        .from('wardrobe_items')
        .delete()
        .eq('id', id)
        .eq('user_id', req.user.id);

      if (deleteError) {
        console.error('删除衣物失败:', deleteError);
        return res.status(500).json({ code: 500, message: '删除衣物失败' });
      }

      // 尝试删除存储中的图片文件（可选，失败不影响主要功能）
      try {
        const { error: storageError } = await supabase.storage
          .from('wardrobe')
          .remove([clothing.image_path]);

        if (storageError) {
          console.warn('删除存储文件失败:', storageError);
        } else {
          console.log('存储文件删除成功:', clothing.image_path);
        }
      } catch (storageError) {
        console.warn('删除存储文件异常:', storageError);
      }

      res.json({ message: '衣物删除成功' });
    } catch (error) {
      console.error('删除衣物错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 设置默认衣物
  app.post('/wardrobe/:id/default', authenticateToken, async (req, res) => {
    res.status(400).json({ code: 400, message: '当前模型不支持设置默认衣物' });
  });
}
