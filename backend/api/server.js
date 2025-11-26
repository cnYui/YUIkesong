import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Supabase配置 - 必须通过环境变量提供
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 错误：缺少必需的环境变量');
  console.error('请确保在 .env 文件中设置了以下变量：');
  console.error('  - SUPABASE_URL');
  console.error('  - SUPABASE_SERVICE_ROLE_KEY');
  console.error('参考 .env.example 文件获取更多信息');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function ensurePublicBucket(bucket) {
  try {
    const { data: info } = await supabase.storage.getBucket(bucket);
    if (!info || info.public !== true) {
      const { error: updErr } = await supabase.storage.updateBucket(bucket, { public: true });
      if (updErr) {
        console.warn(`存储桶 ${bucket} 设为公开失败:`, updErr);
      } else {
        console.log(`存储桶 ${bucket} 已设为公开`);
      }
    }
  } catch (e) {
    console.warn(`检查/更新存储桶 ${bucket} 公开状态异常:`, e);
  }
}

ensurePublicBucket('wardrobe');

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 认证中间件
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ code: 401, message: '访问令牌缺失' });
  }

  try {
    // 首先尝试使用Supabase标准认证
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (!error && user) {
      req.user = user;
      return next();
    }

    // 如果标准认证失败，尝试验证自定义JWT令牌
    try {
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        console.error('JWT_SECRET 未设置');
        return res.status(500).json({ code: 500, message: '服务器配置错误' });
      }
      const decoded = jwt.verify(token, jwtSecret);

      if (decoded && decoded.sub) {
        // 从数据库获取用户信息
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('id, nickname, avatar_url')
          .eq('id', decoded.sub)
          .single();

        if (profileError || !profile) {
          return res.status(401).json({ code: 401, message: '用户不存在' });
        }

        // 创建用户对象
        req.user = {
          id: decoded.sub,
          email: decoded.email,
          user_metadata: decoded.user_metadata || {}
        };

        return next();
      }
    } catch (jwtError) {
      console.error('JWT验证失败:', jwtError);
    }

    return res.status(401).json({ code: 401, message: '无效的访问令牌' });
  } catch (error) {
    console.error('认证错误:', error);
    return res.status(500).json({ code: 500, message: '认证服务错误' });
  }
};

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 认证相关接口
app.post('/auth/register', async (req, res) => {
  try {
    const { email, password, nickname } = req.body;

    if (!email || !password || !nickname) {
      return res.status(400).json({ code: 400, message: '缺少必需参数' });
    }

    // 添加调试输出
    console.log('=== 用户注册调试信息 ===');
    console.log('用户名:', nickname);
    console.log('邮箱:', email);
    console.log('密码:', password);
    console.log('========================');

    // 邮箱格式验证
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email)) {
      console.log('邮箱格式验证失败:', email);
      return res.status(400).json({ code: 400, message: '邮箱格式不正确' });
    }

    // 检查是否为测试邮箱
    const testPatterns = ['test@', 'demo@', 'example@', 'sample@'];
    const isTestEmail = testPatterns.some(pattern => email.toLowerCase().startsWith(pattern));
    if (isTestEmail) {
      console.log('检测到测试邮箱:', email);
    }

    // 检查用户是否已存在
    const { data: existingUser } = await supabase
      .from('auth.users')
      .select('id, email_confirmed_at')
      .eq('email', email)
      .single();

    let userId;
    let isNewUser = false;

    if (existingUser) {
      // 用户已存在
      console.log('用户已存在，邮箱:', email);
      userId = existingUser.id;

      if (existingUser.email_confirmed_at) {
        console.log('用户邮箱已确认');
      } else {
        // 如果邮箱未确认，尝试确认
        try {
          const { error: confirmError } = await supabase.auth.admin.updateUserById(
            userId,
            { email_confirmed: true }
          );
          if (confirmError) {
            console.error('邮箱确认失败:', confirmError);
          } else {
            console.log('邮箱确认成功');
          }
        } catch (confirmError) {
          console.error('邮箱确认异常:', confirmError);
        }
      }
    } else {
      // 新用户注册
      console.log('新用户注册，邮箱:', email);
      isNewUser = true;

      // 使用Admin API直接创建已确认的用户
      try {
        const { data: adminData, error: adminError } = await supabase.auth.admin.createUser({
          email,
          password,
          email_confirmed: true,
          user_metadata: {
            nickname: nickname
          }
        });

        if (adminError) {
          console.error('Admin用户创建失败:', adminError);
          return res.status(400).json({ code: 400, message: adminError.message });
        }

        if (!adminData.user) {
          return res.status(500).json({ code: 500, message: '用户创建失败' });
        }

        userId = adminData.user.id;
        console.log('用户创建成功（已确认邮箱）！用户ID:', userId);

      } catch (adminError) {
        console.error('Admin API异常:', adminError);
        // 如果Admin API失败，回退到普通注册
        const { data: authData, error: authError } = await supabase.auth.signUp({
          email,
          password
        });

        if (authError) {
          console.error('Supabase注册错误:', authError);
          return res.status(400).json({ code: 400, message: authError.message });
        }

        if (!authData.user) {
          return res.status(500).json({ code: 500, message: '用户创建失败' });
        }

        userId = authData.user.id;
        console.log('用户创建成功！用户ID:', userId);
      }
    }

    // 检查用户资料是否存在
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .single();

    if (!existingProfile) {
      // 创建用户资料（仅当不存在时）
      const { error: profileError } = await supabase
        .from('profiles')
        .insert({
          id: userId,
          nickname,
          created_at: new Date().toISOString()
        });

      if (profileError) {
        console.error('用户资料创建失败:', profileError);
        // 如果资料创建失败，但不删除用户，允许重试
        return res.status(500).json({ code: 500, message: '用户资料创建失败' });
      }

      console.log('用户注册成功！用户ID:', userId);
      res.json({ id: userId });
    } else {
      console.log('用户资料已存在，跳过创建');
      console.log('用户注册成功！用户ID:', userId);
      res.json({ id: userId });
    }
  } catch (error) {
    console.error('注册错误:', error);
    res.status(500).json({ code: 500, message: '服务器内部错误' });
  }
});

