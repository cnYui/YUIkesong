// 天气相关接口
export function setupWeatherRoutes(app, supabase, authenticateToken) {
  
  // 保存天气缓存
  app.post('/weather/cache', authenticateToken, async (req, res) => {
    try {
      const userId = req.user.id;
      const { weatherData } = req.body;

      if (!weatherData) {
        return res.status(400).json({ code: 400, message: '缺少天气数据' });
      }

      // 保存天气缓存到数据库
      const { error } = await supabase
        .from('profiles')
        .update({
          cached_weather: weatherData,
          weather_updated_at: new Date().toISOString()
        })
        .eq('id', userId);

      if (error) {
        console.error('保存天气缓存失败:', error);
        return res.status(500).json({ code: 500, message: '保存天气缓存失败' });
      }

      console.log(`✅ 用户 ${userId} 的天气缓存已更新`);
      res.json({ success: true });
    } catch (error) {
      console.error('保存天气缓存错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });

  // 获取天气缓存
  app.get('/weather/cache', authenticateToken, async (req, res) => {
    try {
      const userId = req.user.id;

      const { data: profile, error } = await supabase
        .from('profiles')
        .select('cached_weather, weather_updated_at')
        .eq('id', userId)
        .single();

      if (error || !profile) {
        return res.status(404).json({ code: 404, message: '未找到天气缓存' });
      }

      if (!profile.cached_weather) {
        return res.status(404).json({ code: 404, message: '暂无缓存的天气数据' });
      }

      res.json({
        weatherData: profile.cached_weather,
        updatedAt: profile.weather_updated_at
      });
    } catch (error) {
      console.error('获取天气缓存错误:', error);
      res.status(500).json({ code: 500, message: '服务器内部错误' });
    }
  });
}

