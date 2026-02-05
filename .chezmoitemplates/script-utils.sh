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

# 进度旋转器
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 带进度显示执行命令（成功/失败）
run_task() {
    local msg=$1
    shift
    printf "  > %-${LABEL_WIDTH}s" "$msg"
    "$@" > /dev/null 2>&1 &
    local pid=$!
    show_spinner "$pid"
    wait "$pid"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}完成${NC}"
    else
        echo -e "${RED}失败${NC}"
    fi
    return $exit_code
}

# 带进度显示执行命令（成功/跳过）
run_task_skip() {
    local msg=$1
    shift
    printf "  > %-${LABEL_WIDTH}s" "$msg"
    "$@" > /dev/null 2>&1 &
    local pid=$!
    show_spinner "$pid"
    wait "$pid"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}完成${NC}"
    else
        echo -e "${YELLOW}跳过${NC}"
    fi
    return $exit_code
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
