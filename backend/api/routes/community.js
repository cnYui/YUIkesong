// 社区相关接口
import { v4 as uuidv4 } from 'uuid';

export function setupCommunityRoutes(app, supabase, authenticateToken) {
  // 创建社区帖子
  app.post('/community/posts', authenticateToken, async (req, res) => {
    try {
      const { images = [], description, visibility = 'public' } = req.body;

      if (!images || !Array.isArray(images) || images.length === 0) {
        return res.status(400).json({ code: 400, message: '至少需要一张图片' });
      }

      if (!['public', 'private'].includes(visibility)) {
        return res.status(400).json({ code: 400, message: '无效的可见性设置' });
      }

      const userId = req.user.id;
      const postId = uuidv4();

      // 创建帖子
      const { data: post, error: postError } = await supabase
        .from('community_posts')
        .insert({
          id: postId,
          user_id: userId,
          cover_image_url: images[0], // 第一张图片作为封面
          description: description || null,
          visibility,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (postError || !post) {
        return res.status(500).json({ code: 500, message: '创建帖子失败' });
      }

      // 创建帖子图片记录
      const postImages = images.map((imageUrl, index) => ({
        id: uuidv4(),
        post_id: postId,
        image_url: imageUrl,
        sort_order: index
      }));

      const { error: imagesError } = await supabase
        .from('community_post_images')
        .insert(postImages);

      if (imagesError) {
        // 如果图片创建失败，删除已创建的帖子
        await supabase
          .from('community_posts')
          .delete()
          .eq('id', postId);
        
        return res.status(500).json({ code: 500, message: '创建帖子图片失败' });
      }

      res.json({ id: post.id });
    } catch (error) {
      console.error('创建社区帖子错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取社区帖子列表
  app.get('/community/posts', authenticateToken, async (req, res) => {
    try {
      const { page = 1, pageSize = 6 } = req.query;
      
      const pageNum = parseInt(page);
      const sizeNum = parseInt(pageSize);
      const offset = (pageNum - 1) * sizeNum;

      // 获取公开的帖子
      const { data: posts, error, count } = await supabase
        .from('community_posts')
        .select(`
          *,
          profiles!inner(nickname, avatar_url)
        `, { count: 'exact' })
        .eq('visibility', 'public')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .range(offset, offset + sizeNum - 1);

      if (error) {
        return res.status(500).json({ code: 500, message: '获取帖子列表失败' });
      }

      // 格式化返回数据
      const formattedPosts = (posts || []).map(post => ({
        id: post.id,
        cover_image_url: post.cover_image_url,
        username: post.profiles.nickname,
        avatar: post.profiles.avatar_url,
        created_at: post.created_at
      }));

      res.json({
        list: formattedPosts,
        page: pageNum,
        pageSize: sizeNum,
        total: count || 0
      });
    } catch (error) {
      console.error('获取社区帖子列表错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取社区帖子详情
  app.get('/community/posts/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // 获取帖子详情
      const { data: post, error: postError } = await supabase
        .from('community_posts')
        .select(`
          *,
          profiles!inner(nickname, avatar_url)
        `)
        .eq('id', id)
        .or(`visibility.eq.public,user_id.eq.${userId}`)
        .is('deleted_at', null)
        .single();

      if (postError || !post) {
        return res.status(404).json({ code: 404, message: '帖子不存在' });
      }

      // 获取帖子图片
      const { data: images, error: imagesError } = await supabase
        .from('community_post_images')
        .select('image_url, sort_order')
        .eq('post_id', id)
        .order('sort_order', { ascending: true });

      if (imagesError) {
        return res.status(500).json({ code: 500, message: '获取帖子图片失败' });
      }

      res.json({
        id: post.id,
        images: images || [],
        username: post.profiles.nickname,
        avatar: post.profiles.avatar_url,
        description: post.description,
        created_at: post.created_at
      });
    } catch (error) {
      console.error('获取社区帖子详情错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 点赞/取消点赞
  app.post('/community/posts/:id/likes', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // 验证帖子是否存在且公开
      const { data: post, error: postError } = await supabase
        .from('community_posts')
        .select('id')
        .eq('id', id)
        .eq('visibility', 'public')
        .is('deleted_at', null)
        .single();

      if (postError || !post) {
        return res.status(404).json({ code: 404, message: '帖子不存在' });
      }

      // 检查是否已经点赞
      const { data: existingLike } = await supabase
        .from('community_likes')
        .select('post_id')
        .eq('post_id', id)
        .eq('user_id', userId)
        .single();

      if (existingLike) {
        // 取消点赞
        const { error: deleteError } = await supabase
          .from('community_likes')
          .delete()
          .eq('post_id', id)
          .eq('user_id', userId);

        if (deleteError) {
          return res.status(500).json({ code: 500, message: '取消点赞失败' });
        }
      } else {
        // 点赞
        const { error: insertError } = await supabase
          .from('community_likes')
          .insert({
            post_id: id,
            user_id: userId,
            created_at: new Date().toISOString()
          });

        if (insertError) {
          return res.status(500).json({ code: 500, message: '点赞失败' });
        }
      }

      // 获取最新点赞数
      const { count } = await supabase
        .from('community_likes')
        .select('*', { count: 'exact', head: true })
        .eq('post_id', id);

      res.json({ likes: count || 0 });
    } catch (error) {
      console.error('点赞操作错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取评论列表
  app.get('/community/posts/:id/comments', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { page = 1, pageSize = 20 } = req.query;
      
      const pageNum = parseInt(page);
      const sizeNum = parseInt(pageSize);
      const offset = (pageNum - 1) * sizeNum;

      // 验证帖子是否存在
      const { data: post, error: postError } = await supabase
        .from('community_posts')
        .select('id, visibility')
        .eq('id', id)
        .is('deleted_at', null)
        .single();

      if (postError || !post) {
        return res.status(404).json({ code: 404, message: '帖子不存在' });
      }

      // 获取评论列表
      const { data: comments, error, count } = await supabase
        .from('community_comments')
        .select(`
          *,
          profiles!inner(nickname, avatar_url)
        `, { count: 'exact' })
        .eq('post_id', id)
        .order('created_at', { ascending: false })
        .range(offset, offset + sizeNum - 1);

      if (error) {
        return res.status(500).json({ code: 500, message: '获取评论列表失败' });
      }

      // 格式化返回数据
      const formattedComments = (comments || []).map(comment => ({
        id: comment.id,
        user: {
          id: comment.user_id,
          nickname: comment.profiles.nickname,
          avatar_url: comment.profiles.avatar_url
        },
        content: comment.content,
        created_at: comment.created_at
      }));

      res.json({
        list: formattedComments,
        page: pageNum,
        pageSize: sizeNum,
        total: count || 0
      });
    } catch (error) {
      console.error('获取评论列表错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 创建评论
  app.post('/community/posts/:id/comments', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { content, parent_id } = req.body;

      if (!content || content.trim().length === 0) {
        return res.status(400).json({ code: 400, message: '评论内容不能为空' });
      }

      // 验证帖子是否存在且公开
      const { data: post, error: postError } = await supabase
        .from('community_posts')
        .select('id')
        .eq('id', id)
        .eq('visibility', 'public')
        .is('deleted_at', null)
        .single();

      if (postError || !post) {
        return res.status(404).json({ code: 404, message: '帖子不存在' });
      }

      const userId = req.user.id;
      const commentId = uuidv4();

      const { data: comment, error } = await supabase
        .from('community_comments')
        .insert({
          id: commentId,
          post_id: id,
          user_id: userId,
          content: content.trim(),
          parent_id: parent_id || null,
          created_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (error || !comment) {
        return res.status(500).json({ code: 500, message: '创建评论失败' });
      }

      res.json({ id: comment.id });
    } catch (error) {
      console.error('创建评论错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });
}