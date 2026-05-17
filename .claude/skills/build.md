---
name: build
description: 一键构建 Flutter APK 和服务端 JAR
---

# /build — 一键打包

同时构建 Flutter APK 和服务端 JAR，完成后输出产物路径和大小。

## 执行步骤

1. **编译服务端 JAR**（后台运行）
   ```bash
   export JAVA_HOME="D:/Program Files/Java/jdk-21"
   export PATH="$JAVA_HOME/bin:$PATH"
   cd E:\code\project\mycode\claudecode\rebuildmyself\rebuild-myself-server
   mvn package -DskipTests -q
   ```

2. **编译 Flutter APK**（后台运行）
   ```bash
   export JAVA_HOME="D:/Program Files/Java/jdk-21"
   export PATH="$JAVA_HOME/bin:$PATH"
   cd E:\code\project\mycode\claudecode\rebuildmyself\rebuild-myself-flutter
   flutter build apk --release
   ```

3. 两个都完成后，汇总输出：
   - APK 路径：`flutter/build/app/outputs/flutter-apk/app-release.apk` 及其大小
   - JAR 路径：`server/target/` 下的 jar 文件名

## 注意
- 两个构建**并行**执行（互不依赖），每个超时 10 分钟
- JDK 路径使用 `D:/Program Files/Java/jdk-21`
- Flutter 构建不加 `--no-tree-shake-icons`
