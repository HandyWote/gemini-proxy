# Gemini Proxy

一个部署在 Cloudflare Worker 上的轻量级代理，用于转发请求到 Gemini API，从而避免需要使用代理访问。

## 🚀 新功能

基于 [openai-gemini](https://github.com/PublicAffairs/openai-gemini) 项目，现在支持完整的 OpenAI API 兼容性：

### ✅ 支持的端点
- `/v1/chat/completions` - 聊天补全（支持流式和非流式）
- `/v1/embeddings` - 文本嵌入
- `/v1/models` - 获取可用模型列表

### ✅ 增强功能
- **流式响应** - 支持 Server-Sent Events (SSE)
- **函数调用** - 支持 OpenAI 的函数调用功能
- **多模态输入** - 支持图像和音频输入
- **多模型支持** - 支持 Gemini、Gemma、LearnLM 系列模型
- **CORS 支持** - 完全支持跨域请求

## 🛠️ 部署说明

### 快速部署
1. 克隆项目仓库
2. 安装依赖：`npm install`
3. 配置环境变量（可选）
4. 部署到 Cloudflare Workers：`npm run deploy` 或 `wrangler deploy`

### 本地测试
```bash
npx wrangler dev
```

## 📖 使用方法

### 基本使用
客户端只需将请求的 base URL 更改为代理服务的 URL：

```javascript
// 原 OpenAI API 调用
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

// 使用 Gemini Proxy
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

### 支持的模型
- `gemini-2.5-flash` (默认)
- `gemini-2.5-pro`
- `gemma-3-27b-it`
- `learnlm-1.5-pro-experimental`
- 以及其他 Google Gemini 模型

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

## 🔧 配置选项

### Wrangler 配置
在 `wrangler.toml` 中可以配置：
- `name` - Worker 名称
- `compatibility_date` - 兼容性日期
- 环境变量等

### 环境变量
- `GEMINI_API_URL` - Gemini API 基础 URL（默认：https://generativelanguage.googleapis.com/v1beta）

## 🎯 项目特点

- **无状态**：不存储任何 API Key 或用户数据
- **透明转发**：保持请求和响应的原始格式
- **支持 CORS**：允许跨域请求
- **完整兼容**：100% OpenAI API 兼容
- **高性能**：基于 Cloudflare Workers 边缘计算

## 📝 注意事项

1. **API Key 安全**：API Key 需要在请求中提供，代理服务不会存储或替换您的 API Key
2. **速率限制**：受 Google Gemini API 的速率限制
3. **模型可用性**：不同模型的可用性可能因地区和账户类型而异

## 🐛 故障排除

### 常见问题
- **CORS 错误**：确保请求头包含正确的 Authorization
- **模型不可用**：检查模型名称是否正确
- **API Key 无效**：确认 API Key 有访问 Gemini API 的权限

### 调试
使用 `npx wrangler dev` 启动本地开发服务器，查看详细日志。

## 📄 许可证
MIT License - 详见 LICENSE 文件