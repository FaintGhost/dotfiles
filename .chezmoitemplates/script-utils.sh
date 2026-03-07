# ==========================================
# 通用脚本工具函数
# ==========================================

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 统一宽度（考虑中文字符）
LABEL_WIDTH=32
LOG_TAIL_LINES=10

# 进度旋转器
show_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\\'

  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep "$delay"
    printf "\b\b\b\b\b\b"
  done

  printf "    \b\b\b\b"
}

show_task_log() {
  local log_file=$1
  local line_count

  if [ ! -s "$log_file" ]; then
    return 0
  fi

  line_count=$(wc -l < "$log_file")
  if [ "$line_count" -gt "$LOG_TAIL_LINES" ]; then
    echo -e "    ${YELLOW}↳ 仅显示最后 ${LOG_TAIL_LINES} 行${NC}"
  fi

  tail -n "$LOG_TAIL_LINES" "$log_file" | sed 's/^/    │ /'
}

run_task_logged() {
  local mode=$1
  local msg=$2
  shift 2

  local log_file
  local pid
  local exit_code

  log_file=$(mktemp)
  printf "  > %-${LABEL_WIDTH}s" "$msg"

  "$@" >"$log_file" 2>&1 &
  pid=$!
  show_spinner "$pid"

  if wait "$pid"; then
    exit_code=0
  else
    exit_code=$?
  fi

  if [ "$exit_code" -eq 0 ]; then
    echo -e "${GREEN}完成${NC}"
    rm -f "$log_file"
    return 0
  fi

  if [ "$mode" = "skip" ]; then
    echo -e "${YELLOW}跳过${NC}"
    show_task_log "$log_file"
    rm -f "$log_file"
    return 0
  fi

  echo -e "${RED}失败${NC}"
  show_task_log "$log_file"
  rm -f "$log_file"
  return "$exit_code"
}

# 带进度显示执行命令（成功/失败）
run_task() {
  local msg=$1
  shift
  run_task_logged "fail" "$msg" "$@"
}

# 带进度显示执行命令（成功/跳过）
run_task_skip() {
  local msg=$1
  shift
  run_task_logged "skip" "$msg" "$@"
}

# 打印标题
print_header() {
  echo -e "${BLUE}$1${NC}"
}

# 打印成功状态
print_ok() {
  echo -e "  ${GREEN}✓${NC} $1"
}

# 打印警告状态
print_warn() {
  echo -e "  ${YELLOW}⚡${NC} $1"
}

# 打印完成信息
print_done() {
  echo -e "  ${GREEN}✓ $1${NC}"
}
