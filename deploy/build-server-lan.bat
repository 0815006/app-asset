@echo off
chcp 65001 >nul 2>&1
title 🔨 构建 Asset Server → Linux 部署
setlocal enabledelayedexpansion

echo ==================================================
echo   🔨 构建 Asset 后端 Server Linux 部署版本
echo ==================================================
echo.

:: ========== 📌 Linux 部署环境变量（与 deploy/application.yml 中的 ${VAR:default} 对应）==========
:: 修改此处变量即可控制部署参数，start.sh 会在启动时 export 这些变量
set "SERVER_PORT=8095"
set "DB_HOST=22.188.9.16"
set "DB_PORT=3306"
set "DB_NAME=asset_db"
set "DB_USER=td"
set "DB_PASSWORD=Mtx0422!"
set "REDIS_HOST=22.188.9.16"
set "REDIS_PORT=6379"
set "REDIS_ENABLED=false"
set "SOLR_HOST=http://22.188.9.16:8983/solr"
set "FILE_UPLOAD_DIR=/data/webfiles/asset/asset_files"
set "FILE_RECYCLE_DIR=/data/webfiles/asset/asset_recycle_bin"
set "FILE_MAX_SIZE=100MB"
set "AUTH_VERIFY_INTERNAL=true"
set "AUTH_TOKEN_EXPIRATION=48"
set "AUTH_SECRET_KEY=asset-management-secret-key-2026"
set "AUTH_USER_SOURCE=sys"
set "AUTH_AES_KEY=ihaierForTodoKey"
set "AUTH_AES_IV=ihaierForTodo_Iv"
set "DEPLOY_DIR=/app/asset-server"
set "JAVA_OPTS=-Xms512m -Xmx1024m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
:: ==========================================================================================

:: 切到项目根目录
set "PROJECT_ROOT=%~dp0.."
cd /d "%PROJECT_ROOT%"
if %errorlevel% neq 0 (
    echo ❌ 无法进入项目根目录！
    pause
    exit /b 1
)
echo 📁 项目根目录: %cd%
echo.

:: ========== Step 1: 校验项目文件 ==========
echo [1/6] 📋 校验项目文件...
if not exist "java-asset-server\pom.xml" (
    echo ❌ 未找到 java-asset-server\pom.xml！
    pause
    exit /b 1
)
if not exist "deploy\application.yml" (
    echo ❌ 未找到 deploy\application.yml！
    pause
    exit /b 1
)
echo ✅ 项目文件就绪
echo.

echo 📌 Linux 部署参数 ^(与 deploy/application.yml ^$^{VAR:default} 对应^):
echo    SERVER_PORT        = %SERVER_PORT%
echo    DB_HOST:DB_PORT    = %DB_HOST%:%DB_PORT%
echo    DB_NAME            = %DB_NAME%
echo    DB_USER            = %DB_USER%
echo    DB_PASSWORD        = ****
echo    REDIS_HOST:PORT    = %REDIS_HOST%:%REDIS_PORT% (enabled=%REDIS_ENABLED%)
echo    SOLR_HOST          = %SOLR_HOST%
echo    FILE_UPLOAD_DIR    = %FILE_UPLOAD_DIR%
echo    FILE_RECYCLE_DIR   = %FILE_RECYCLE_DIR%
echo    FILE_MAX_SIZE      = %FILE_MAX_SIZE%
echo    DEPLOY_DIR         = %DEPLOY_DIR%
echo.

:: ========== Step 2: Maven 编译打包 ==========
echo [2/6] ⚡ Maven 编译打包（跳过测试）...
echo.

cd /d "%PROJECT_ROOT%\java-asset-server"

echo   执行: mvn clean package -Dmaven.test.skip=true
echo.
call mvn clean package -Dmaven.test.skip=true
set BUILD_RESULT=%errorlevel%

if %BUILD_RESULT% neq 0 (
    echo.
    echo ❌ Maven 编译失败！请检查 Java 8 环境和 Maven 配置。
    cd /d "%PROJECT_ROOT%"
    pause
    exit /b 1
)
echo.
echo ✅ Maven 编译完成
echo.

:: ========== Step 3: 复制 JAR 到输出目录 ==========
echo [3/6] 📦 复制 JAR 到 bin\asset-server\ ...

set "OUT_DIR=%PROJECT_ROOT%\bin\asset-server"
set "JAR_SRC=%PROJECT_ROOT%\java-asset-server\target\java-asset-server-0.0.1-SNAPSHOT.jar"
set "JAR_DST=%OUT_DIR%\asset-server.jar"

if not exist "%JAR_SRC%" (
    echo ❌ 未找到编译产物 %JAR_SRC%
    cd /d "%PROJECT_ROOT%"
    pause
    exit /b 1
)

:: 清理并创建输出目录
if exist "%OUT_DIR%" rmdir /s /q "%OUT_DIR%"
mkdir "%OUT_DIR%" >nul 2>&1

copy /y "%JAR_SRC%" "%JAR_DST%" >nul
echo   %JAR_SRC%
echo   → %JAR_DST%
echo.

