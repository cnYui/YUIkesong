// 自拍管理相关接口
import { v4 as uuidv4 } from 'uuid';

export function setupSelfiesRoutes(app, supabase, authenticateToken) {
  // 获取上传URL
  app.post('/selfies/upload-url', authenticateToken, async (req, res) => {
    try {
      const { filename, content_type } = req.body;

      console.log(`=== 获取上传URL请求 ===`);
      console.log(`用户ID: ${req.user.id}`);
      console.log(`文件名: ${filename}`);
      console.log(`内容类型: ${content_type}`);

      if (!filename || !content_type) {
        console.log('缺少文件名或内容类型参数');
        return res.status(400).json({ code: 400, message: '缺少文件名或内容类型' });
      }

      // 验证内容类型
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
      if (!allowedTypes.includes(content_type)) {
        console.log(`不允许的内容类型: ${content_type}`);
        return res.status(400).json({ code: 400, message: '不支持的图片格式' });
      }

      const userId = req.user.id;
      const imagePath = `${userId}/${uuidv4()}_${filename}`;
      
      console.log(`生成图片路径: ${imagePath}`);
      
      // 尝试方法1: 使用createSignedUploadUrl
      try {
        const { data, error } = await supabase
          .storage
          .from('selfies')
          .createSignedUploadUrl(imagePath, {
            contentType: content_type,
            upsert: true
          });

        if (error) {
          console.error('createSignedUploadUrl失败:', error);
          throw error;
        }

        console.log('createSignedUploadUrl响应数据:', JSON.stringify(data, null, 2));
        
        if (!data || !data.signedUrl) {
          console.error('上传URL数据缺失:', data);
          throw new Error('上传URL生成失败');
        }

        console.log(`上传URL创建成功: ${data.signedUrl}`);
        console.log(`=== 获取上传URL完成 ===`);

        return res.json({
          upload_url: data.signedUrl,
          image_path: imagePath,
          token: data.token || null
        });
      } catch (method1Error) {
        console.error('方法1失败，尝试方法2:', method1Error);
        
        // 方法2: 使用createSignedUrl（下载URL）但用于上传
        try {
          const { data: signedData, error: signedError } = await supabase
            .storage
            .from('selfies')
            .createSignedUrl(imagePath, 3600); // 1小时有效期

          if (signedError) {
            console.error('createSignedUrl也失败:', signedError);
            throw signedError;
          }

          // 构建上传URL（替换下载URL中的参数）
          let uploadUrl = signedData.signedUrl;
          if (uploadUrl.includes('/object/sign/')) {
            uploadUrl = uploadUrl.replace('/object/sign/', '/object/upload/sign/');
          }
          
          console.log(`备用方法上传URL: ${uploadUrl}`);
          
          return res.json({
            upload_url: uploadUrl,
            image_path: imagePath,
            token: null
          });
        } catch (method2Error) {
          console.error('方法2也失败:', method2Error);
          
          // 方法3: 直接返回一个可以手动构建上传URL的格式
          const baseUrl = process.env.SUPABASE_URL.replace('.supabase.co', '');
          const directUploadUrl = `${baseUrl}.supabase.co/storage/v1/object/upload/sign/selfies/${encodeURIComponent(imagePath)}`;
          
          console.log(`直接构建上传URL: ${directUploadUrl}`);
          
          return res.json({
            upload_url: directUploadUrl,
            image_path: imagePath,
            token: null,
            manual_upload: true
          });
        }
      }
    } catch (error) {
      console.error('获取上传URL错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 创建自拍记录
  app.post('/selfies', authenticateToken, async (req, res) => {
    try {
      const { image_path, is_default = false } = req.body;
      const userId = req.user.id;

      console.log(`=== 用户添加自拍操作 ===`);
      console.log(`用户ID: ${userId}`);
      console.log(`图片路径: ${image_path}`);
      console.log(`是否设为默认: ${is_default}`);

      if (!image_path) {
        console.log('缺少图片路径参数');
        return res.status(400).json({ code: 400, message: '缺少图片路径' });
      }

      // 验证图片路径格式
      if (!image_path.startsWith(`${userId}/`)) {
        console.log(`图片路径不属于当前用户: ${image_path}`);
        return res.status(400).json({ code: 400, message: '图片路径无效' });
      }

      // 如果设置为默认，先取消其他默认自拍
      if (is_default) {
        console.log('取消其他默认自拍...');
        const { error: updateError } = await supabase
          .from('selfies')
          .update({ is_default: false })
          .eq('user_id', userId)
          .eq('is_default', true);

        if (updateError) {
          console.error('取消其他默认自拍失败:', updateError);
        } else {
          console.log('已取消其他默认自拍');
        }
      }

      const selfieId = uuidv4();
      console.log(`生成自拍ID: ${selfieId}`);

      console.log('开始创建自拍记录...');
      const { data, error } = await supabase
        .from('selfies')
        .insert({
          id: selfieId,
          user_id: userId,
          image_path,
          is_default,
          created_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (error || !data) {
        console.error('创建自拍记录失败:', error);
        return res.status(500).json({ code: 500, message: '创建自拍记录失败' });
      }

      console.log(`=== 自拍添加操作完成 ===`);
      res.json({ 
        id: data.id,
        message: '自拍已成功添加',
        is_default: is_default
      });
    } catch (error) {
      console.error('创建自拍记录错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取自拍列表
  app.get('/selfies', authenticateToken, async (req, res) => {
    try {
      const userId = req.user.id;

      const { data, error } = await supabase
        .from('selfies')
        .select('id, image_path, is_default, created_at')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) {
        return res.status(500).json({ code: 500, message: '获取自拍列表失败' });
      }

      const selfiesWithUrls = await Promise.all(
        (data || []).map(async (selfie) => {
          try {
            // 使用getPublicUrl生成公开URL（因为存储桶现在是公开的）
            const { data: publicData } = supabase
              .storage
              .from('selfies')
              .getPublicUrl(selfie.image_path);

            return {
              ...selfie,
              image_url: publicData?.publicUrl || selfie.image_path
            };
          } catch (urlError) {
            console.error(`生成图片URL失败: ${selfie.image_path}`, urlError);
            return {
              ...selfie,
              image_url: selfie.image_path
            };
          }
        })
      );

      res.json({ list: selfiesWithUrls });
    } catch (error) {
      console.error('获取自拍列表错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 删除自拍
  app.delete('/selfies/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      console.log(`=== 用户删除自拍操作 ===`);
      console.log(`用户ID: ${userId}`);
      console.log(`自拍ID: ${id}`);

      // 先获取自拍信息
      const { data: selfie, error: getError } = await supabase
        .from('selfies')
        .select('image_path, is_default, created_at')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (getError || !selfie) {
        console.log(`自拍不存在或无权删除: ${id}`);
        return res.status(404).json({ code: 404, message: '自拍不存在' });
      }

      console.log(`找到自拍信息: 图片路径=${selfie.image_path}, 是否默认=${selfie.is_default}`);

      // 删除存储中的图片
      console.log(`开始删除存储中的图片: ${selfie.image_path}`);
      const { error: storageError } = await supabase
        .storage
        .from('selfies')
        .remove([selfie.image_path]);

      if (storageError) {
        console.error('删除存储图片失败:', storageError);
      } else {
        console.log('存储图片删除成功');
      }

      // 删除数据库记录
      console.log('开始删除数据库记录...');
      const { error: deleteError } = await supabase
        .from('selfies')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);

      if (deleteError) {
        console.error('删除自拍记录失败:', deleteError);
        return res.status(500).json({ code: 500, message: '删除自拍记录失败' });
      }

      console.log('数据库记录删除成功');

      // 如果是默认自拍，设置最新的自拍为默认
      if (selfie.is_default) {
        console.log('删除的是默认自拍，需要设置新的默认自拍');
        const { data: latestSelfie } = await supabase
          .from('selfies')
          .select('id')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(1)
          .single();

        if (latestSelfie) {
          console.log(`设置新的默认自拍: ${latestSelfie.id}`);
          await supabase
            .from('selfies')
            .update({ is_default: true })
            .eq('id', latestSelfie.id);
        } else {
          console.log('用户没有其他自拍，无需设置默认');
        }
      }

      console.log(`=== 自拍删除操作完成 ===`);
      res.json({ 
        ok: true, 
        message: '自拍已成功删除',
        deleted_selfie_id: id,
        was_default: selfie.is_default
      });
    } catch (error) {
      console.error('删除自拍错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 设置默认自拍
  app.post('/selfies/:id/default', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // 验证自拍是否存在且属于当前用户
      const { data: selfie, error: getError } = await supabase
        .from('selfies')
        .select('id')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (getError || !selfie) {
        return res.status(404).json({ code: 404, message: '自拍不存在' });
      }

      // 先取消所有默认自拍
      await supabase
        .from('selfies')
        .update({ is_default: false })
        .eq('user_id', userId);

      // 设置新的默认自拍
      const { error: updateError } = await supabase
        .from('selfies')
        .update({ is_default: true })
        .eq('id', id);

      if (updateError) {
        return res.status(500).json({ code: 500, message: '设置默认自拍失败' });
      }

      res.json({ ok: true });
    } catch (error) {
      console.error('设置默认自拍错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });
}
