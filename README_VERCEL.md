# 部署到 Vercel

本指南将帮助您将 Gemini Proxy 服务部署到 Vercel。

## 部署步骤

1. **安装 Vercel CLI**
   如果您尚未安装 Vercel CLI，请运行以下命令：
   ```bash
   npm install -g vercel
   ```

2. **登录到 Vercel**
   ```bash
   vercel login
   ```

3. **部署项目**
   在项目根目录中运行以下命令：
   ```bash
   vercel
   ```

4. **配置项目**
   在部署过程中，Vercel 会询问一些问题：
   - 设置项目名称（例如：gemini-proxy）
   - 选择框架预设（选择 "Other"）
   - 配置输出目录（留空）

5. **访问您的部署**
   部署完成后，Vercel 将提供一个 URL，您可以通过该 URL 访问您的 Gemini Proxy 服务。

## 环境变量

项目使用以下环境变量：

- `GEMINI_API_URL`: Gemini API 的基础 URL（默认为 https://generativelanguage.googleapis.com/v1beta）

这些变量已在 `vercel.json` 文件中配置。如果您需要更改它们，可以在 Vercel 仪表板的项目设置中进行修改。

## 使用说明

部署后，您可以像使用原始 Cloudflare Workers 版本一样使用该服务：

1. **基本代理功能**:
   - 发送请求到您的 Vercel 部署 URL，它将代理到 Gemini API
   - 在请求头中添加 `x-goog-api-key` 字段来指定 API 密钥

2. **OpenAI 兼容接口**:
   - 使用 `/chat/completions`、`/completions`、`/embeddings` 和 `/models` 端点
   - 在 `Authorization` 头中使用 `Bearer YOUR_API_KEY` 格式

3. **验证端点**:
   - 使用 `/verify` 端点来验证 API 密钥

## 注意事项

- Vercel 的免费套餐可能有一些限制，如执行时间限制和请求频率限制。
- 如果您需要更高的性能或更多的请求，可以考虑升级到 Vercel 的付费套餐。
- 与 Cloudflare Workers 相比，Vercel Serverless Functions 的冷启动时间可能会略有不同。