:: ========== Step 4: 复制 deploy/application.yml 到 config/ ==========
echo [4/6] 📋 复制 deploy/application.yml → config/application.yml ...

set "CONFIG_DIR=%OUT_DIR%\config"
mkdir "%CONFIG_DIR%" >nul 2>&1

copy /y "%PROJECT_ROOT%\deploy\application.yml" "%CONFIG_DIR%\application.yml" >nul
echo   deploy\application.yml
echo   → %CONFIG_DIR%\application.yml
echo   ✅ 配置文件已复制 (使用 ${VAR:default} 参数模式，由环境变量注入^)
echo.

:: ========== Step 5: 生成 Linux 启停脚本 ==========
echo [5/6] 📝 生成 Linux 启停脚本...

:: ---- asset-server.sh (启停管理) ----
(
echo #!/bin/bash
echo # ==============================================================================
echo # Asset Server 启停管理脚本 ^(Linux^)
echo # 部署目录: %DEPLOY_DIR%
echo # 所有环境变量在启动时注入，与 config/application.yml 的 ${VAR:default} 对应
echo # ==============================================================================
echo.
echo APP_NAME="asset-server.jar"
echo JAR_PATH="./${APP_NAME}"
echo JAVA_OPTS="%JAVA_OPTS%"
echo.
echo # ========== 环境变量注入 ==========
echo export SERVER_PORT=%SERVER_PORT%
echo export DB_HOST=%DB_HOST%
echo export DB_PORT=%DB_PORT%
echo export DB_NAME=%DB_NAME%
echo export DB_USER=%DB_USER%
echo export DB_PASSWORD=%DB_PASSWORD%
echo export REDIS_HOST=%REDIS_HOST%
echo export REDIS_PORT=%REDIS_PORT%
echo export REDIS_ENABLED=%REDIS_ENABLED%
echo export SOLR_HOST=%SOLR_HOST%
echo export FILE_UPLOAD_DIR=%FILE_UPLOAD_DIR%
echo export FILE_RECYCLE_DIR=%FILE_RECYCLE_DIR%
echo export FILE_MAX_SIZE=%FILE_MAX_SIZE%
echo export AUTH_VERIFY_INTERNAL=%AUTH_VERIFY_INTERNAL%
echo export AUTH_TOKEN_EXPIRATION=%AUTH_TOKEN_EXPIRATION%
echo export AUTH_SECRET_KEY=%AUTH_SECRET_KEY%
echo export AUTH_USER_SOURCE=%AUTH_USER_SOURCE%
echo export AUTH_AES_KEY=%AUTH_AES_KEY%
echo export AUTH_AES_IV=%AUTH_AES_IV%
echo.
echo # ========== 函数定义 ==========
echo is_exist^(^) {
echo     pid=`ps -ef ^| grep $APP_NAME ^| grep -v grep ^| awk '{print $2}'`
echo     if [ -z "${pid}" ]; then
echo         return 1
echo     else
echo         return 0
echo     fi
echo }
echo.
echo start^(^) {
echo     is_exist
echo     if [ $? -eq 0 ]; then
echo         echo "${APP_NAME} is already running. pid=${pid}"
echo     else
echo         if [ ! -f "$JAR_PATH" ]; then
echo             echo "Error: JAR file not found at $JAR_PATH"
echo             exit 1
echo         fi
echo         echo "Starting ${APP_NAME}..."
echo         nohup java $JAVA_OPTS -jar $JAR_PATH ^> app.log 2^>^&1 ^&
echo         sleep 3
echo         is_exist
echo         if [ $? -eq 0 ]; then
echo             echo "${APP_NAME} started successfully. pid=${pid}"
echo             echo "Logs: tail -f app.log"
echo         else
echo             echo "❌ ${APP_NAME} failed to start! Check app.log for details."
echo         fi
echo     fi
echo }
echo.
echo stop^(^) {
echo     is_exist
echo     if [ $? -eq 0 ]; then
echo         echo "Stopping ${APP_NAME} (pid=${pid})..."
echo         kill $pid
echo         sleep 2
echo         is_exist
echo         if [ $? -eq 0 ]; then
echo             echo "Force killing ${APP_NAME}..."
echo             kill -9 $pid
echo         fi
echo         echo "${APP_NAME} stopped."
echo     else
echo         echo "${APP_NAME} is not running."
echo     fi
echo }
echo.
echo status^(^) {
echo     is_exist
echo     if [ $? -eq 0 ]; then
echo         echo "${APP_NAME} is running. pid=${pid}"
echo     else
echo         echo "${APP_NAME} is NOT running."
echo     fi
echo }
echo.
echo restart^(^) {
echo     stop
echo     sleep 2
echo     start
echo }
echo.
echo case "$1" in
echo     start^)
echo         start
echo         ;;
echo     stop^)
echo         stop
echo         ;;
echo     status^)
echo         status
echo         ;;
echo     restart^)
echo         restart
echo         ;;
echo     *^)
echo         echo "Usage: sh asset-server.sh {start|stop|restart|status}"
echo         echo "Default: start"
echo         start
echo         ;;
echo esac
) > "%OUT_DIR%\asset-server.sh"

