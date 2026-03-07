# Task Plan

- [x] 检查当前 `chezmoi` 自动安装入口与包来源
- [x] 将 `tmux` 与 `starship` 纳入自动安装配置
- [x] 验证脚本会读取新包列表并能覆盖 shell 依赖
- [x] 在本文件补充 review 结果

# Review

- 已将 `tmux` 与 `starship` 加入 `.chezmoidata/packages.yaml` 的 `packages.linux.apt`
- 已确认 `.chezmoiscripts/run_onchange_100-system-packages.sh.tmpl` 持续从 `.packages.linux.apt` 渲染 `apt install -y ...`
- 已通过 `chezmoi execute-template` 验证渲染命令包含 `tmux starship`
- 已通过 `bash -n` 验证渲染后的安装脚本语法正确
- 本机 `apt-cache policy` 可解析 `tmux` 与 `starship`，满足当前环境的最小改法前提
