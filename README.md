# Gemini Proxy

一个部署在 Cloudflare Worker 上的轻量级代理，用于转发请求到 Gemini API，从而避免需要使用代理访问。

## 部署说明

* 克隆项目仓库。
* 安装依赖：`npm install`。
* 部署到 Cloudflare Workers：`npm run deploy` 或 `wrangler deploy`。

## 使用方法

* 客户端只需将请求的 base URL 更改为代理服务的 URL。
* 注意：API Key 需要在请求中提供，代理服务不会存储或替换您的 API Key。

## 项目特点

* 无状态：不存储任何 API Key 或用户数据。
* 透明转发：保持请求和响应的原始格式。
* 支持 CORS：允许跨域请求。