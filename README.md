# dotfiles

跨 Windows / Linux / macOS 的统一开发环境,由三层工具组成:

| 层 | 工具 | 职责 |
|---|---|---|
| 配置 | [chezmoi](https://chezmoi.io) | 管理 dotfile,模板按 OS 分支,autoCommit + autoPush |
| 工具链 | [mise](https://mise.jdx.dev) | 统一管理 go/node/python/rust/uv 等开发工具版本 |
| 秘密 | age + 1Password | SSH 私钥等加密存储在仓库,密钥存 1Password |

机器:Windows 本机 + kr-ts(Debian arm64,SSH 可达)+ mac-mini(macOS arm64,SSH 可达)。

## 新机器 bootstrap

```bash
# 0. macOS 前置条件:先装 Xcode Command Line Tools(否则 /usr/bin/git 不可用)
#    xcode-select --install,或系统更新后按提示安装
# 1. 装 chezmoi 和 mise(可用各自官方脚本,装完后 chezmoi 本身不管自己)
# 2. 从 1Password 取出 age 私钥,放到 ~/.config/chezmoi/key/age.txt
# 3. 初始化并应用(会拉取本仓库、解密 age 文件、渲染模板)
chezmoi init --apply https://github.com/FaintGhost/dotfiles.git
# 4. 装全部开发工具
mise install
```

之后日常同步只需 `chezmoi update`(自动 commit + push)。

## 管理清单

| 文件 | 平台 | 说明 |
|---|---|---|
| `.config/mise/mise.toml` | 全平台 | 工具版本声明、全局工具自动更新及后台服务；设置统一的 `HERDR_CONFIG_PATH` |
| `.config/herdr/config.toml` | 全平台 | Herdr 通用配置；资源插件状态栏和快捷键仅 Linux 启用 |
| `.ssh/config` + 私钥 | 全平台 | **age 加密**;kr/kr-ts 主机已合并进来 |
| `.config/starship.toml` | 全平台 | |
| `.gitconfig` | 全平台 | autocrlf 按 OS 分支 |
| PowerShell profile | 仅 Windows | `readonly_Documents/` |
| `.wslconfig` | 仅 Windows | |
| `.bashrc` / `.tmux.conf` / nvim | Linux + macOS | |
| `.zshrc` | Linux + macOS | macOS 默认 shell 是 zsh,与 `.bashrc` 是兄弟文件,改动要两边同步 |

## 已知坑(改动前必读)

1. **改完模板两侧都要同步**:Windows 跑 `chezmoi apply --force <file>`,kr-ts 跑 `chezmoi update --force`。漏一边就会出现"一边好一边坏"。
2. **`.bashrc` / `.zshrc` 顺序不能重排**:可选工具 env(cargo/vite-plus/grok/kimi-code)→ `prepend_path mise shims`(永远最前)→ **starship init 必须在 PATH 装配之后**,否则 mise 版 starship 找不到、prompt 静默变裸。两个文件只有 guard、`cz` 里 source 的文件名和 `starship init` 的 shell 参数不同,其余内容必须保持一致。
3. **`mise.toml` 的 `[env] GOPATH` 必须用 TOML 单引号字面字符串**:双引号在 Windows 反斜杠路径上会转义爆炸。
4. **Herdr 全平台由 mise 管理**:当前官方稳定版提供 Linux/macOS/Windows 资产。mise 设置 `HERDR_CONFIG_PATH` 指向用户目录下的 `.config/herdr/config.toml`,Windows 也使用这份 chezmoi 配置。资源插件目前仅支持 Linux,命令从 `$HOME`/`XDG_CONFIG_HOME` 解析路径；没有安装插件时状态栏不输出。插件二进制、注册表和 session/state 不纳入 chezmoi。
5. **NetCatty(Windows SSH 客户端)不要开 .ssh/config 同步**:chezmoi 已收回该文件管理权,两边都写会冲突。
6. 交互确认一律用 `--force` 跳过;`chezmoi remove` 已废弃,用 `destroy --force`。
7. kr-ts 上验证 PATH 相关结果要用 `bash -ic 'which xxx'`(非交互 shell 不加载完整 bashrc);mac-mini 上用 `zsh -ic 'which xxx'`。
8. **mac-mini 上没有 Homebrew**:`.chezmoiscripts/` 里的系统包安装脚本仅 Linux 生效,macOS 的系统依赖靠 Xcode CLT 自带(git 等),其余开发工具一律走 mise。
9. **skills 不再由 mise/chezmoi 自动管理**:已移除 `skills-update` 任务、自动安装钩子、更新脚本和源清单；`.chezmoiremove` 会在其他机器下次 apply 时清除旧脚本和清单,保留已安装的 skills。

## 收编新工具的标准流程

```bash
mise search <名>            # 确认存在
mise registry <名>          # 看后端(第一位是默认)
mise ls-remote <名>         # 看可用版本
# 加进 dot_config/mise/mise.toml.tmpl → commit+push
chezmoi apply --force ~/.config/mise/mise.toml && mise install <名>   # Windows
ssh kr-ts "chezmoi update --force && mise install <名>"               # kr-ts
# 清理旧的独立安装来源(winget/apt/rustup/官方脚本)
```

## 日常维护

```bash
mise run update    # = mise upgrade,升级全部工具
mise prune         # 清理旧版本
chezmoi update     # 同步配置(双侧)
```

mise 需要 **2026.10.4 或更高版本**。全局工具声明启用 `auto_update = true`：`latest` 跟随最新版本,包括 `npm:@zvec/zvec-grep`；`go = "1.26"`、`node = "24"` 等仅在声明范围内更新。

各平台 `chezmoi update`/`apply` 后会执行 `mise bootstrap services apply --yes`,安装并启动 `mise-tool-update` 后台服务。服务每小时扫描一次,各工具默认每 24 小时检查更新；分别使用 Linux systemd 用户服务、macOS LaunchAgent、Windows 计划任务。已替代原来的每次同步执行 `mise upgrade` 钩子；此配置只自动更新工具,不设置 mise 自身的自动更新。Linux 需要可用的 systemd 用户管理器。

```bash
mise bootstrap services status  # 检查后台服务是否运行
```
