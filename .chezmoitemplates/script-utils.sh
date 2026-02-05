# ==========================================
# 通用脚本工具函数
# ==========================================

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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
execute_with_loader() {
    local msg=$1
    shift
    printf "  > %-30s" "$msg"
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
execute_with_loader_skip() {
    local msg=$1
    shift
    printf "  > %-30s" "$msg"
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
