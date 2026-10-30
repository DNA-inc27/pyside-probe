# LGNS Claimer · 构建说明（给非程序员）

按顺序做三件事，全程不用敲命令。

## 第一步：解压

把收到的 `LGNS-Claimer-build-kit-v1.0.0.zip` 右键 →「全部解压缩」，
得到一个 `dist-kit` 文件夹（**不要**在压缩包里直接双击，容易失败）。

> 建议解压到 `D:\LGNS` 这类简单路径，**不要**放在中文或带空格的深层目录，
> 也不要放在 OneDrive 同步目录里（会锁文件）。

## 第二步：双击 `build.bat`

窗口会自己跑，显示 1/6 … 6/6 的中文进度：

| 步骤 | 在做什么 | 大概耗时 |
|---|---|---|
| 1 | 检查系统是不是 64 位 Windows | 1 秒 |
| 2 | 找工作电脑里有没有 Python（没有会自动装） | 0 秒 / 1~3 分钟 |
| 3 | 建独立环境 `.venv` | 10 秒 |
| 4 | 联网下载依赖（PySide6 约 100MB） | 1~5 分钟 |
| 5 | 打包成单文件 exe | 1~3 分钟 |
| 6 | 改名 + 校验 | 2 秒 |

**跑到一半不要关窗口。** 中途想取消，按 `Ctrl+C` 后重来即可（可重复执行）。

## 第三步：去 `dist` 拿 exe

成功后窗口会提示「打包成功」，并自动打开 `dist` 文件夹，
里面是：

```
LGNS-Claimer-v1.0.0-win64.exe   （约 45MB，双击即可运行）
```

发送给别人：**只发这一个 exe**，不需要发整个文件夹。

---

## 遇到问题

| 现象 | 原因 | 怎么办 |
|---|---|---|
| 进度 4/6 卡住、报 `ConnectionError` / `Read timed out` | 网络或代理挡住了 PyPI | 关掉 VPN/公司代理；或连手机热点重试；脚本已优先用清华镜像，失败会自动换官方源 |
| 双击 `build.bat` 一闪就没了 | 系统策略拦截脚本 | 右键 →「以管理员身份运行」；仍不行则把 `build.log` 发回来 |
| 杀毒软件弹窗/直接把 exe 删了 | PyInstaller 打包的程序常被误报（启发式） | 在杀软里把 `dist` 文件夹加入信任/白名单，然后重跑；exe 是从源码本机生成的，没有下载外部程序 |
| 运行 exe 提示缺少 `VCRUNTIME140.dll` / `MSVCP140.dll` | 缺 VC++ 运行库 | 装微软官方 `vc_redist.x64.exe`（https://aka.ms/vs/17/release/vc_redist.x64.exe），装完直接双击 exe |
| 提示「Windows 已保护你的电脑」（SmartScreen） | exe 未做代码签名 | 点「更多信息」→「仍要运行」；这是首次运行的正常提示，不是中毒 |
| 报「磁盘空间不足」 | 构建临时文件约需 1.5~2GB | 清空回收站、删掉旧的 `build` / `.venv` 后重试；或换到空间大的盘再解压 |
| 2/6 提示没有 Python 且 winget 装不上 | 公司电脑禁用 winget | 手动去 https://www.python.org/downloads/windows/ 下 3.12，安装时**勾选 Add python.exe to PATH**，装完重启再双击 `build.bat` |
| 中文显示成乱码 | 旧版终端编码问题 | 在窗口里先执行 `chcp 65001` 再跑；或直接看 `build.log`（UTF-8 编码） |
| 打包成功但 exe 双击没反应 | 被安全软件静默拦截 | 看杀软隔离区并恢复；或换一台电脑试 |

任何失败：**把整个 `build.log` 发回来**，里面有每一步的详细输出。

## 包里有什么

```
dist-kit/
├─ build.bat              ← 双击这个
├─ README-构建.md          ← 本文件
├─ app/main.py            ← 程序源码（RPC 地址可在界面里改）
├─ requirements.txt       ← 锁定版本：PySide6 6.7.3 / PyInstaller 6.11.1
├─ LGNS-Claimer.spec      ← PyInstaller 配置（单文件、无控制台）
├─ version_info.txt       ← exe 属性里的版本号 1.0.0
├─ icon.ico               ← 占位图标（可替换）
└─ 免责声明.txt            ← 使用前请读
```

## 已知边界

- 本包只验证「能打出可运行的 GUI exe」，领取逻辑尚未接入。
- 构建需要联网；不内置 wheels（体积控制），首次构建下载约 150MB。
- 产物未签名（见 README 上表 SmartScreen 一行）。