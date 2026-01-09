# Chezmoi Dotfiles 配置

> 使用 [Chezmoi](https://www.chezmoi.io/) 管理的跨平台 dotfiles 配置，支持 Linux、macOS 和 Windows。

## 📋 目录

- [特性](#特性)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [配置说明](#配置说明)
- [常用命令](#常用命令)
- [自定义配置](#自定义配置)
- [故障排查](#故障排查)
- [最佳实践](#最佳实践)

## ✨ 特性

- **跨平台支持**: Linux、macOS、Windows
- **声明式包管理**: 通过 `.chezmoiexternal` 自动管理二进制工具
- **加密敏感信息**: 使用 age 加密 SSH 私钥等敏感文件
- **模块化配置**: 拆分的脚本和数据文件，易于维护
- **自动化安装**: `run_onchange` 脚本自动执行系统配置
- **版本管理**: 支持固定或自动更新工具版本

## 🚀 快速开始

### 1. 安装 Chezmoi

```bash
# Linux/macOS
curl -fsSL https://chezmoi.io/get | bash

# macOS (Homebrew)
brew install chezmoi

# Windows (Scoop)
scoop install chezmoi
```

### 2. 初始化配置

```bash
# 从 Git 仓库初始化
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git

# 或者从本地目录初始化
chezmoi init ~/.local/share/chezmoi
```

### 3. 应用配置

```bash
# 预览将要更改的内容
chezmoi diff

# 应用配置
chezmoi apply
```

## 📁 项目结构

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl              # 主配置文件模板
├── .chezmoiexternal.toml.tmpl       # 外部资源配置（字体、二进制工具）
├── .chezmoiignore.tmpl              # 忽略规则
├── .chezmoidata/                    # 数据文件目录
│   ├── env.yaml                     # 环境变量配置
│   ├── packages.yaml                # 包管理配置
│   └── versions.yaml                # 工具版本管理
├── run_before_validate-templates.sh.tmpl  # 模板验证脚本
├── run_onchange_100-system-packages.sh.tmpl    # 系统包安装
├── run_onchange_200-declarative-tools.sh.tmpl  # 声明式工具检查
├── run_onchange_300-font-cache.sh.tmpl         # 字体缓存刷新
├── dot_bashrc.tmpl                  # Bash 配置
├── dot_gitconfig.tmpl               # Git 配置
├── dot_tmux.conf                    # Tmux 配置
├── dot_config/
│   └── nvim/                        # Neovim 配置
└── private_dot_ssh/                 # SSH 配置（加密）
    ├── authorized_keys
    ├── config.age
    └── private_id_ed25519.age
```

## ⚙️ 配置说明

### 主配置文件 (.chezmoi.toml.tmpl)

```toml
# Age 加密配置
[age]
    identity = "~/.config/chezmoi/key/age.txt"
    recipient = "age1..."

# 编辑器配置
[edit]
    command = "nvim"
    hardlink = true

# Git 自动提交
[git]
    autoCommit = true
```

### 外部资源配置 (.chezmoiexternal.toml.tmpl)

自动从 GitHub 下载和管理二进制工具：

- **uv**: Python 包管理器
- **bun**: JavaScript 运行时
- **starship**: Prompt 工具
- **fnm**: Node.js 版本管理器
- **字体**: JetBrainsMono Nerd Font

### 数据文件 (.chezmoidata/)

#### env.yaml
管理环境变量和代理配置：

```yaml
proxy:
  http: "http://proxy.example.com:8080"
  https: "http://proxy.example.com:8080"
  enabled: false

custom:
  opencode:
    disable_default_plugins: 1
```

#### packages.yaml
定义各平台需要安装的软件包：

```yaml
packages:
  linux:
    apt: ["git", "vim", "curl"]
    binaries: ["uv", "bun", "starship"]
```

#### versions.yaml
管理工具版本：

```yaml
tools:
  uv: "latest"
  bun: "latest"
```

## 📝 常用命令

### 基本操作

```bash
# 查看当前状态
chezmoi status

# 查看将要应用的更改
chezmoi diff

# 应用所有更改
chezmoi apply

# 应用特定文件
chezmoi apply ~/.bashrc

# 添加新文件到 chezmoi
chezmoi add ~/.config/nvim/init.lua

# 添加为模板
chezmoi add --template ~/.gitconfig
```

### 编辑和验证

```bash
# 进入源目录
chezmoi cd

# 编辑配置文件
chezmoi edit .chezmoi.toml.tmpl

# 验证模板语法
chezmoi execute-template < .chezmoi.toml.tmpl

# 查看所有模板数据
chezmoi data

# 检查配置健康状态
chezmoi doctor
```

### 脚本状态管理

```bash
# 查看脚本执行状态
chezmoi state dump

# 清除 run_once 脚本状态（重新执行）
chezmoi state delete-bucket --bucket=scriptState

# 清除 run_onchange 脚本状态（重新执行）
chezmoi state delete-bucket --bucket=entryState
```

### Git 操作

```bash
# 自动提交更改（需要配置）
chezmoi apply && chezmoi git auto-add

# 手动提交
cd $(chezmoi source-path)
git add .
git commit -m "Update dotfiles"
```

## 🔧 自定义配置

### 1. 添加新文件

```bash
# 添加普通文件
chezmoi add ~/.config/myapp/config.yaml

# 添加为模板（使用 Go 模板语法）
chezmoi add --template ~/.config/myapp/config.yaml
```

### 2. 添加加密文件

```bash
# 使用 age 加密
chezmoi add --encrypt ~/.ssh/id_ed25519

# 文件将被保存为 private_dot_ssh/encrypted_id_ed25519.age
```

### 3. 配置代理

编辑 `.chezmoidata/env.yaml`:

```yaml
proxy:
  http: "http://10.0.0.1:8080"
  https: "http://10.0.0.1:8080"
  enabled: true
```

然后运行 `chezmoi apply`。

### 4. 添加新的二进制工具

1. 在 `.chezmoidata/packages.yaml` 中添加工具名称
2. 在 `.chezmoiexternal.toml.tmpl` 中配置下载规则
3. 运行 `chezmoi apply`

示例：

```toml
{{- if eq . "mytool" }}
{{-   $asset := printf "mytool-%s-%s.tar.gz" .chezmoi.os .chezmoi.arch }}
[".local/bin/mytool"]
    type = "archive-file"
    url = {{ gitHubLatestReleaseAssetURL "user/repo" $asset | quote }}
    executable = true
    path = "mytool"
    stripComponents = 1
{{-   end }}
```

## 🔍 故障排查

### 模板语法错误

```bash
# 查看模板错误详情
chezmoi execute-template < .chezmoi.toml.tmpl

# 验证所有模板
# (运行 validate-templates 脚本)
```

### 脚本未执行

```bash
# 查看脚本执行状态
chezmoi state dump

# 清除脚本状态（强制重新执行）
chezmoi state delete-bucket --bucket=scriptState
chezmoi state delete-bucket --bucket=entryState
```

### 外部资源下载失败

```bash
# 检查网络连接
# 如果使用代理，在 .chezmoidata/env.yaml 中配置

# 强制刷新外部资源
chezmoi apply --force
```

### 配置未生效

```bash
# 查看详细输出
chezmoi apply --verbose

# 查看将要更改的内容
chezmoi diff

# 重新加载 shell 配置
source ~/.bashrc
```

## 💡 最佳实践

### 1. 版本控制

- 将配置推送到 Git 仓库
- 使用分支管理不同环境配置
- 定期提交更改

```bash
# 推送到 GitHub
cd $(chezmoi source-path)
git remote add origin https://github.com/YOUR_USERNAME/dotfiles.git
git push -u origin main
```

### 2. 安全性

- **永远不要**将加密密钥提交到 Git
- 使用 `.gitignore` 排除敏感文件
- 定期轮换 age 密钥

### 3. 模块化

- 使用 `.chezmoidata/` 分离数据
- 使用 `run_onchange_*` 脚本编号保持执行顺序
- 为不同平台创建专门的配置

### 4. 测试配置

```bash
# 在应用前预览更改
chezmoi diff

# 在测试环境验证
chezmoi apply --dry-run
```

### 5. 文档维护

- 在 README 中记录自定义配置
- 为复杂的模板添加注释
- 记录工具版本和依赖关系

## 🔄 更新配置

### 更新已有配置

```bash
# 拉取最新更改
cd $(chezmoi source-path)
git pull

# 查看将要应用的更改
chezmoi diff

# 应用更新
chezmoi apply
```

### 在新机器上设置

```bash
# 安装 chezmoi
curl -fsSL https://chezmoi.io/get | bash

# 初始化（会提示输入 age 密钥）
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git

# 应用配置
chezmoi apply
```

## 📚 相关资源

- [Chezmoi 官方文档](https://www.chezmoi.io/docs/)
- [Go 模板语法](https://pkg.go.dev/text/template)
- [Age 加密工具](https://github.com/FiloSottile/age)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

**提示**: 运行 `chezmoi doctor` 检查配置健康状态。
