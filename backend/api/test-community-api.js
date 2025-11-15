// 测试社区API
import fetch from 'node-fetch';

async function testCommunityAPI() {
  console.log('=== 测试社区帖子API ===\n');
  
  // 这里需要一个有效的token
  // 你需要从Flutter应用获取当前登录用户的token
  const token = 'YOUR_TOKEN_HERE';  // 替换为实际的token
  
  try {
    const url = 'http://localhost:3001/community/posts?page=1&pageSize=6';
    console.log('请求URL:', url);
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('响应状态码:', response.status);
    console.log('响应状态文本:', response.statusText);
    
    const data = await response.json();
    console.log('响应数据:', JSON.stringify(data, null, 2));
    
    if (response.status === 200) {
      console.log('\n✅ API调用成功！');
      console.log(`返回 ${data.list.length} 个帖子，总共 ${data.total} 个`);
    } else {
      console.log('\n❌ API调用失败！');
      console.log('错误信息:', data.message);
    }
  } catch (error) {
    console.error('\n❌ 请求异常:', error.message);
    console.error('详细错误:', error);
  }
}

// 如果没有提供token，显示帮助信息
console.log('注意: 请在代码中替换 YOUR_TOKEN_HERE 为实际的认证token');
console.log('你可以从Flutter应用的登录响应中获取token\n');

testCommunityAPI();

