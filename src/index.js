
import OpenAI from 'openai';

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
    // 从 env.OPENAI_API_KEY 获取 OpenAI API 密钥
    const OPENAI_API_KEY = env.OPENAI_API_KEY;
    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({
          error: 'Missing API key',
          message: 'OPENAI_API_KEY environment variable is not set'
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

    // 创建 OpenAI 客户端实例
    const openai = new OpenAI({
      apiKey: OPENAI_API_KEY,
      // 如果需要使用代理或其他自定义设置，可以在这里配置
    });

    // 解析请求体
    const requestBody = await request.json();

    // 调用 OpenAI API
    const completion = await openai.chat.completions.create({
      model: requestBody.model || 'gpt-3.5-turbo',
      messages: requestBody.messages || [],
      // 可以传递其他参数
      ...requestBody
    });

    // 创建响应对象
    const response = new Response(JSON.stringify(completion), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': '*'
      }
    });

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