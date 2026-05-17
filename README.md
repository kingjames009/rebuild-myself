# 日新 — 全维度人生重塑

全维度人生重塑自律成长 APP，帮助用户通过目标设定、习惯养成、每日反思实现自我提升。

## 技术栈

| 模块 | 技术 |
|------|------|
| 后端 | Spring Boot 3.2, MyBatis-Plus 3.5, MySQL 8, JWT, DeepSeek AI |
| Web 前端 | Vue 3, Vite, Element Plus |
| 移动端 | Flutter (跨平台) |

## 项目结构

```
rebuildmyself/
├── rebuild-myself-server/   # Spring Boot 后端
│   ├── src/main/java/       # Java 源码
│   ├── src/main/resources/  # 配置文件
│   ├── deploy/              # 部署相关（env.sh 模板、systemd 配置）
│   └── pom.xml
├── rebuild-myself-web/      # Vue 3 Web 前端
├── rebuild-myself-flutter/  # Flutter 移动端
├── .github/workflows/       # GitHub Actions CI/CD
└── DEPLOY.md                # 部署文档
```

## 快速开始

### 环境要求

- JDK 17+
- Maven 3.8+
- MySQL 8.0+
- Node.js 18+ (Web 前端)
- Flutter 3.x (移动端)

### 后端

```bash
cd rebuild-myself-server

# 1. 创建数据库
mysql -uroot -p -e "CREATE DATABASE rebuild_myself DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 2. 导入建表脚本
mysql -uroot -p rebuild_myself < src/main/resources/db/init.sql

# 3. 以 dev 配置启动（使用 application-dev.yml）
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# 或者打包后启动
mvn clean package -DskipTests
java -jar target/rebuild-myself-server-1.0.0.jar --spring.profiles.active=dev
```

> dev 配置默认 MySQL 用户名/密码为 `root/root`，请确保本地 MySQL 匹配或修改 `application-dev.yml`。

服务启动后访问 `http://localhost:8080`。

### Web 前端

```bash
cd rebuild-myself-web
npm install
npm run dev
```

### 生产环境部署

生产环境通过 **环境变量** 注入敏感配置（数据库密码、JWT 密钥、AI API Key），不会出现在配置文件默认值中。

```bash
export DB_USERNAME=your_db_user
export DB_PASSWORD=your_db_password
export JWT_SECRET=your_jwt_secret
export AI_API_KEY=your_deepseek_api_key
```

详细部署文档见 [DEPLOY.md](DEPLOY.md)。

## 配置说明

| 配置文件 | 用途 |
|----------|------|
| `application.yml` | 公共配置 |
| `application-dev.yml` | 本地开发环境 |
| `application-prod.yml` | 生产环境（通过环境变量注入敏感值） |

## 自动部署

push 到 `main` 分支时 GitHub Actions 自动构建并部署到阿里云。详见 `.github/workflows/deploy.yml`。

## License

MIT
