#!/bin/bash
# 用 skills CLI 安装/更新全局 skills,显式钉死 agent 列表
# (CLI 的自动探测会把不支持全局安装的 PromptScript/Eve 混进来刷报错;
#  update 子命令无法透传 agent,所以用 add 拉最新代替 update)
# 用法: skills-update.sh [owner/repo](缺省读 ~/.config/skills.txt 全部)
set -uo pipefail
cd "$HOME" || exit 1

# -a 要空格分隔的多参数,逗号串会被当成单个非法 agent 名
AGENTS=(amp antigravity antigravity-cli cline codex cursor deepagents gemini-cli github-copilot kimi-code-cli opencode warp zed claude-code)

if [ $# -gt 0 ]; then
  pkgs=("$@")
else
  MANIFEST="$HOME/.config/skills.txt"
  [ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST"; exit 1; }
  mapfile -t pkgs < <(grep -v '^\s*\(#\|$\)' "$MANIFEST")
fi

for pkg in "${pkgs[@]}"; do
  echo "==> $pkg"
  # 注意:-y 本身就装全部 skills,不要加 -s '*'——PS 5.1 传参会剥掉引号,
  # 裸 * 混进参数后 CLI 会当成 agent 通配符,把所有 agent(含 PromptScript)拉进来
  bunx skills add "$pkg" -g -y -a "${AGENTS[@]}"
done
