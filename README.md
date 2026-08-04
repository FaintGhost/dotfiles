# dotfiles

跨 Windows / Linux 的统一开发环境,由三层工具组成:

| 层 | 工具 | 职责 |
|---|---|---|
| 配置 | [chezmoi](https://chezmoi.io) | 管理 dotfile,模板按 OS 分支,autoCommit + autoPush |
| 工具链 | [mise](https://mise.jdx.dev) | 统一管理 go/node/python/rust/uv 等开发工具版本 |
| 秘密 | age + 1Password | SSH 私钥等加密存储在仓库,密钥存 1Password |

机器:Windows 本机 + kr-ts(Debian arm64,SSH 可达)。

## 新机器 bootstrap

```bash
# 1. 装 chezmoi 和 mise(可用各自官方脚本,装完后 chezmoi 本身不管自己)
# 2. 从 1Password 取出 age 私钥,放到 ~/.config/chezmoi/key.txt
# 3. 初始化并应用(会拉取本仓库、解密 age 文件、渲染模板)
chezmoi init --apply https://github.com/FaintGhost/dotfiles.git
# 4. 装全部开发工具
mise install
```

之后日常同步只需 `chezmoi update`(自动 commit + push)。

## 管理清单

| 文件 | 平台 | 说明 |
|---|---|---|
| `.config/mise/mise.toml` | 全平台 | 工具版本声明,herdr 仅非 Windows |
| `.ssh/config` + 私钥 | 全平台 | **age 加密**;kr/kr-ts 主机已合并进来 |
| `.config/starship.toml` | 全平台 | |
| `.gitconfig` | 全平台 | autocrlf 按 OS 分支 |
| PowerShell profile | 仅 Windows | `readonly_Documents/` |
| `.wslconfig` | 仅 Windows | |
| `.bashrc` / `.tmux.conf` / nvim | 仅 Linux | |

## 已知坑(改动前必读)

1. **改完模板两侧都要同步**:Windows 跑 `chezmoi apply --force <file>`,kr-ts 跑 `chezmoi update --force`。漏一边就会出现"一边好一边坏"。
2. **`.bashrc` 顺序不能重排**:可选工具 env(cargo/vite-plus/grok/kimi-code)→ `prepend_path mise shims`(永远最前)→ **starship init 必须在 PATH 装配之后**,否则 mise 版 starship 找不到、prompt 静默变裸。
3. **`mise.toml` 的 `[env] GOPATH` 必须用 TOML 单引号字面字符串**:双引号在 Windows 反斜杠路径上会转义爆炸。
4. **herdr 只对非 Windows 生效**:上游无 Windows release,mise 两个后端都仅 linux/darwin。Windows 的 herdr 是官方 install.ps1 独立装的,不受 mise 管。
5. **NetCatty(Windows SSH 客户端)不要开 .ssh/config 同步**:chezmoi 已收回该文件管理权,两边都写会冲突。
6. 交互确认一律用 `--force` 跳过;`chezmoi remove` 已废弃,用 `destroy --force`。
7. kr-ts 上验证 PATH 相关结果要用 `bash -ic 'which xxx'`(非交互 shell 不加载完整 bashrc)。

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
