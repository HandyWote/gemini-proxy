# Gemini Proxy

一个部署在 Cloudflare Worker 和 Vercel 上的轻量级代理，用于转发请求到 Gemini API，从而避免需要使用代理访问。

部分代码来自 [tech-shrimp/gemini-balance-lite](https://github.com/tech-shrimp/gemini-balance-lite) 仓库。

## 新功能

本项目基于 [openai-gemini](https://github.com/PublicAffairs/openai-gemini) 项目，支持完整的 OpenAI API 兼容性，包括 `/v1/chat/completions` 聊天补全（支持流式和非流式）、`/v1/embeddings` 文本嵌入和 `/v1/models` 获取可用模型列表等功能。同时支持流式响应、函数调用、多模态输入（图像和音频）以及多种 Google Gemini 模型（如 `gemini-2.5-flash`、`gemini-2.5-pro`、`gemma-3-27b-it`、`learnlm-1.5-pro-experimental` 等）。

## 部署说明

### 快速部署
1. 克隆项目仓库
2. 安装依赖：`npm install`
3. 配置环境变量（可选）
4. 部署到 Cloudflare Workers：`npm run deploy` 或 `wrangler deploy`
5. 部署到 Vercel：直接推送到 Vercel 平台

### 本地测试
```bash
npx wrangler dev
```

## 使用方法

客户端只需将请求的 base URL 更改为代理服务的 URL。例如，将原本的 OpenAI API 调用：

```javascript
const response = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_GEMINI_API_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'gemini-2.5-flash',
    messages: [{ role: 'user', content: 'Hello!' }]
  })
});
```

修改为使用 Gemini Proxy：

```javascript
const response = await fetch('https://your-worker.your-subdomain.workers.dev/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_GEMINI_API_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'gemini-2.5-flash',
    messages: [{ role: 'user', content: 'Hello!' }]
  })
});
```

### 示例代码

#### 聊天补全
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/v1/chat/completions \
  -H "Authorization: Bearer YOUR_GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-2.5-flash",
    "messages": [{"role": "user", "content": "你好，世界！"}],
    "max_tokens": 100
  }'
```

#### 获取模型列表
```bash
curl -X GET https://your-worker.your-subdomain.workers.dev/v1/models \
  -H "Authorization: Bearer YOUR_GEMINI_API_KEY"
```

#### 文本嵌入
```bash
curl -X POST https://your-worker.your-subdomain.workers.dev/v1/embeddings \
  -H "Authorization: Bearer YOUR_GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "text-embedding-004",
    "input": "这是一个测试文本"
  }'
```

## 配置选项

在 `wrangler.toml` 中可以配置 Worker 名称、兼容性日期等。环境变量 `GEMINI_API_URL` 用于设置 Gemini API 基础 URL，默认为 https://generativelanguage.googleapis.com/v1beta。

## 项目特点

本项目无状态，不存储任何 API Key 或用户数据，透明转发请求和响应，支持 CORS 跨域请求，完全兼容 OpenAI API，并基于 Cloudflare Workers 和 Vercel Edge Functions 边缘计算提供高性能。

## 注意事项

API Key 需要在请求中提供，代理服务不会存储或替换您的 API Key。使用时需注意 Google Gemini API 的速率限制，不同模型的可用性可能因地区和账户类型而异。

## 故障排除

常见问题包括 CORS 错误（需确保请求头包含正确的 Authorization）、模型不可用（检查模型名称是否正确）和 API Key 无效（确认 API Key 有访问 Gemini API 的权限）。可以使用 `npx wrangler dev` 启动本地开发服务器查看详细日志进行调试。

## 许可证
MIT License - 详见 LICENSE 文件