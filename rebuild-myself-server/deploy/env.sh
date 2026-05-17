# ============================================================
# 日新 — 生产环境变量
# 部署到服务器后请修改以下值:
#   /data/rebuild-myself/env.sh
# ============================================================

# 数据库（MySQL 账号密码）
export DB_USERNAME=rebuild
export DB_PASSWORD=ChangeMe123!

# JWT 密钥（请用随机字符串替换，至少32字符）
export JWT_SECRET=ChangeMeToARandomStringAtLeast32Characters

# DeepSeek AI 密钥
export AI_API_KEY=sk-your-deepseek-api-key
