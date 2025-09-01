async function handleRequest(request, env) {
  console.log('=== New Request ===');
  console.log('Method:', request.method);
  console.log('URL:', request.url);
  console.log('Headers:', Object.fromEntries(request.headers.entries()));
  
  // 处理 OPTIONS 请求以支持 CORS 预检
  if (request.method === 'OPTIONS') {
    console.log('Handling OPTIONS preflight request');
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
    console.log('Auth Header:', authHeader ? 'Present' : 'Missing');
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
    console.log('API Key extracted:', apiKey.substring(0, 8) + '...'); // 只显示前8位

    // 构建目标URL - 使用wrangler.toml中配置的GEMINI_API_URL
    const baseUrl = env.GEMINI_API_URL || 'https://generativelanguage.googleapis.com/v1beta';
    const url = new URL(request.url);
    
    // 构建正确的端点 URL
    let targetUrl;
    if (url.pathname === '/' || url.pathname === '') {
      // 如果是根路径，使用 OpenAI 兼容的 chat/completions
      targetUrl = baseUrl.replace(/\/$/, '') + '/chat/completions';
    } else {
      // 使用 OpenAI 兼容端点
      const cleanBase = baseUrl.replace(/\/$/, '');
      const cleanPath = url.pathname.startsWith('/') ? url.pathname : '/' + url.pathname;
      targetUrl = cleanBase + '/openai' + cleanPath + url.search;
    }
    
    console.log('Target URL:', targetUrl);
    console.log('Pathname:', url.pathname);
    console.log('Search params:', url.search);

    // 准备转发请求头
    const headers = new Headers(request.headers);
    headers.set('Authorization', `Bearer ${apiKey}`);
    
    // 确保Content-Type头存在
    if (!headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json');
    }
    console.log('Forward Headers:', Object.fromEntries(headers.entries()));

    // 读取请求体（用于调试）
    let requestBody = null;
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      try {
        requestBody = await request.clone().text();
        console.log('Request Body:', requestBody);
      } catch (e) {
        console.log('Could not read request body:', e.message);
      }
    }

    // 准备转发请求
    const forwardRequest = new Request(targetUrl, {
      method: request.method,
      headers: headers,
      body: request.method !== 'GET' && request.method !== 'HEAD' ? requestBody : null
    });

    console.log('Forwarding request to Gemini API...');
    // 转发请求到Gemini API
    const response = await fetch(forwardRequest);
    console.log('Response status:', response.status, response.statusText);

    // 创建新的响应头，仅添加必要的CORS头而不覆盖原始头
    const responseHeaders = new Headers(response.headers);
    console.log('Response Headers:', Object.fromEntries(responseHeaders.entries()));
    
    // 仅在原始响应没有CORS头时才添加，确保透明性
    if (!responseHeaders.has('Access-Control-Allow-Origin')) {
      responseHeaders.set('Access-Control-Allow-Origin', '*');
    }

    // 读取响应内容（用于调试，限制大小）
    let responseBody = null;
    try {
      const clonedResponse = response.clone();
      const contentType = responseHeaders.get('content-type') || '';
      
      if (contentType.includes('application/json')) {
        responseBody = await clonedResponse.text();
        console.log('Response Body (JSON):', responseBody.substring(0, 500) + (responseBody.length > 500 ? '...' : ''));
      } else if (contentType.includes('text/')) {
        responseBody = await clonedResponse.text();
        console.log('Response Body (Text):', responseBody.substring(0, 200) + (responseBody.length > 200 ? '...' : ''));
      } else {
        console.log('Response Body: [non-text content, size:', responseHeaders.get('content-length') || 'unknown', ']');
      }
    } catch (e) {
      console.log('Could not read response body:', e.message);
    }

    console.log('=== Request Complete ===\n');

    // 直接返回原始响应，不进行任何包装或修改
    // 这包括流式响应（SSE）和非流式响应
    return new Response(responseBody || response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders
    });

  } catch (error) {
    // 在发生错误时，直接返回原始错误响应，不进行包装
    console.error('Proxy error:', error);
    console.error('Error stack:', error.stack);
    console.error('=== Error End ===\n');
    
    // 返回一个简洁的错误响应，但保持透明性
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        timestamp: new Date().toISOString()
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