# 日新 — 阿里云部署文档

- 服务器: **47.92.98.182**
- JAR: `rebuild-myself-server/target/rebuild-myself-server-1.0.0.jar` (31MB)

---

## 1. SSH 连接

```bash
ssh root@47.92.98.182
```

## 2. 安装 Java 21

```bash
yum install -y java-21-openjdk java-21-openjdk-devel
java -version
```

## 3. 安装 MySQL + 初始化

```bash
yum install -y mysql-server
systemctl start mysqld && systemctl enable mysqld
grep 'temporary password' /var/log/mysqld.log
```

用临时密码登录：
```bash
mysql -uroot -p
```

MySQL 中执行：
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourStrongPassword!';
CREATE DATABASE rebuild_myself DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'rebuild'@'localhost' IDENTIFIED BY 'YOUR_DB_PASSWORD';
GRANT ALL ON rebuild_myself.* TO 'rebuild'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

导入建表脚本（先在本地上传文件）：
```powershell
# Windows PowerShell 新窗口
scp E:\code\project\mycode\claudecode\rebuildmyself\rebuild-myself-server\src\main\resources\db\init.sql root@47.92.98.182:/tmp/
```

回到服务器：
```bash
mysql -uroot -p'YOUR_ROOT_PASSWORD' rebuild_myself < /tmp/init.sql
```

## 4. 创建目录 + 环境变量

```bash
mkdir -p /data/rebuild-myself/{logs,uploads}

cat > /data/rebuild-myself/env.sh << 'EOF'
export DB_USERNAME=rebuild
export DB_PASSWORD=YOUR_DB_PASSWORD
export JWT_SECRET=YOUR_JWT_SECRET
export AI_API_KEY=YOUR_DEEPSEEK_API_KEY
EOF
```

## 5. 上传 JAR

```powershell
# Windows PowerShell 新窗口
scp E:\code\project\mycode\claudecode\rebuildmyself\rebuild-myself-server\target\rebuild-myself-server-1.0.0.jar root@47.92.98.182:/data/rebuild-myself/
```

## 6. 创建 systemd 服务

```bash
cat > /etc/systemd/system/rebuild-myself.service << 'EOF'
[Unit]
Description=日新 — 全维度人生重塑
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/data/rebuild-myself
EnvironmentFile=/data/rebuild-myself/env.sh
ExecStart=/usr/bin/java -jar /data/rebuild-myself/rebuild-myself-server-1.0.0.jar --spring.profiles.active=prod
Restart=on-failure
RestartSec=10
StandardOutput=append:/data/rebuild-myself/logs/stdout.log
StandardError=append:/data/rebuild-myself/logs/stderr.log

[Install]
WantedBy=multi-user.target
EOF
```

## 7. 开放端口

```bash
firewall-cmd --add-port=8080/tcp --permanent && firewall-cmd --reload
```

> **别忘了**: 阿里云控制台 → ECS → 安全组 → 入方向 → 放行 TCP 8080

## 8. 启动

```bash
systemctl daemon-reload
systemctl enable rebuild-myself
systemctl start rebuild-myself

# 检查
systemctl status rebuild-myself
curl http://localhost:8080/index.html | head -5
```

## 9. 访问

`http://47.92.98.182:8080`

---

## 配置文件说明

| 文件 | 用途 |
|------|------|
| `application.yml` | 公共配置 |
| `application-dev.yml` | 本地开发（root/root, SQL日志） |
| `application-prod.yml` | 生产环境（环境变量, 无SQL日志） |

## 启动/重启/停止

```bash
systemctl start rebuild-myself    # 启动
systemctl restart rebuild-myself  # 重启
systemctl stop rebuild-myself     # 停止
systemctl status rebuild-myself   # 状态
tail -f /data/rebuild-myself/logs/stdout.log  # 查看日志
```
