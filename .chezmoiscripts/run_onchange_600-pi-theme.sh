#!/bin/sh
# 给 Pi 的 settings.json 设置主题（只改 theme 一个键，其他键原样保留）
#
# 为什么用脚本而不是模板：settings.json 里混着机器特定配置
# （defaultModel / defaultProvider / lastChangelogVersion），
# 用模板整文件覆盖会冲掉别的机器上的值。
# pi 不一定装了，没装就跳过。

set -e

if ! command -v pi >/dev/null 2>&1; then
	echo "pi 未安装，跳过 Pi 主题设置"
	exit 0
fi

SETTINGS="$HOME/.pi/agent/settings.json"
THEME="monokai-pro-light/monokai-pro-dark"

mkdir -p "$(dirname "$SETTINGS")"

# 没有 jq 或 python 就不硬来，避免写坏文件
if command -v python3 >/dev/null 2>&1; then
	PY=python3
elif command -v python >/dev/null 2>&1; then
	PY=python
else
	echo "找不到 python，跳过 Pi 主题设置"
	exit 0
fi

"$PY" - "$SETTINGS" "$THEME" <<'PYEOF'
import json, os, sys

path, theme = sys.argv[1], sys.argv[2]

data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            raw = f.read().strip()
        data = json.loads(raw) if raw else {}
    except Exception:
        # 文件坏了就备份再重写，不静默丢数据
        bak = path + ".broken"
        try:
            os.replace(path, bak)
            print(f"settings.json 解析失败，已备份到 {bak}")
        except Exception:
            pass
        data = {}

if not isinstance(data, dict):
    data = {}

if data.get("theme") == theme:
    sys.exit(0)

data["theme"] = theme
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
print(f"Pi 主题已设为 {theme}")
PYEOF
