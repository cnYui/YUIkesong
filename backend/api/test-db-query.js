// 直接测试数据库查询
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();


const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 错误：缺少必需的环境变量');
  console.error('请确保在 .env 文件中设置了 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function testCommunityQuery() {
  console.log('=== 测试社区帖子数据库查询 ===\n');

  try {
    // 模拟后端的查询
    const page = 1;
    const pageSize = 6;
    const offset = (page - 1) * pageSize;

    console.log(`查询参数: page=${page}, pageSize=${pageSize}, offset=${offset}`);

    // 执行与后端相同的查询
    const { data: posts, error, count } = await supabase
      .from('community_posts')
      .select(`
        *,
        profiles!community_posts_user_id_fkey(nickname, avatar_url)
      `, { count: 'exact' })
      .eq('visibility', 'public')
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + pageSize - 1);

    if (error) {
      console.error('❌ 查询失败!');
      console.error('错误详情:', error);
      console.error('错误消息:', error.message);
      console.error('错误代码:', error.code);
      console.error('错误提示:', error.hint);
      return;
    }

    console.log('✅ 查询成功!');
    console.log(`找到 ${posts?.length || 0} 个帖子`);
    console.log(`总数: ${count}`);

    if (posts && posts.length > 0) {
      console.log('\n帖子详情:');
      posts.forEach((post, index) => {
        console.log(`\n帖子 ${index + 1}:`);
        console.log('  ID:', post.id);
        console.log('  用户ID:', post.user_id);
        console.log('  用户昵称:', post.profiles?.nickname);
        console.log('  用户头像:', post.profiles?.avatar_url);
        console.log('  封面图:', post.cover_image_url);
        console.log('  描述:', post.description);
        console.log('  创建时间:', post.created_at);
      });
    } else {
      console.log('\n当前没有任何帖子。');
      console.log('这是正常的，因为数据库中还没有发布任何内容。');
      console.log('\n预期的API响应应该是:');
      console.log(JSON.stringify({
        list: [],
        page: 1,
        pageSize: 6,
        total: 0
      }, null, 2));
    }

  } catch (error) {
    console.error('❌ 测试异常:', error);
    console.error('详细错误:', error.stack);
  }
}

testCommunityQuery();

