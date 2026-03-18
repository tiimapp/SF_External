# Salesforce Federated Search Mock OpenSearch Service

一个基于 **Node.js + Express** 的最小可用 mock OpenSearch 服务，用于给 **Salesforce Federated Search** 做联通测试。

目标：
- 提供一个可公网访问的搜索 endpoint
- 返回固定 mock 结果
- 支持最基础的 OpenSearch 描述文档
- 可部署到 Linux VPS

## 功能

- `GET /`：服务说明
- `GET /health`：健康检查
- `GET /opensearch.xml`：OpenSearch Description Document
- `GET /search?q=test`：返回固定 JSON 搜索结果
- `GET /search?q=test&format=os-array`：返回 OpenSearch Suggest 风格数组

## 本地运行

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

可按需修改：

```env
PORT=3000
BASE_URL=http://localhost:3000
DEFAULT_RESULT_COUNT=3
MOCK_SERVICE_NAME=Salesforce Mock OpenSearch
```

### 3. 启动

```bash
npm start
```

开发模式：

```bash
npm run dev
```

## 快速验证

```bash
curl http://localhost:3000/health
curl "http://localhost:3000/search?q=salesforce"
curl "http://localhost:3000/search?q=salesforce&format=os-array"
curl http://localhost:3000/opensearch.xml
```

## 返回示例

### `/search?q=salesforce`

```json
{
  "service": "Salesforce Mock OpenSearch",
  "searchTerms": "salesforce",
  "totalResults": 3,
  "startIndex": 1,
  "itemsPerPage": 3,
  "items": [
    {
      "id": "mock-001",
      "title": "Sample Knowledge Article: Federated Search Overview",
      "url": "https://example.com/articles/federated-search-overview",
      "description": "A mock result describing how Salesforce Federated Search can connect to external content sources.",
      "type": "Knowledge",
      "updatedAt": "2026-03-18T08:00:00Z"
    }
  ]
}
```

### `/search?q=salesforce&format=os-array`

```json
[
  "salesforce",
  ["title1", "title2"],
  ["description1", "description2"],
  ["https://...", "https://..."]
]
```

## 部署到 Linux VPS（Ubuntu / Debian / Alibaba Cloud Linux / RHEL 系）

### 1. 上传到 GitHub

在本地仓库中执行：

```bash
git init
git add .
git commit -m "Initial mock OpenSearch service"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

### 2. 在 VPS 上部署

```bash
git clone <your-github-repo-url>
cd <your-repo-folder>
bash deploy/install.sh
```

脚本会：
- 安装 Node.js（如果系统没有）
- 安装 npm 依赖
- 初始化 `.env`
- 注册 systemd 服务 `mock-opensearch`
- 启动服务

已支持：
- Ubuntu / Debian（`apt-get`）
- Alibaba Cloud Linux / Amazon Linux / CentOS / RHEL / Rocky / AlmaLinux / Fedora（`yum` / `dnf`）

### 3. 查看服务状态

```bash
sudo systemctl status mock-opensearch --no-pager
```

### 4. 修改配置并重启

```bash
nano .env
sudo systemctl restart mock-opensearch
```

## Nginx 反向代理

项目内提供了示例文件：

`deploy/nginx.conf.example`

建议将 Node 服务仅监听在 VPS 本地端口，然后由 Nginx 暴露公网域名。

示例操作：

```bash
# Debian / Ubuntu
sudo apt-get update
sudo apt-get install -y nginx

# Alibaba Cloud Linux / RHEL 系
sudo yum install -y nginx || sudo dnf install -y nginx

sudo cp deploy/nginx.conf.example /etc/nginx/sites-available/mock-opensearch
sudo ln -s /etc/nginx/sites-available/mock-opensearch /etc/nginx/sites-enabled/mock-opensearch
sudo nginx -t
sudo systemctl reload nginx
```

然后把 `server_name` 改成你的域名。

> 注意：在 RHEL / Alibaba Cloud Linux 上，Nginx 的站点目录布局可能与 Debian 不同。如果没有 `/etc/nginx/sites-available`，可以直接把配置放到 `/etc/nginx/conf.d/mock-opensearch.conf`。

## HTTPS 建议

如果 Salesforce 需要稳定公网访问，推荐配置域名 + HTTPS：

```bash
# Debian / Ubuntu
sudo apt-get install -y certbot python3-certbot-nginx

# Alibaba Cloud Linux / RHEL 系
sudo yum install -y certbot python3-certbot-nginx || sudo dnf install -y certbot python3-certbot-nginx

sudo certbot --nginx -d your-domain.example.com
```

完成后把 `.env` 里的：

```env
BASE_URL=https://your-domain.example.com
```

再重启服务：

```bash
sudo systemctl restart mock-opensearch
```

## Salesforce 配置建议

你可优先尝试把以下 URL 提供给 Salesforce：

- OpenSearch 描述地址：`https://your-domain.example.com/opensearch.xml`
- 搜索地址：`https://your-domain.example.com/search?q=test`

如果 Salesforce 后续对字段名、认证头、返回结构有更严格要求，可以在这个 mock 服务上继续迭代。

## 后续可扩展项

- Basic Auth / Bearer Token 鉴权
- 按 query 动态过滤结果
- RSS / Atom 输出
- Salesforce 实际请求报文适配
- Docker 部署
