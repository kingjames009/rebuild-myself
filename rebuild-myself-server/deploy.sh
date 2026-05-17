#!/bin/bash
# ============================================================
# 日新 — 阿里云部署脚本
# 用法: ./deploy.sh <服务器IP>
# 示例: ./deploy.sh 47.96.xxx.xxx
# ============================================================
set -e

SERVER_IP="${1:?请提供服务器IP，如: ./deploy.sh 47.96.xxx.xxx}"
SERVER_USER="root"
REMOTE_DIR="/data/rebuild-myself"
APP_NAME="rebuild-myself-server"

echo ">>> 1. 本地构建 JAR..."
cd "$(dirname "$0")"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21}"
mvn -q -DskipTests clean package -Pprod

echo ">>> 2. 上传 JAR 到服务器..."
ssh ${SERVER_USER}@${SERVER_IP} "mkdir -p ${REMOTE_DIR}"
scp target/${APP_NAME}-1.0.0.jar ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/

echo ">>> 3. 上传配置..."
scp deploy/systemd/rebuild-myself.service ${SERVER_USER}@${SERVER_IP}:/etc/systemd/system/
scp deploy/env.sh ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/

echo ">>> 4. 重启服务..."
ssh ${SERVER_USER}@${SERVER_IP} << 'REMOTE_CMD'
  systemctl daemon-reload
  systemctl enable rebuild-myself
  systemctl restart rebuild-myself
  sleep 3
  systemctl status rebuild-myself --no-pager
  echo ""
  echo ">>> 服务状态检查..."
  curl -s http://localhost:8080/index.html | head -3
REMOTE_CMD

echo ""
echo ">>> 部署完成! 访问 http://${SERVER_IP}:8080"
