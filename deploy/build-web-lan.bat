@echo off
chcp 65001 >nul 2>&1
title 🔨 构建 Asset Web → Linux 部署
setlocal

echo ==================================================
echo   🔨 构建 Asset 前端 Web Linux 部署版本
echo ==================================================
echo.

:: ========== 📌 Linux 部署参数（按实际环境修改） ==========
set "ONLYOFFICE_API=http://22.188.9.16:9010/web-apps/apps/api/documents/api.js"
:: ===========================================================

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
echo [1/5] 📋 校验项目文件...
if not exist "web-asset-vue\package.json" (
    echo ❌ 未找到 web-asset-vue\package.json！
    pause
    exit /b 1
)
echo ✅ 项目文件就绪
echo.

echo 📌 Linux 部署参数:
echo    OnlyOffice: %ONLYOFFICE_API%
echo.

:: ========== Step 2: 生成 .env 文件 ==========
echo [2/5] ⚙️  生成 .env 文件（OnlyOffice 地址）...

cd /d "%PROJECT_ROOT%\web-asset-vue"

(
echo # ===================================================================
echo # 环境变量 — 由 build-web-lan.bat 自动生成
echo # ===================================================================
echo VUE_APP_ONLYOFFICE_API=%ONLYOFFICE_API%
) > ".env"

echo ✅ .env 已生成
echo.

:: ========== Step 3: npm 编译打包 ==========
echo [3/5] ⚡ Vue CLI 生产环境打包...
echo   执行: npm run build
echo.

:: 检查 node_modules
if not exist "node_modules" (
    echo ⚠️  未找到 node_modules，正在执行 npm install...
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ npm install 失败！
        cd /d "%PROJECT_ROOT%"
        pause
        exit /b 1
    )
    echo ✅ npm install 完成
    echo.
)

call npm run build
set BUILD_RESULT=%errorlevel%

if %BUILD_RESULT% neq 0 (
    echo.
    echo ❌ 前端打包失败！请检查 Node.js 环境和依赖。
    cd /d "%PROJECT_ROOT%"
    pause
    exit /b 1
)
echo.
echo ✅ Vue CLI 打包完成
echo.

:: ========== Step 4: 复制 dist 到 bin\asset-web ==========
echo [4/5] 📦 复制 dist 产物到 bin\asset-web\ ...

set "DIST_SRC=%PROJECT_ROOT%\web-asset-vue\dist"
set "WEB_OUT=%PROJECT_ROOT%\bin\asset-web"

if not exist "%DIST_SRC%" (
    echo ❌ 未找到打包产物 %DIST_SRC%
    cd /d "%PROJECT_ROOT%"
    pause
    exit /b 1
)

:: 清理并创建输出目录
if exist "%WEB_OUT%" rmdir /s /q "%WEB_OUT%"
mkdir "%WEB_OUT%" >nul 2>&1

xcopy /e /y "%DIST_SRC%\*" "%WEB_OUT%\" >nul
echo   %DIST_SRC%\*
echo   → %WEB_OUT%\
echo.

:: ========== Step 5: 清理 .env 文件 ==========
echo [5/5] 🧹 清理临时 .env 文件...
del /q "%PROJECT_ROOT%\web-asset-vue\.env" >nul 2>&1
echo ✅ 已清理
echo.

:: ========== 输出完成信息 ==========
echo ==================================================
echo   🏁  构建完成！Linux 前端 Web 版本
echo ==================================================
echo.
echo   📌 构建产物目录: %WEB_OUT%\
dir /b "%WEB_OUT%"
echo.
echo   📌 Linux 服务器部署步骤:
echo       1. 将 bin\asset-web\ 下所有文件上传到:
echo          /app/asset-web/
echo       2. Nginx 配置参考: deploy\nginx-asset-lan.conf
echo          (放入 /usr/local/nginx/conf/conf.d/ 并 nginx -s reload^)
echo.
echo   💡 OnlyOffice 地址已写入: %ONLYOFFICE_API%
echo   💡 重新构建: 修改本 bat 头部参数，重新运行即可
echo ==================================================
echo.

cd /d "%PROJECT_ROOT%"
pause
exit /b 0
