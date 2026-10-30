@echo off
chcp 65001 >nul
setlocal EnableExtensions
cd /d "%~dp0"
set "LOG=%~dp0build.log"
set "PYTHONUTF8=1"
title LGNS Claimer 打包工具

call :say "=================================================="
call :say "  LGNS Claimer 打包工具（生成 Windows 单文件 exe）"
call :say "  全程 3~10 分钟，取决于网速，请勿关闭本窗口"
call :say "=================================================="
call :say "日志会同时写入 build.log"

call :say ""
call :say "[1/6] 检查 Windows 版本……"
if not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    call :say "  这不是 64 位 Windows，无法生成 win64 exe。"
    goto :fail
)
call :say "  OK：%OS% 64 位"

call :say ""
call :say "[2/6] 查找 Python 3.10 以上……"
set "PY="
py -3 -c "import sys;raise SystemExit(0 if sys.version_info>=(3,10) else 1)" >nul 2>&1 && set "PY=py -3"
if not defined PY (
    python -c "import sys;raise SystemExit(0 if sys.version_info>=(3,10) else 1)" >nul 2>&1 && set "PY=python"
)
if not defined PY (
    call :say "  没有找到可用的 Python，尝试用 winget 自动安装（约 1~3 分钟）……"
    where winget >nul 2>&1 || (
        call :say "  这台电脑没有 winget，无法自动安装。"
        call :say "  请手动安装 Python 3.12（勾选 Add python.exe to PATH）：https://www.python.org/downloads/windows/"
        goto :fail
    )
    winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements >>"%LOG%" 2>&1
    py -3 -c "import sys;raise SystemExit(0 if sys.version_info>=(3,10) else 1)" >nul 2>&1 && set "PY=py -3"
    if not defined PY (
        if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PY=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    )
)
if not defined PY (
    call :say "  Python 仍然不可用。请重启电脑后再双击 build.bat；或手动安装 Python 后重试。"
    goto :fail
)
for /f "delims=" %%v in ('%PY% -c "import sys;print(sys.version.split()[0])"') do set "PYVER=%%v"
call :say "  OK：Python %PYVER%"

call :say ""
call :say "[3/6] 创建独立环境 .venv（不污染系统 Python）……"
if not exist ".venv\Scripts\python.exe" (
    %PY% -m venv .venv >>"%LOG%" 2>&1
    if errorlevel 1 (
        call :say "  创建虚拟环境失败，常见原因：Python 安装不完整或目录无写权限。"
        goto :fail
    )
) else (
    call :say "  已存在，复用。"
)
call :say "  OK：.venv 就绪"

call :say ""
call :say "[4/6] 安装打包依赖（PySide6 约 100MB，首次较慢）……"
.venv\Scripts\python.exe -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple >>"%LOG%" 2>&1
.venv\Scripts\python.exe -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple >>"%LOG%" 2>&1
if errorlevel 1 (
    call :say "  镜像源失败，改用官方源重试……"
    .venv\Scripts\python.exe -m pip install -r requirements.txt >>"%LOG%" 2>&1
    if errorlevel 1 (
        call :say "  依赖安装失败：请检查网络/代理（公司电脑常需要关代理或用手机热点）。"
        goto :fail
    )
)
call :say "  OK：依赖安装完成"

call :say ""
call :say "[5/6] 正在打包 exe（约 1~3 分钟，窗口会安静一阵）……"
if exist "dist" rmdir /s /q "dist"
if exist "build" rmdir /s /q "build"
.venv\Scripts\python.exe -m PyInstaller --noconfirm --clean LGNS-Claimer.spec >>"%LOG%" 2>&1
if errorlevel 1 (
    call :say "  打包失败，日志末尾如下："
    powershell -NoProfile -Command "Get-Content -Path '%LOG%' -Tail 15" 2>nul
    goto :fail
)
if not exist "dist\LGNS-Claimer.exe" (
    call :say "  打包命令跑完了但没有找到 exe，日志末尾："
    powershell -NoProfile -Command "Get-Content -Path '%LOG%' -Tail 15" 2>nul
    goto :fail
)

call :say ""
call :say "[6/6] 重命名并校验产物……"
set "OUT=dist\LGNS-Claimer-v1.0.0-win64.exe"
if exist "%OUT%" del /q "%OUT%"
move /y "dist\LGNS-Claimer.exe" "%OUT%" >>"%LOG%" 2>&1
if not exist "%OUT%" (
    call :say "  重命名失败。"
    goto :fail
)
for %%f in ("%OUT%") do set "SIZE=%%~zf"
set /a SIZEMB=%SIZE%/1048576
call :say "  OK：%OUT%（约 %SIZEMB%MB）"

call :say ""
call :say "=================================================="
call :say "  打包成功！"
call :say "  文件位置：%~dp0%OUT%"
call :say "  双击这个 exe 就能运行；发给别人只需要这一个文件。"
call :say "=================================================="
start "" explorer "%~dp0dist"
if /I "%CI%"=="true" goto :done
pause
goto :done

:fail
call :say ""
call :say "=================================================="
call :say "  打包没有完成。请把 build.log 整个文件发回来。"
call :say "  常见对照表见 README-构建.md 的「遇到问题」一节。"
call :say "=================================================="
if /I "%CI%"=="true" exit /b 1
pause
exit /b 1

:done
endlocal
exit /b 0

:say
echo %~1
>>"%LOG%" echo [%TIME%] %~1
goto :eof