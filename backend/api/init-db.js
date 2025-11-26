// 数据库初始化脚本
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();


const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 错误：缺少必需的环境变量');
  console.error('请确保在 .env 文件中设置了 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function checkTableExists(tableName) {
  try {
    const { data, error } = await supabase
      .from(tableName)
      .select('*')
      .limit(1);

    if (error) {
      console.log(`❌ 表 ${tableName} 不存在或无法访问:`, error.message);
      return false;
    }

    console.log(`✅ 表 ${tableName} 存在`);
    return true;
  } catch (error) {
    console.log(`❌ 检查表 ${tableName} 时出错:`, error.message);
    return false;
  }
}

async function checkDatabase() {
  console.log('=== 开始检查数据库表 ===\n');

  const tables = [
    'profiles',
    'community_posts',
    'community_post_images',
    'community_likes',
    'community_comments'
  ];

  const results = {};

  for (const table of tables) {
    results[table] = await checkTableExists(table);
  }

  console.log('\n=== 检查结果汇总 ===');
  const allExist = Object.values(results).every(exists => exists);

  if (allExist) {
    console.log('✅ 所有必要的表都存在！');

    // 检查数据
    console.log('\n=== 检查数据 ===');

    const { count: profileCount } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true });
    console.log(`Profiles 表中有 ${profileCount || 0} 条记录`);

    const { count: postCount } = await supabase
      .from('community_posts')
      .select('*', { count: 'exact', head: true });
    console.log(`Community Posts 表中有 ${postCount || 0} 条记录`);

  } else {
    console.log('❌ 部分表不存在，需要执行初始化SQL脚本！');
    console.log('\n请执行以下步骤：');
    console.log('1. 打开 Supabase 控制台: https://app.supabase.com/');
    console.log('2. 选择你的项目');
    console.log('3. 进入 SQL Editor');
    console.log('4. 执行文件: backend/supabase/init_community_full.sql');
  }
}

// 测试后端API连接
async function testBackendConnection() {
  console.log('\n=== 测试后端API连接 ===');

  try {
    const response = await fetch('http://localhost:3001/health');
    if (response.ok) {
      const data = await response.json();
      console.log('✅ 后端服务正常运行:', data);
    } else {
      console.log('❌ 后端服务返回错误状态:', response.status);
    }
  } catch (error) {
    console.log('❌ 无法连接到后端服务:', error.message);
    console.log('请确保后端服务已启动: cd backend/api && npm start');
  }
}

// 运行检查
(async () => {
  await testBackendConnection();
  await checkDatabase();
})();