app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ code: 400, message: '缺少邮箱或密码' });
    }

    // 添加调试输出
    console.log('=== 用户登录调试信息 ===');
    console.log('邮箱:', email);
    console.log('密码:', password);
    console.log('======================');

    // 步骤1: 使用Admin API获取用户信息（不验证密码）
    let targetUser;
    try {
      const { data: users, error: listError } = await supabase.auth.admin.listUsers();

      if (listError) {
        console.error('获取用户列表失败:', listError);
        return res.status(500).json({ code: 500, message: '系统错误' });
      }

      // 查找对应邮箱的用户
      targetUser = users.users.find(user => user.email === email);
      if (!targetUser) {
        console.log('用户不存在:', email);
        return res.status(401).json({ code: 401, message: '邮箱或密码错误' });
      }

      console.log('找到用户，用户ID:', targetUser.id);
    } catch (adminError) {
      console.error('Admin API错误:', adminError);
      return res.status(500).json({ code: 500, message: '系统错误' });
    }

    // 步骤2: 验证密码正确性（关键步骤）
    console.log('开始验证密码正确性...');
    try {
      // 使用Supabase的signIn方法验证密码，但捕获邮箱未确认的错误
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError) {
        if (authError.message.includes('Email not confirmed')) {
          console.log('密码正确，但邮箱未确认');
          // 密码正确，继续处理邮箱确认
        } else {
          console.log('密码验证失败:', authError.message);
          return res.status(401).json({ code: 401, message: '邮箱或密码错误' });
        }
      } else if (authData.user) {
        console.log('密码验证成功，用户ID:', authData.user.id);
        // 如果密码验证通过且邮箱已确认，直接返回成功
        if (authData.user.email_confirmed_at) {
          console.log('邮箱已确认，登录成功');

          // 获取用户资料
          const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('id, nickname, avatar_url')
            .eq('id', authData.user.id)
            .single();

          if (profileError || !profile) {
            console.error('获取用户资料失败:', profileError);
            return res.status(500).json({ code: 500, message: '获取用户资料失败' });
          }

          return res.json({
            token: authData.session.access_token,
            user: profile,
            message: '登录成功'
          });
        }
      }
    } catch (passwordError) {
      console.error('密码验证异常:', passwordError);
      return res.status(401).json({ code: 401, message: '邮箱或密码错误' });
    }

    // 步骤3: 密码验证通过，处理邮箱未确认的情况
    console.log('密码验证通过，检查邮箱确认状态...');

    if (!targetUser.email_confirmed_at) {
      console.log('用户邮箱未确认，现在确认邮箱...');
      try {
        const { error: confirmError } = await supabase.auth.admin.updateUserById(
          targetUser.id,
          {
            email_confirmed: true,
            user_metadata: targetUser.user_metadata || {}
          }
        );

        if (confirmError) {
          console.error('邮箱确认失败:', confirmError);
          // 邮箱确认失败，但密码正确，仍然允许登录
        } else {
          console.log('邮箱确认成功');
        }
      } catch (confirmError) {
        console.error('邮箱确认异常:', confirmError);
        // 邮箱确认异常，但密码正确，仍然允许登录
      }
    }

    // 步骤4: 创建自定义登录会话
    console.log('创建自定义登录会话...');

    // 获取用户资料
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id, nickname, avatar_url')
      .eq('id', targetUser.id)
      .single();

    if (profileError || !profile) {
      console.error('获取用户资料失败:', profileError);
      return res.status(500).json({ code: 500, message: '获取用户资料失败' });
    }

    // 创建自定义JWT令牌
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      console.error('JWT_SECRET 未设置');
      return res.status(500).json({ code: 500, message: '服务器配置错误' });
    }

    const customToken = jwt.sign(
      {
        sub: targetUser.id,
        email: targetUser.email,
        user_metadata: targetUser.user_metadata,
        role: 'authenticated',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24小时有效期
      },
      jwtSecret,
      { algorithm: 'HS256' }
    );

    console.log('登录成功！用户ID:', targetUser.id, '用户名:', profile.nickname);

    // 更新最后登录时间
    await supabase
      .from('profiles')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', targetUser.id);

    return res.json({
      token: customToken,
      user: profile,
      message: '登录成功（自定义认证）'
    });

  } catch (error) {
    console.error('登录错误:', error);
    res.status(500).json({ code: 500, message: '服务器内部错误' });
  }
});