:: ---- deploy.sh (首次部署辅助) ----
(
echo #!/bin/bash
echo # ==============================================================================
echo # Asset Server 首次部署辅助脚本 ^(Linux^)
echo # 用法:
echo #   1. 将 bin/asset-server/ 下所有文件上传到 %DEPLOY_DIR%/
echo #   2. cd %DEPLOY_DIR% ^&^& chmod +x deploy.sh ^&^& ./deploy.sh
echo # ==============================================================================
echo.
echo set -e
echo.
echo echo "========================================"
echo echo "  🚀 Asset Server 首次部署"
echo echo "========================================"
echo echo ""
echo.
echo # 1. 创建数据目录
echo echo "[1/5] 创建数据目录..."
echo mkdir -p %FILE_UPLOAD_DIR%
echo mkdir -p %FILE_RECYCLE_DIR%
echo echo "  ✅ %FILE_UPLOAD_DIR%"
echo echo "  ✅ %FILE_RECYCLE_DIR%"
echo echo ""
echo.
echo # 2. 赋予脚本执行权限
echo echo "[2/5] 设置脚本权限..."
echo chmod +x asset-server.sh
echo echo "  ✅ asset-server.sh"
echo echo ""
echo.
echo # 3. 检查 Java 环境
echo echo "[3/5] 检查 Java 环境..."
echo if command -v java ^> /dev/null 2^>^&1; then
echo     echo "  ✅ Java: $(java -version 2^>^&1 ^| head -1^)"
echo else
echo     echo "  ❌ 未找到 Java！请先安装 JDK 8+"
echo     exit 1
echo fi
echo echo ""
echo.
echo # 4. 检查配置文件
echo echo "[4/5] 检查配置文件..."
echo if [ -f "./config/application.yml" ]; then
echo     echo "  ✅ config/application.yml 就绪"
echo     echo "  💡 所有参数均通过 asset-server.sh 中的环境变量注入"
echo     echo "  💡 如需修改参数，编辑 asset-server.sh 中的 export 语句即可"
echo else
echo     echo "  ❌ 未找到 config/application.yml！请确保已将文件完整上传。"
echo     exit 1
echo fi
echo echo ""
echo.
echo # 5. 启动服务
echo echo "[5/5] 启动 Asset Server..."
echo ./asset-server.sh start
echo echo ""
echo.
echo echo "========================================"
echo echo "  ✅ Asset Server 部署完成"
echo echo "========================================"
echo echo "  端口: %SERVER_PORT%"
echo echo "  日志: tail -f %DEPLOY_DIR%/app.log"
echo echo "  管理: cd %DEPLOY_DIR% ^&^& ./asset-server.sh {start|stop|restart|status}"
echo echo "========================================"
) > "%OUT_DIR%\deploy.sh"

rem ---- CRLF → LF 转换（Windows 生成的 sh 脚本在 Linux 上会出现 ^M） ----
echo   🔄 转换换行符 CRLF → LF ...
for %%f in ("%OUT_DIR%\asset-server.sh" "%OUT_DIR%\deploy.sh") do (
    powershell -NoProfile -Command ^
        "$content = Get-Content -Path '%%~f' -Raw; $content = $content -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText('%%~f', $content, [System.Text.UTF8Encoding]::new($false))"
    if !errorlevel! neq 0 (
        echo   ⚠ 换行符转换失败: %%~nxf ，请手动 dos2unix 处理
    ) else (
        echo   ✅ %%~nxf 已转换为 LF
    )
)

echo   ✅ asset-server.sh / deploy.sh 已生成
echo.

:: ========== Step 6: 校验输出 ==========
echo [6/6] ✅ 校验输出产物...
echo.
echo ==================================================
echo   🏁  构建完成！Linux 后端 Server 版本
echo ==================================================
echo.
echo   📌 构建产物目录: %OUT_DIR%\
dir /b "%OUT_DIR%"
echo.
echo   📁 目录结构:
echo       %OUT_DIR%\
echo         ├── asset-server.jar          (Spring Boot JAR^)
echo         ├── asset-server.sh           (启停管理: start^|stop^|restart^|status^)
echo         ├── deploy.sh                 (首次部署辅助^)
echo         └── config\
echo             └── application.yml       (参数模式 ${VAR:default}，由环境变量注入^)
echo.
echo   📌 Linux 服务器部署步骤:
echo       1. 将 bin\asset-server\ 下所有文件上传到 %DEPLOY_DIR%/
echo       2. ssh 到服务器: cd %DEPLOY_DIR%
echo       3. chmod +x deploy.sh ^&^& ./deploy.sh
echo       4. 验证: curl http://localhost:%SERVER_PORT%/api/health
echo.
echo   💡 修改参数:
echo       - 编辑本 bat 头部 set 变量 → 重新构建
echo       - 或直接在服务器上编辑 asset-server.sh 中的 export 语句
echo   💡 手动运行: java -jar asset-server.jar
echo   💡 查看日志: tail -f %DEPLOY_DIR%/app.log
echo ==================================================
echo.

cd /d "%PROJECT_ROOT%"
pause
exit /b 0
