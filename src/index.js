// Cloudflare Worker 入口文件
// Gemini API 代理服务

/**
 * 处理传入的请求并转发到 Gemini API
 * @param {Request} request - 原始请求对象
 * @param {object} env - 环境变量
 * @returns {Response} 转发后的响应
 */
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
    // 从 env.GEMINI_API_URL 获取 Gemini API 基础 URL，如果未设置则默认为 https://generativelanguage.googleapis.com
    const GEMINI_API_URL = env.GEMINI_API_URL || 'https://generativelanguage.googleapis.com';
    
    // 构造目标 URL：将原始请求的路径和查询参数附加到 Gemini API 基础 URL
    const url = new URL(request.url);
    const targetUrl = GEMINI_API_URL + url.pathname + url.search;
    
    // 复制原始请求的 headers 到一个新的 Headers 对象
    const headers = new Headers(request.headers);
    
    // 修改 Host 头为 Gemini API 的主机名
    headers.set('Host', new URL(GEMINI_API_URL).host);
    
    // 创建一个新的请求对象，目标是构造好的 URL，使用原始请求的方法、headers 和 body
    const geminiRequest = new Request(targetUrl, {
      method: request.method,
      headers: headers,
      body: request.body,
      redirect: 'follow'
    });
    
    // 使用 fetch 发送新构造的请求到 Gemini API
    const geminiResponse = await fetch(geminiRequest);
    
    // 创建一个新的响应对象，复制 Gemini API 响应的状态码、headers 和 body
    const response = new Response(geminiResponse.body, {
      status: geminiResponse.status,
      statusText: geminiResponse.statusText,
      headers: geminiResponse.headers
    });
    
    // 为响应添加 CORS 头 (Access-Control-Allow-Origin: *)
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', '*');
    
    // 返回这个新的响应对象
    return response;
  } catch (error) {
    // 在发生错误时，捕获异常并返回一个 JSON 格式的 500 错误响应，包含错误信息
    return new Response(
      JSON.stringify({
        error: 'Proxy error',
        message: error.message
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