app.post('/auth/reset', async (req, res) => {
  try {
    const { email, token, new_password } = req.body;

    if (email && !token && !new_password) {
      // 发送重置密码邮件
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${process.env.FRONTEND_URL}/reset-password`
      });

      if (error) {
        return res.status(400).json({ code: 400, message: error.message });
      }

      return res.json({ ok: true });
    }

    if (token && new_password) {
      // 更新密码
      const { error } = await supabase.auth.updateUser({
        password: new_password
      });

      if (error) {
        return res.status(400).json({ code: 400, message: error.message });
      }

      return res.json({ ok: true });
    }

    return res.status(400).json({ code: 400, message: '参数错误' });
  } catch (error) {
    console.error('重置密码错误:', error);
    res.status(500).json({ code: 500, message: '服务器内部错误' });
  }
});

// 用户资料相关接口
app.get('/users/me', authenticateToken, async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, nickname, avatar_url, city')
      .eq('id', req.user.id)
      .single();

    if (error || !profile) {
      return res.status(404).json({ code: 404, message: '用户资料不存在' });
    }

    res.json(profile);
  } catch (error) {
    console.error('获取用户资料错误:', error);
    res.status(500).json({ code: 500, message: '服务器内部错误' });
  }
});

app.put('/users/me', authenticateToken, async (req, res) => {
  try {
    const { nickname, avatar_url, city } = req.body;
    const updates = {};

    if (nickname !== undefined) updates.nickname = nickname;
    if (avatar_url !== undefined) updates.avatar_url = avatar_url;
    if (city !== undefined) updates.city = city;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ code: 400, message: '没有有效的更新字段' });
    }

    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', req.user.id)
      .select('id, nickname, avatar_url, city')
      .single();

    if (error || !data) {
      return res.status(500).json({ code: 500, message: '更新用户资料失败' });
    }

    res.json(data);
  } catch (error) {
    console.error('更新用户资料错误:', error);
    res.status(500).json({ code: 500, message: '服务器内部错误' });
  }
});

// 导入路由模块
import { setupSelfiesRoutes } from './routes/selfies.js';
import { setupWardrobeRoutes } from './routes/wardrobe.js';
import { setupAiTasksRoutes } from './routes/ai-tasks.js';
import { setupSavedLooksRoutes } from './routes/saved-looks.js';
import { setupCommunityRoutes } from './routes/community.js';
import { setupWeatherRoutes } from './routes/weather.js';

// 设置所有路由
setupSelfiesRoutes(app, supabase, authenticateToken);
setupWardrobeRoutes(app, supabase, authenticateToken);
setupAiTasksRoutes(app, supabase, authenticateToken);
setupSavedLooksRoutes(app, supabase, authenticateToken);
setupCommunityRoutes(app, supabase, authenticateToken);
setupWeatherRoutes(app, supabase, authenticateToken);

// 启动服务器
app.listen(PORT, () => {
  console.log(`服务器运行在端口 ${PORT}`);
  console.log(`Supabase URL: ${supabaseUrl}`);
});
