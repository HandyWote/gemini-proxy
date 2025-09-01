async function handleRequest(request, env) {
  // 处理 OPTIONS 请求以支持 CORS 预检
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Max-Age': '86400'
      }
    });
  }

  try {
    // 从请求头中获取Authorization头中的API密钥
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({
          error: 'Missing API key',
          message: 'Authorization header with Bearer token is required'
        }),
        {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      );
    }

    // 提取API密钥
    const apiKey = authHeader.substring(7); // 移除 "Bearer " 前缀

    // 构建目标URL - 使用wrangler.toml中配置的GEMINI_API_URL
    const baseUrl = env.GEMINI_API_URL || 'https://generativelanguage.googleapis.com/v1beta/openai/';
    const url = new URL(request.url);
    const targetUrl = baseUrl + url.pathname + url.search;

    // 准备转发请求头
    const headers = new Headers(request.headers);
    headers.set('Authorization', `Bearer ${apiKey}`);
    
    // 确保Content-Type头存在
    if (!headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json');
    }

    // 准备转发请求
    const forwardRequest = new Request(targetUrl, {
      method: request.method,
      headers: headers,
      body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : null
    });

    // 转发请求到Gemini API
    const response = await fetch(forwardRequest);

    // 创建新的响应头，仅添加必要的CORS头而不覆盖原始头
    const responseHeaders = new Headers(response.headers);
    
    // 仅在原始响应没有CORS头时才添加，确保透明性
    if (!responseHeaders.has('Access-Control-Allow-Origin')) {
      responseHeaders.set('Access-Control-Allow-Origin', '*');
    }

    // 直接返回原始响应，不进行任何包装或修改
    // 这包括流式响应（SSE）和非流式响应
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders
    });

  } catch (error) {
    // 在发生错误时，直接返回原始错误响应，不进行包装
    console.error('Proxy error:', error);
    
    // 返回一个简洁的错误响应，但保持透明性
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error'
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    );
  }
}

// 将 handleRequest 函数导出为默认的 fetch 事件处理器
export default {
  fetch: handleRequest
};