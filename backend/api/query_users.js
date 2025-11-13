import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://tightenjiachui.supabase.co',
  process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZ2h0ZW5qaWFjaHVpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjI5NDI5OSwiZXhwIjoyMDQ3ODcwMjk5fQ.nw4hSpgZV8VFq5FUF6USGqKjRBVrPVoS1iDsoV5j1t0',
  {
    auth: {
      persistSession: false
    }
  }
);

async function queryUsers() {
  try {
    console.log('=== 查询用户数据 ===\n');

    // 1. 查询profiles表中的用户数据
    console.log('1. 用户资料表 (profiles):');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false });

    if (profilesError) {
      console.error('查询profiles表错误:', profilesError);
    } else {
      console.log(`总用户数: ${profiles.length}`);
      profiles.forEach((profile, index) => {
        console.log(`\n用户 ${index + 1}:`);
        console.log(`  ID: ${profile.id}`);
        console.log(`  昵称: ${profile.nickname || '未设置'}`);
        console.log(`  头像URL: ${profile.avatar_url || '未设置'}`);
        console.log(`  城市: ${profile.city || '未设置'}`);
        console.log(`  创建时间: ${new Date(profile.created_at).toLocaleString()}`);
      });
    }

    // 2. 使用管理员权限查询auth.users表
    console.log('\n\n2. 认证用户表 (auth.users):');
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();

    if (authError) {
      console.error('查询auth.users表错误:', authError);
    } else {
      console.log(`总认证用户数: ${authUsers.users.length}`);
      authUsers.users.forEach((user, index) => {
        console.log(`\n认证用户 ${index + 1}:`);
        console.log(`  ID: ${user.id}`);
        console.log(`  邮箱: ${user.email}`);
        console.log(`  邮箱确认状态: ${user.email_confirmed_at ? '已确认' : '未确认'}`);
        console.log(`  创建时间: ${new Date(user.created_at).toLocaleString()}`);
        console.log(`  最后登录: ${user.last_sign_in_at ? new Date(user.last_sign_in_at).toLocaleString() : '从未登录'}`);
        console.log(`  用户元数据: ${JSON.stringify(user.user_metadata, null, 2)}`);
      });
    }

    // 3. 统计信息
    console.log('\n\n3. 用户统计:');
    if (profiles && authUsers) {
      const profileIds = new Set(profiles.map(p => p.id));
      const authIds = new Set(authUsers.users.map(u => u.id));
      
      console.log(`有资料的用户数: ${profiles.length}`);
      console.log(`已认证的用户数: ${authUsers.users.length}`);
      console.log(`同时有资料和认证的用户数: ${[...profileIds].filter(id => authIds.has(id)).length}`);
      
      // 找出只有认证没有资料的用户
      const authOnly = [...authIds].filter(id => !profileIds.has(id));
      if (authOnly.length > 0) {
        console.log(`只有认证没有资料的用户ID: ${authOnly.join(', ')}`);
      }
      
      // 找出只有资料没有认证的用户
      const profileOnly = [...profileIds].filter(id => !authIds.has(id));
      if (profileOnly.length > 0) {
        console.log(`只有资料没有认证的用户ID: ${profileOnly.join(', ')}`);
      }
    }

  } catch (error) {
    console.error('查询过程出错:', error);
  }
}

queryUsers();