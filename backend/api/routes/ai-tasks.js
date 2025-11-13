// AI任务相关接口
import { v4 as uuidv4 } from 'uuid';

export function setupAiTasksRoutes(app, supabase, authenticateToken) {
  // 创建AI任务
  app.post('/ai/tasks', authenticateToken, async (req, res) => {
    try {
      const { task_type, selfie_url, clothing_image_urls } = req.body;

      if (!task_type || !['image', 'video'].includes(task_type)) {
        return res.status(400).json({ code: 400, message: '无效的任务类型' });
      }

      if (!selfie_url || !clothing_image_urls || !Array.isArray(clothing_image_urls)) {
        return res.status(400).json({ code: 400, message: '缺少必需的图片URL' });
      }

      const userId = req.user.id;
      const taskId = uuidv4();

      const { data, error } = await supabase
        .from('ai_tasks')
        .insert({
          id: taskId,
          user_id: userId,
          task_type,
          status: 'pending',
          input_payload: {
            selfie_url,
            clothing_image_urls
          },
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select('id, status')
        .single();

      if (error || !data) {
        return res.status(500).json({ code: 500, message: '创建AI任务失败' });
      }

      // 这里可以添加调用AI服务的逻辑
      // 例如：调用外部AI API进行图片处理
      
      res.json({ id: data.id, status: data.status });
    } catch (error) {
      console.error('创建AI任务错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取AI任务状态
  app.get('/ai/tasks/:id', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const { data, error } = await supabase
        .from('ai_tasks')
        .select('status, result_url, updated_at')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        return res.status(404).json({ code: 404, message: 'AI任务不存在' });
      }

      res.json({
        status: data.status,
        result_url: data.result_url
      });
    } catch (error) {
      console.error('获取AI任务状态错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 模拟AI任务处理（用于测试）
  app.post('/ai/tasks/:id/process', authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      // 验证任务是否存在
      const { data: task, error: taskError } = await supabase
        .from('ai_tasks')
        .select('status, input_payload')
        .eq('id', id)
        .eq('user_id', userId)
        .single();

      if (taskError || !task) {
        return res.status(404).json({ code: 404, message: 'AI任务不存在' });
      }

      if (task.status !== 'pending') {
        return res.status(400).json({ code: 400, message: '任务状态不正确' });
      }

      // 更新任务状态为处理中
      await supabase
        .from('ai_tasks')
        .update({ 
          status: 'processing',
          updated_at: new Date().toISOString()
        })
        .eq('id', id);

      // 模拟AI处理过程
      setTimeout(async () => {
        try {
          // 生成模拟结果URL
          const resultUrl = `https://tbjyhqcazhgcmtbdgwpg.supabase.co/storage/v1/object/public/ai-results/${userId}/${id}_result.jpg`;
          
          // 更新任务状态为完成
          await supabase
            .from('ai_tasks')
            .update({ 
              status: 'finished',
              result_url: resultUrl,
              updated_at: new Date().toISOString()
            })
            .eq('id', id);

          console.log(`AI任务 ${id} 处理完成`);
        } catch (error) {
          console.error('AI任务处理失败:', error);
          
          // 更新任务状态为失败
          await supabase
            .from('ai_tasks')
            .update({ 
              status: 'failed',
              updated_at: new Date().toISOString()
            })
            .eq('id', id);
        }
      }, 5000); // 5秒后完成

      res.json({ message: 'AI任务开始处理' });
    } catch (error) {
      console.error('处理AI任务错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });
}