#!/usr/bin/env bash

# ============================================
# FrameworkPatcher 自动构建脚本
# 支持 Ubuntu 和 Arch Linux 系统
# ============================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否在 CI/CD 环境运行
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$GITLAB_CI" ] || [ -n "$CIRCLECI" ]; then
    IS_CI_ENV="true"
    echo -e "${YELLOW}[CI环境] 检测到 CI/CD 环境，将自动处理用户交互${NC}"
else
    IS_CI_ENV="false"
fi

# 自动回答（用于CI环境）
AUTO_ANSWER=""

# 脚本目录和工具目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(pwd)"
TOOLS_DIR="$SCRIPT_DIR/../tools"
BIN_DIR="$SCRIPT_DIR/../bin"
LOG_FILE="$WORK_DIR/build.log"

# 设备代号到设备名称的映射（按系列分类）
declare -A DEVICE_MAP=(
    # ========== Xiaomi 数字系列 ==========
    ["houji"]="Xiaomi 14"
    ["fuxi"]="Xiaomi 13"
    ["nuwa"]="Xiaomi 13 Pro"
    ["ishtar"]="Xiaomi 13 Ultra"
    ["cupid"]="Xiaomi 12"
    ["psyche"]="Xiaomi 12X"
    ["zeus"]="Xiaomi 12 Pro"
    ["unicorn"]="Xiaomi 12S Pro"
    ["mayfly"]="Xiaomi 12S"
    ["thor"]="Xiaomi 12S Ultra"
    ["diting"]="Xiaomi 12T Pro / Redmi K50 Ultra"
    ["plato"]="Xiaomi 12T"
    ["venus"]="Xiaomi 11"
    ["star"]="Xiaomi 11 Ultra / Pro"
    ["mars"]="Xiaomi 11 Ultra / Pro"
    ["haydn"]="Xiaomi 11i / Redmi K40 Pro/Pro+"
    ["agate"]="Xiaomi 11T"
    ["vili"]="Xiaomi 11T Pro"
    ["umi"]="Xiaomi 10"
    ["cmi"]="Xiaomi 10 Pro"
    ["cas"]="Xiaomi 10 Ultra"
    ["thyme"]="Xiaomi 10S"
    ["monet"]="Xiaomi 10 Lite"
    ["vangogh"]="Xiaomi 10 Lite (China)"
    ["toco"]="Xiaomi Note 10 Lite"
    
    # ========== Xiaomi Civi系列 ==========
    ["chenfeng"]="Xiaomi 14 Civi / Xiaomi Civi 4 Pro"
    ["ziyi"]="Xiaomi 13 Lite / Civi 2"
    ["mona"]="Xiaomi Civi"
    ["zijin"]="Xiaomi Civi 1S"
    ["yuechu"]="Xiaomi Civi 3"
    
    # ========== Xiaomi MIX系列 ==========
    ["shennong"]="Xiaomi 14 Pro / 14 Pro Ti Satellite"
    ["aurora"]="Xiaomi 14 Ultra"
    ["odin"]="Xiaomi MIX 4"
    ["cetus"]="Xiaomi MIX Fold"
    ["zizhan"]="Xiaomi MIX Fold 2"
    ["babylon"]="Xiaomi MIX Fold 3"
    ["goku"]="Xiaomi MIX Fold 4"
    ["ruyi"]="Xiaomi MIX Flip"
    
    # ========== Redmi K系列 ==========
    ["peridot"]="Redmi Turbo 3 / POCO F6"
    ["vermeer"]="Redmi K70 / POCO F6 Pro"
    ["manet"]="Redmi K70 Pro"
    ["corot"]="Xiaomi 13T Pro / Redmi K60 Ultra"
    ["mondrian"]="Redmi K60 / POCO F5 Pro"
    ["socrates"]="Redmi K60 Pro"
    ["rembrandt"]="Redmi K60E"
    ["ingres"]="Redmi K50G / POCO F4 GT"
    ["matisse"]="Redmi K50 Pro"
    ["rubens"]="Redmi K50"
    ["diting"]="Xiaomi 12T Pro / Redmi K50 Ultra"
    ["ares"]="Redmi K40 Gaming / POCO F3 GT"
    ["alioth"]="Redmi K40 / POCO F3"
    ["haydn"]="Xiaomi 11i / Redmi K40 Pro/Pro+"
    ["munch"]="Redmi K40S / POCO F4"
    ["apollo"]="Xiaomi 10T / 10T Pro / Redmi K30S Ultra"
    ["cezanne"]="Redmi K30 Ultra"
    ["lmi"]="Redmi K30 Pro"
    ["picasso"]="Redmi K30 / K30i"
    ["phoenix"]="Redmi K30 4G / POCO X2 4G"
    
    # ========== Redmi Note系列 ==========
    ["duchamp"]="Redmi K70E / POCO X6 Pro"
    ["marble"]="Redmi Note 12 Turbo / POCO F5"
    ["ruby"]="Redmi Note 12 Pro"
    ["sunstone"]="Redmi Note 12 / Note 12R Pro"
    ["moonstone"]="POCO X5"
    ["redwood"]="Redmi Note 12 Pro Speed / POCO X5 Pro"
    ["tapas"]="Redmi Note 12 4G"
    ["topaz"]="Redmi Note 12 4G NFC"
    ["garnet"]="Redmi Note 13 Pro / POCO X6"
    ["zircon"]="Redmi Note 13 Pro+"
    ["gold"]="Redmi Note 13 / 13R Pro / POCO X6 Neo"
    ["sapphire"]="Redmi Note 13 4G"
    ["sapphiren"]="Redmi Note 13 NFC"
    ["emerald"]="Redmi Note 13 Pro 4G / POCO M6 Pro 4G"
    ["sweet"]="Redmi Note 10 Pro"
    ["sweetin"]="Redmi Note 10 Pro (India) / Pro Max"
    ["sweet_k6a"]="Redmi Note 12 Pro 4G"
    ["mojito"]="Redmi Note 10"
    ["rosemary"]="Redmi Note 10S / POCO M5s"
    ["camellian"]="Redmi Note 10 (Global) / Note 10T / POCO M3 Pro"
    ["lilac"]="Redmi Note 10T"
    ["spes"]="Redmi Note 11"
    ["spesn"]="Redmi Note 11 NFC"
    ["evergo"]="Redmi Note 11 / Note 11T"
    ["evergreen"]="POCO M4 Pro"
    ["fleur"]="Redmi Note 11S 4G / POCO M4 Pro 4G"
    ["opal"]="Redmi Note 11S"
    ["veux"]="Redmi Note 11E Pro / Note 11 Pro / POCO X4 Pro"
    ["pissarro"]="Xiaomi 11i / Redmi Note 11 Pro/Pro+"
    ["chopin"]="Redmi Note 10 Pro (China) / POCO X3 GT"
    ["joyeuse"]="Redmi Note 9 Pro"
    ["curtana"]="Redmi Note 9 Pro (India) / Note 9S / Note 10 Lite"
    ["excalibur"]="Redmi Note 9 Pro Max"
    ["merlin"]="Redmi Note 9 / 10X 4G"
    ["cannon"]="Redmi Note 9"
    ["cannong"]="Redmi Note 9T"
    ["gauguin"]="Xiaomi 10T Lite / 10i / Redmi Note 9 Pro"
    ["pearl"]="Redmi Note 12T Pro"
    
    # ========== POCO系列 ==========
    ["peridot"]="Redmi Turbo 3 / POCO F6"
    ["vermeer"]="Redmi K70 / POCO F6 Pro"
    ["duchamp"]="Redmi K70E / POCO X6 Pro"
    ["marble"]="Redmi Note 12 Turbo / POCO F5"
    ["mondrian"]="Redmi K60 / POCO F5 Pro"
    ["ingres"]="Redmi K50G / POCO F4 GT"
    ["munch"]="Redmi K40S / POCO F4"
    ["alioth"]="Redmi K40 / POCO F3"
    ["haydn"]="Xiaomi 11i / Redmi K40 Pro/Pro+ (POCO F3 Pro)"
    ["ares"]="Redmi K40 Gaming / POCO F3 GT"
    ["vayu"]="POCO X3 Pro"
    ["surya"]="POCO X3 NFC"
    ["vili"]="Xiaomi 11T Pro (POCO F3 GT)"
    ["chopin"]="Redmi Note 10 Pro (China) / POCO X3 GT"
    ["gram"]="POCO M2 Pro"
    ["citrus"]="POCO M3"
    ["camellian"]="Redmi Note 10 (Global) / Note 10T / POCO M3 Pro"
    ["evergreen"]="POCO M4 Pro"
    ["fleur"]="Redmi Note 11S 4G / POCO M4 Pro 4G"
    ["veux"]="Redmi Note 11E Pro / Note 11 Pro / POCO X4 Pro"
    ["redwood"]="Redmi Note 12 Pro Speed / POCO X5 Pro"
    ["moonstone"]="POCO X5"
    ["garnet"]="Redmi Note 13 Pro / POCO X6"
    ["gold"]="Redmi Note 13 / 13R Pro / POCO X6 Neo"
    
    # ========== Redmi数字系列 ==========
    ["moon"]="Redmi 13 / 13x / POCO M6"
    ["fire"]="Redmi 12"
    ["sky"]="Redmi Note 12 / Note 12R / POCO M6 Pro"
    ["gale"]="Redmi 13C / POCO C65"
    ["air"]="Redmi 13C 5G / 13R 5G / POCO M6 5G"
    ["lake"]="Redmi 14C / A3 Pro / POCO C75"
    ["flame"]="Redmi 14R 5G / 14C 5G / POCO M7 5G"
    ["warm"]="Redmi A4 5G / POCO C75 5G"
    ["serenity"]="Redmi A5 / POCO C71"
    ["blue"]="Redmi A3 / POCO C61"
    ["klein"]="Redmi A3x"
    ["water"]="Redmi A2/A2+ / POCO C51"
    ["ice"]="Redmi A1 / POCO C50"
    ["earth"]="Redmi 12C / POCO C55"
    ["fog"]="Redmi 10C"
    ["light"]="Redmi 10 / 11 Prime / Note 11E / POCO M4"
    ["lightcm"]="Redmi Note 11R"
    ["selene"]="Redmi 10 / 10 Prime / Note 11 4G"
    ["lime"]="Redmi 9T / 9 Power / Note 9 4G"
    ["lancelot"]="Redmi 9 / 9 Prime"
    ["dandelion"]="Redmi 9A / 9i / 9AT / 10A"
    ["atom"]="Redmi 10X"
    ["bomb"]="Redmi 10X Pro"
    ["frost"]="POCO C40"
    
    # ========== Pad系列 ==========
    ["pipa"]="Xiaomi Pad 6"
    ["liuqin"]="Xiaomi Pad 6 Pro"
    ["yudi"]="Xiaomi Pad 6 Max 14"
    ["sheng"]="Xiaomi Pad 6S Pro"
    ["elish"]="Xiaomi Pad 5 Pro WiFi"
    ["enuma"]="Xiaomi Pad 5 Pro 5G"
    ["dagu"]="Xiaomi Pad 5 Pro 12.4"
    ["nabu"]="Xiaomi Pad 5"
    ["yunluo"]="Redmi Pad"
    ["xun"]="Redmi Pad SE"
    ["dizi"]="Redmi Pad Pro WiFi / POCO Pad"
    ["ruan"]="Redmi Pad Pro 5G / POCO Pad 5G"
    ["spark"]="Redmi Pad SE 8.7 4G"
    ["flare"]="Redmi Pad SE 8.7 WiFi"
)

# CI环境自动回答函数
ci_auto_answer() {
    local question="$1"
    local default_value="$2"
    
    if [ "$IS_CI_ENV" = "true" ]; then
        echo "$default_value"
        return 0
    fi
    
    # 非CI环境，返回空值，让后续逻辑处理
    return 1
}

# CI环境安全读取用户输入
safe_read_input() {
    local prompt="$1"
    local default_value="$2"
    local var_name="$3"
    
    if [ "$IS_CI_ENV" = "true" ]; then
        # CI环境使用默认值
        eval "$var_name=\"$default_value\""
        echo -e "${YELLOW}[CI环境] 自动使用默认值: $default_value${NC}"
        return 0
    fi
    
    # 非CI环境正常读取
    echo -n "$prompt"
    read -r value
    eval "$var_name=\"$value\""
}

# CI环境安全确认
safe_confirm() {
    local prompt="$1"
    
    if [ "$IS_CI_ENV" = "true" ]; then
        # CI环境默认继续
        echo -e "${YELLOW}[CI环境] 自动确认继续${NC}"
        return 0
    fi
    
    # 非CI环境正常确认
    read -p "$prompt" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 初始化日志
init_log() {
    echo -e "${GREEN}开始记录日志到: $LOG_FILE${NC}"
    echo "===========================================" >> "$LOG_FILE"
    echo "构建开始时间: $(date)" >> "$LOG_FILE"
    echo "工作目录: $WORK_DIR" >> "$LOG_FILE"
    echo "脚本目录: $SCRIPT_DIR" >> "$LOG_FILE"
    echo "CI环境: $IS_CI_ENV" >> "$LOG_FILE"
    echo "===========================================" >> "$LOG_FILE"
}

# 日志记录函数
log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $msg"
    echo "[INFO] $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $msg"
    echo "[SUCCESS] $msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARNING]${NC} $msg"
    echo "[WARNING] $msg" >> "$LOG_FILE"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg"
    echo "[ERROR] $msg" >> "$LOG_FILE"
}

# 显示帮助信息
show_help() {
    cat << EOF
FrameworkPatcher 自动构建脚本

用法: ./build.sh [选项] <ROM路径或URL>

选项:
  -h, --help                显示此帮助信息
  -o, --output-dir <目录>   指定输出目录（默认: 当前目录）
  -f, --features <功能列表>  指定修补功能（逗号分隔）
                         可用功能: disable_signature_verification, cn_notification_fix,
                                disable_secure_flag, kaorios_toolbox, add_gboard
  -d, --device-name <名称>  指定设备完整名称（如 "Xiaomi Pad 6"）
  -k, --keep-files          保留中间文件（默认会清理）
  -v, --verbose             显示详细输出
  -y, --yes                 自动回答"yes"（跳过所有确认提示）

示例:
  # 使用URL自动构建 (Android 15)
  ./build.sh "https://bkt-sgp-miui-ota-update-alisgp.oss-ap-southeast-1.aliyuncs.com/OS3.0.5.0.VMYCNXM/liuqin-ota_full-OS3.0.5.0.VMYCNXM-user-15.0-39685cb85f.zip"

  # 使用本地文件构建 (Android 13)
  ./build.sh "/mnt/d/Desktop/miui_ELISH_OS1.0.2.0.TKYCNXM_da8102b61e_13.0.zip"

  # 指定功能和设备名称
  ./build.sh -f "disable_signature_verification,cn_notification_fix" -d "Xiaomi Pad 6" "https://example.com/rom.zip"

  # 指定输出目录
  ./build.sh -o ./output "https://example.com/rom.zip"

注意:
  - 脚本会自动检测系统（Ubuntu/Arch）并安装所需依赖
  - 需要从 HyperOS_SystemApps_Get_Action 项目复制提取工具到 tools/ 目录
  - 支持远程URL和本地文件路径
  - Android版本从 "-user-" 后面的数字自动识别（如 -user-15.0- 表示 Android 15）
  - 使用 -y 参数或 CI 环境运行时，将自动处理所有用户交互
EOF
}

# 检测操作系统并安装依赖
install_dependencies() {
    log_info "检测操作系统..."
    
    if command -v apt &> /dev/null; then
        log_info "检测到 Ubuntu/Debian 系统"
        install_ubuntu_deps
    elif command -v pacman &> /dev/null; then
        log_info "检测到 Arch Linux 系统"
        install_arch_deps
    elif command -v dnf &> /dev/null; then
        log_info "检测到 Fedora/RHEL 系统"
        install_fedora_deps
    else
        log_warning "未知的Linux发行版，请手动安装所需依赖"
        echo "所需依赖: python3 python3-pip aria2 p7zip zip unzip wget curl file zstd"
        
        if ! safe_confirm "是否尝试继续? (y/N): "; then
            exit 1
        fi
    fi
    
    # 安装Python依赖
    log_info "安装Python依赖..."
    pip3 install --upgrade pip pycryptodome setuptools docopt requests beautifulsoup4 pyyaml 2>/dev/null || {
        log_warning "部分Python依赖安装失败，尝试继续..."
    }
}

install_ubuntu_deps() {
    log_info "更新包列表..."
    sudo apt-get update 2>/dev/null || true
    
    log_info "安装系统依赖..."
    sudo apt-get install -y \
        python3 \
        python3-pip \
        aria2 \
        p7zip-full \
        zip \
        unzip \
        wget \
        curl \
        file \
        zstd \
        dos2unix \
        rsync 2>/dev/null || {
        log_warning "部分依赖安装失败，尝试继续..."
    }
}

install_arch_deps() {
    log_info "更新系统..."
    sudo pacman -Syu --noconfirm 2>/dev/null || true
    
    log_info "安装系统依赖..."
    sudo pacman -S --noconfirm \
        python \
        python-pip \
        aria2 \
        p7zip \
        zip \
        unzip \
        wget \
        curl \
        file \
        zstd \
        dos2unix \
        rsync 2>/dev/null || {
        log_warning "部分依赖安装失败，尝试继续..."
    }
}

install_fedora_deps() {
    log_info "更新系统..."
    sudo dnf update -y 2>/dev/null || true
    
    log_info "安装系统依赖..."
    sudo dnf install -y \
        python3 \
        python3-pip \
        aria2 \
        p7zip \
        zip \
        unzip \
        wget \
        curl \
        file \
        zstd \
        dos2unix \
        rsync 2>/dev/null || {
        log_warning "部分依赖安装失败，尝试继续..."
    }
}

# 检查工具是否就绪
check_tools() {
    log_info "检查必要工具..."
    
    local missing_tools=()
    
    # 检查基本工具
    for tool in python3 aria2 7z wget; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        return 1
    fi
    
    # 检查HyperOS提取工具
    local hyperos_tools=("payload_extract" "gettype.py" "imgextractorLinux.py" "extract.erofs")
    local missing_hyperos=()
    
    for tool in "${hyperos_tools[@]}"; do
        if [ ! -f "$TOOLS_DIR/$tool" ]; then
            missing_hyperos+=("$tool")
        fi
    done
    
    if [ ${#missing_hyperos[@]} -gt 0 ]; then
        log_warning "缺少HyperOS提取工具: ${missing_hyperos[*]}"
        log_warning "请从 HyperOS_SystemApps_Get_Action 项目复制到 $TOOLS_DIR/"
        
        if [ "$IS_CI_ENV" = "true" ]; then
            log_error "CI环境中缺少必要工具，构建失败"
            return 1
        fi
        
        if ! safe_confirm "是否尝试继续? (y/N): "; then
            return 1
        fi
    fi
    
    # 检查patcher脚本
    if [ ! -f "$SCRIPT_DIR/patcher_a13.sh" ] || \
       [ ! -f "$SCRIPT_DIR/patcher_a14.sh" ] || \
       [ ! -f "$SCRIPT_DIR/patcher_a15.sh" ] || \
       [ ! -f "$SCRIPT_DIR/patcher_a16.sh" ]; then
        log_error "缺少patcher脚本，请确保所有patcher脚本都存在"
        return 1
    fi
    
    log_success "所有必要工具检查通过"
    return 0
}

# 设置执行权限
set_permissions() {
    log_info "设置脚本执行权限..."
    
    # 设置工具执行权限
    chmod +x "$TOOLS_DIR"/*.py 2>/dev/null || true
    chmod +x "$TOOLS_DIR"/payload_extract 2>/dev/null || true
    chmod +x "$TOOLS_DIR"/extract.erofs 2>/dev/null || true
    
    # 设置patcher脚本执行权限
    chmod +x "$SCRIPT_DIR"/patcher_*.sh 2>/dev/null || true
    
    log_success "权限设置完成"
}

# 解析ROM信息
parse_rom_info() {
    local rom_path="$1"
    
    log_info "解析ROM信息: $rom_path"
    
    # 提取文件名
    local filename
    if [[ "$rom_path" =~ ^http ]]; then
        filename=$(basename "$(echo "$rom_path" | cut -d'?' -f1)")
    else
        filename=$(basename "$rom_path")
    fi
    
    log_info "ROM文件名: $filename"
    
    local codename=""
    local version=""
    local android_version=""
    
    # 尝试解析文件名格式
    # 格式1: liuqin-ota_full-OS3.0.5.0.VMYCNXM-user-15.0-39685cb85f.zip
    # 格式2: houji-ota_full-OS3.0.6.0.WNCCNXM-user-16.0-63c202b5f4.zip
    # 格式3: miui_HOUJI_OS1.0.47.0.UNCCNXM_1570ac24a8_14.0.zip
    # 格式4: miui_ELISH_OS1.0.2.0.TKYCNXM_da8102b61e_13.0.zip
    
    # 尝试匹配格式1和2：{codename}-ota_full-{version}-user-{android}.{minor}-{hash}.zip
    if [[ "$filename" =~ ^([a-zA-Z0-9]+)-ota_full-([A-Z0-9\.]+)-user-([0-9]+)\.[0-9]+- ]]; then
        codename="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        android_version="${BASH_REMATCH[3]}"
        log_info "匹配OTA格式: 设备代号=$codename, 版本=$version, Android=$android_version"
    
    # 尝试匹配格式3和4：miui_{DEVICE}_{version}_{hash}_{android}.0.zip
    elif [[ "$filename" =~ ^miui_([A-Z]+)_([A-Z0-9\.]+)_[0-9a-f]+_([0-9]+)\.0\.zip$ ]]; then
        local device_upper="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        android_version="${BASH_REMATCH[3]}"
        
        # 转换设备代号（大写转小写）
        codename=$(echo "$device_upper" | tr '[:upper:]' '[:lower:]')
        log_info "匹配MIUI格式: 设备代号=$codename, 版本=$version, Android=$android_version"
    
    # 尝试匹配其他可能的格式
    elif [[ "$filename" =~ -user-([0-9]+)\.[0-9]+- ]]; then
        # 通用格式：从-user-提取Android版本
        android_version="${BASH_REMATCH[1]}"
        
        # 尝试提取设备代号（文件名开头部分）
        if [[ "$filename" =~ ^([a-zA-Z0-9]+)- ]]; then
            codename="${BASH_REMATCH[1]}"
        fi
        
        # 尝试提取版本（在OS和-user之间）
        if [[ "$filename" =~ (OS[0-9A-Z\.]+)-user- ]]; then
            version="${BASH_REMATCH[1]}"
        fi
        log_info "匹配通用格式: 设备代号=$codename, 版本=$version, Android=$android_version"
    fi
    
    # 如果还未提取到Android版本，尝试其他方法
    if [[ -z "$android_version" ]]; then
        log_warning "无法直接解析Android版本，尝试从文件路径提取..."
        
        # 尝试从URL路径提取版本
        if [[ "$rom_path" =~ /([A-Z0-9\.]+)/ ]]; then
            version="${BASH_REMATCH[1]}"
        fi
        
        # 尝试从文件名开头提取设备代号
        if [[ "$filename" =~ ^([a-zA-Z0-9]+) ]]; then
            codename="${BASH_REMATCH[1]}"
            # 去除可能的miui_前缀
            codename="${codename#miui_}"
            # 如果codename包含下划线，取第一部分
            if [[ "$codename" =~ _ ]]; then
                codename="${codename%%_*}"
            fi
        fi
        
        # 最后手段：询问用户或使用默认值
        if [[ -z "$android_version" ]]; then
            if [ "$IS_CI_ENV" = "true" ]; then
                log_error "CI环境中无法解析Android版本，构建失败"
                return 1
            fi
            
            echo -e "${YELLOW}无法自动确定Android版本${NC}"
            safe_read_input "请手动输入Android版本 (13, 14, 15, 16): " "14" android_version_input
            android_version="$android_version_input"
        fi
    fi
    
    # 验证提取的信息
    if [[ -z "$codename" ]]; then
        log_error "无法提取设备代号"
        
        if [ "$IS_CI_ENV" = "true" ]; then
            log_error "CI环境中无法提取设备代号，构建失败"
            return 1
        fi
        
        safe_read_input "请输入设备代号: " "" codename_input
        codename="$codename_input"
        
        if [[ -z "$codename" ]]; then
            log_error "设备代号不能为空"
            return 1
        fi
    fi
    
    if [[ -z "$version" ]]; then
        log_warning "无法提取版本信息"
        version="UNKNOWN"
    fi
    
    # 验证Android版本
    if [[ -z "$android_version" ]] || ! [[ "$android_version" =~ ^(13|14|15|16)$ ]]; then
        log_error "无效的Android版本: $android_version (必须是13, 14, 15, 16)"
        
        if [ "$IS_CI_ENV" = "true" ]; then
            log_error "CI环境中Android版本无效，构建失败"
            return 1
        fi
        
        safe_read_input "请手动输入正确的Android版本 (13, 14, 15, 16): " "14" android_version_input
        android_version="$android_version_input"
        
        if ! [[ "$android_version" =~ ^(13|14|15|16)$ ]]; then
            log_error "Android版本必须是13, 14, 15或16"
            return 1
        fi
    fi
    
    # 输出解析结果
    log_success "解析结果:"
    log_success "  设备代号: $codename"
    log_success "  版本: $version"
    log_success "  Android版本: $android_version"
    
    # 返回解析结果
    echo "$codename,$version,$android_version"
    return 0
}

# 下载ROM文件
download_rom() {
    local rom_url="$1"
    local output_dir="$2"
    
    log_info "下载ROM文件: $rom_url"
    
    local filename
    filename=$(basename "$(echo "$rom_url" | cut -d'?' -f1)")
    local output_path="$output_dir/$filename"
    
    # 检查是否已存在
    if [ -f "$output_path" ]; then
        local existing_size
        existing_size=$(stat -c%s "$output_path" 2>/dev/null || stat -f%z "$output_path" 2>/dev/null)
        if [ "$existing_size" -gt 1000000 ]; then
            log_info "使用已存在的ROM文件: $filename ($existing_size bytes)"
            echo "$output_path"
            return 0
        else
            log_warning "现有文件大小异常，重新下载..."
            rm -f "$output_path"
        fi
    fi
    
    # 使用aria2多线程下载
    log_info "开始下载..."
    aria2c \
        -x 16 \
        -j "$(nproc)" \
        -U "Mozilla/5.0" \
        -d "$output_dir" \
        -o "$filename" \
        "$rom_url"
    
    if [ $? -eq 0 ] && [ -f "$output_path" ]; then
        local file_size
        file_size=$(stat -c%s "$output_path" 2>/dev/null || stat -f%z "$output_path" 2>/dev/null)
        log_success "下载完成: $filename ($file_size bytes)"
        echo "$output_path"
        return 0
    else
        log_error "下载失败: $rom_url"
        return 1
    fi
}

# 提取ROM分区
extract_rom() {
    local rom_path="$1"
    local output_dir="$2"
    
    log_info "提取ROM分区..."
    
    # 创建必要的目录
    local mods_dir="$output_dir/mods"
    local img_port_dir="$output_dir/img_port"
    mkdir -p "$mods_dir" "$img_port_dir"
    
    # 解压分区
    for partition in system system_ext; do
        log_info "提取 $partition 分区..."
        
        # 使用payload_extract提取分区
        if [ -f "$TOOLS_DIR/payload_extract" ]; then
            sudo "$TOOLS_DIR/payload_extract" \
                -i "$rom_path" \
                -t zip \
                --extract="$partition" \
                -o "$mods_dir"
        elif [ -f "$TOOLS_DIR/payload_extractor.py" ]; then
            sudo python3 "$TOOLS_DIR/payload_extractor.py" \
                -i "$rom_path" \
                -t zip \
                --extract="$partition" \
                -o "$mods_dir"
        else
            log_error "未找到payload提取工具"
            return 1
        fi
        
        # 检查提取的镜像
        local img_path="$mods_dir/$partition.img"
        if [ ! -f "$img_path" ]; then
            log_warning "分区 $partition 镜像未找到"
            continue
        fi
        
        # 检测镜像类型
        local img_type="unknown"
        if [ -f "$TOOLS_DIR/gettype.py" ]; then
            img_type=$(sudo python3 "$TOOLS_DIR/gettype.py" "$img_path")
            log_info "$partition 镜像类型: $img_type"
        fi
        
        # 根据类型提取
        if [ "$img_type" = "erofs" ]; then
            # 提取erofs镜像
            if [ -f "$TOOLS_DIR/extract.erofs" ]; then
                sudo "$TOOLS_DIR/extract.erofs" \
                    -i "$img_path" \
                    -o "$img_port_dir" \
                    -x >/dev/null 2>&1 || {
                    log_warning "提取erofs失败: $partition"
                }
            else
                log_warning "未找到erofs提取工具"
            fi
        elif [ "$img_type" = "ext" ] || [ "$img_type" = "ext4" ]; then
            # 提取ext4镜像
            if [ -f "$TOOLS_DIR/imgextractorLinux.py" ]; then
                sudo python3 "$TOOLS_DIR/imgextractorLinux.py" \
                    "$img_path" \
                    "$img_port_dir" >/dev/null 2>&1 || {
                    log_warning "提取ext4失败: $partition"
                }
            else
                log_warning "未找到ext4提取工具"
            fi
        else
            # 尝试自动检测并提取
            log_warning "未知镜像类型，尝试自动提取..."
            if file "$img_path" | grep -q "EROFS"; then
                if [ -f "$TOOLS_DIR/extract.erofs" ]; then
                    sudo "$TOOLS_DIR/extract.erofs" \
                        -i "$img_path" \
                        -o "$img_port_dir" \
                        -x >/dev/null 2>&1
                fi
            elif file "$img_path" | grep -q "Android"; then
                if [ -f "$TOOLS_DIR/imgextractorLinux.py" ]; then
                    sudo python3 "$TOOLS_DIR/imgextractorLinux.py" \
                        "$img_path" \
                        "$img_port_dir" >/dev/null 2>&1
                fi
            fi
        fi
        
        # 清理临时镜像
        sudo rm -f "$img_path"
    done
    
    log_success "ROM提取完成"
    echo "$img_port_dir"
    return 0
}

# 查找并复制JAR文件
find_and_copy_jars() {
    local img_port_dir="$1"
    local output_dir="$2"
    
    log_info "查找JAR文件..."
    
    # 定义目标JAR文件及其可能的位置
    # framework.jar和services.jar一般在system分区
    # miui-services.jar和miui-framework.jar一般在system_ext分区
    declare -A jar_locations=(
        ["framework.jar"]="framework/framework.jar system/framework/framework.jar system/system/framework/framework.jar"
        ["services.jar"]="framework/services.jar system/framework/services.jar system/system/framework/services.jar"
        ["miui-services.jar"]="framework/miui-services.jar system_ext/framework/miui-services.jar system/system_ext/framework/miui-services.jar"
        ["miui-framework.jar"]="framework/miui-framework.jar system_ext/framework/miui-framework.jar system/system_ext/framework/miui-framework.jar"
    )
    
    local found_jars=0
    
    # 查找每个JAR文件
    for jar_name in "${!jar_locations[@]}"; do
        local found=0
        
        # 在可能的位置查找
        for location in ${jar_locations[$jar_name]}; do
            local source_path="$img_port_dir/$location"
            if [ -f "$source_path" ]; then
                cp "$source_path" "$output_dir/$jar_name"
                local file_size
                file_size=$(stat -c%s "$output_dir/$jar_name" 2>/dev/null || stat -f%z "$output_dir/$jar_name" 2>/dev/null)
                log_success "找到 $jar_name ($file_size bytes) at $location"
                found=1
                ((found_jars++))
                break
            fi
        done
        
        if [ $found -eq 0 ]; then
            log_warning "未找到 $jar_name"
        fi
    done
    
    # 如果找到的JAR太少，尝试搜索整个目录
    if [ $found_jars -lt 2 ]; then
        log_info "找到的JAR文件太少，尝试全局搜索..."
        
        # 搜索所有.jar文件
        while IFS= read -r -d '' jar_file; do
            local jar_name
            jar_name=$(basename "$jar_file")
            
            # 检查是否是目标JAR文件
            for target_jar in "${!jar_locations[@]}"; do
                if [[ "$jar_name" == *"$target_jar"* ]] || [[ "$target_jar" == *"${jar_name%.*}"* ]]; then
                    cp "$jar_file" "$output_dir/$target_jar"
                    log_success "通过搜索找到 $target_jar"
                    ((found_jars++))
                    break
                fi
            done
        done < <(find "$img_port_dir" -type f -name "*.jar" -print0 2>/dev/null)
    fi
    
    if [ $found_jars -gt 0 ]; then
        log_success "共找到 $found_jars 个JAR文件"
        return 0
    else
        log_error "未找到任何JAR文件"
        return 1
    fi
}

# 根据设备代号获取设备名称
get_device_name() {
    local codename="$1"
    local user_device_name="$2"
    local auto_yes="$3"
    
    # 如果用户提供了设备名称，直接使用
    if [ -n "$user_device_name" ]; then
        echo "$user_device_name"
        return 0
    fi
    
    # 从设备映射中查找
    if [ -n "${DEVICE_MAP[$codename]}" ]; then
        echo "${DEVICE_MAP[$codename]}"
        return 0
    fi
    
    # 如果未找到，询问用户设备名称（除非是CI环境或自动确认模式）
    if [ "$IS_CI_ENV" = "true" ] || [ "$auto_yes" = "true" ]; then
        # CI环境或自动确认模式：使用设备代号
        echo "$codename"
        log_warning "未找到设备代号 '$codename' 对应的设备名称，将使用设备代号作为设备名称"
        return 0
    fi
    
    # 非CI环境，询问用户
    log_warning "未找到设备代号 '$codename' 对应的设备名称"
    echo -e "${YELLOW}请为设备代号 '$codename' 输入完整的设备名称${NC}"
    echo "例如: 'Xiaomi Pad 6', 'Redmi Note 12 Pro', 'POCO F5'"
    echo "如果不知道设备名称，可以直接按回车使用设备代号 '$codename'"
    echo -n "设备名称: "
    read -r user_input
    
    if [ -n "$user_input" ]; then
        # 用户输入了设备名称
        echo "$user_input"
        log_info "已记录设备代号 '$codename' 的设备名称: $user_input"
    else
        # 用户未输入，使用设备代号
        echo "$codename"
        log_warning "未提供设备名称，将使用设备代号 '$codename' 作为设备名称"
    fi
    
    return 0
}

# 调用patcher脚本
call_patcher() {
    local android_version="$1"
    local codename="$2"
    local version="$3"
    local device_name="$4"
    local features="$5"
    local output_dir="$6"
    local auto_yes="$7"
    
    log_info "调用patcher脚本..."
    log_info "Android版本: $android_version"
    log_info "设备代号: $codename"
    log_info "版本: $version"
    
    # 获取设备名称
    local full_device_name
    full_device_name=$(get_device_name "$codename" "$device_name" "$auto_yes")
    log_info "设备名称: $full_device_name"
    
    log_info "功能: $features"
    
    # 确定patcher脚本和API级别
    local patcher_script=""
    local api_level=""
    
    case "$android_version" in
        13)
            patcher_script="patcher_a13.sh"
            api_level="33"
            ;;
        14)
            patcher_script="patcher_a14.sh"
            api_level="34"
            ;;
        15)
            patcher_script="patcher_a15.sh"
            api_level="35"
            ;;
        16)
            patcher_script="patcher_a16.sh"
            api_level="36"
            ;;
        *)
            log_error "不支持的Android版本: $android_version"
            return 1
            ;;
    esac
    
    # 检查patcher脚本是否存在
    if [ ! -f "$SCRIPT_DIR/$patcher_script" ]; then
        log_error "patcher脚本不存在: $patcher_script"
        return 1
    fi
    
    # 构建功能参数
    local feature_args=""
    if [ -n "$features" ]; then
        # 将逗号分隔的功能列表转换为参数
        IFS=',' read -ra feature_array <<< "$features"
        for feature in "${feature_array[@]}"; do
            feature="${feature//_/-}"  # 将下划线替换为连字符
            feature_args="$feature_args --$feature"
        done
    else
        # 默认功能
        feature_args="--disable-signature-verification"
    fi
    
    # 切换到输出目录
    cd "$output_dir" || {
        log_error "无法切换到输出目录: $output_dir"
        return 1
    }
    
    # 确保patcher脚本有执行权限
    chmod +x "$SCRIPT_DIR/$patcher_script" 2>/dev/null || true
    
    # 构建JAR参数（基于当前目录存在的JAR文件）
    local jar_args=""
    for jar_file in framework.jar services.jar miui-services.jar miui-framework.jar; do
        if [ -f "$jar_file" ]; then
            jar_name="${jar_file%.jar}"
            jar_name="${jar_name//-/_}"  # 将连字符替换为下划线
            jar_args="$jar_args --$jar_name"
        fi
    done
    
    # 如果没有任何JAR参数，使用默认参数
    if [ -z "$jar_args" ]; then
        log_warning "未找到任何JAR文件，使用默认参数"
        jar_args="--framework --services --miui-services --miui-framework"
    fi
    
    # 执行patcher脚本
    log_info "执行命令:"
    log_info "  $SCRIPT_DIR/$patcher_script \\"
    log_info "    $api_level \\"
    log_info "    \"$codename\" \\"
    log_info "    \"$version\" \\"
    log_info "    \"$full_device_name\" \\"
    log_info "    $jar_args \\"
    log_info "    $feature_args"
    
    "$SCRIPT_DIR/$patcher_script" \
        "$api_level" \
        "$codename" \
        "$version" \
        "$full_device_name" \
        $jar_args \
        $feature_args
    
    local patcher_result=$?
    
    if [ $patcher_result -eq 0 ]; then
        log_success "patcher脚本执行成功"
        
        # 检查是否生成了模块文件
        local module_file
        module_file=$(ls Framework-Patcher-"$codename"*.zip 2>/dev/null | head -n1)
        
        if [ -n "$module_file" ] && [ -f "$module_file" ]; then
            local module_size
            module_size=$(stat -c%s "$module_file" 2>/dev/null || stat -f%z "$module_file" 2>/dev/null)
            log_success "模块文件已创建: $module_file ($module_size bytes)"
            echo "$module_file"
            return 0
        else
            log_error "未找到生成的模块文件"
            return 1
        fi
    else
        log_error "patcher脚本执行失败 (退出码: $patcher_result)"
        return 1
    fi
}

# 清理临时文件
cleanup() {
    local keep_files="$1"
    local output_dir="$2"
    
    if [ "$keep_files" = "true" ]; then
        log_info "保留中间文件（根据 -k 参数）"
        return 0
    fi
    
    log_info "清理临时文件..."
    
    # 清理提取的目录
    rm -rf "$output_dir/mods" 2>/dev/null || true
    rm -rf "$output_dir/img_port" 2>/dev/null || true
    
    # 清理下载的ROM文件（保留原始JAR）
    for file in "$output_dir"/*.img "$output_dir"/update.zip; do
        rm -f "$file" 2>/dev/null || true
    done
    
    log_success "清理完成"
}

# 主函数
main() {
    # 初始化日志
    init_log
    
    # 解析命令行参数
    local rom_path=""
    local output_dir="$WORK_DIR"
    local features=""
    local device_name=""
    local keep_files="false"
    local verbose="false"
    local auto_yes="false"
    
    # 解析选项
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output-dir)
                output_dir="$2"
                shift 2
                ;;
            -f|--features)
                features="$2"
                shift 2
                ;;
            -d|--device-name)
                device_name="$2"
                shift 2
                ;;
            -k|--keep-files)
                keep_files="true"
                shift
                ;;
            -v|--verbose)
                verbose="true"
                set -x  # 开启调试模式
                shift
                ;;
            -y|--yes)
                auto_yes="true"
                shift
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                rom_path="$1"
                shift
                ;;
        esac
    done
    
    # 如果auto_yes为true，设置IS_CI_ENV为true以跳过交互
    if [ "$auto_yes" = "true" ]; then
        IS_CI_ENV="true"
        echo -e "${YELLOW}[自动确认模式] 将自动处理所有用户交互${NC}"
    fi
    
    # 检查ROM路径
    if [ -z "$rom_path" ]; then
        log_error "必须提供ROM路径或URL"
        show_help
        exit 1
    fi
    
    # 创建输出目录
    mkdir -p "$output_dir"
    log_info "输出目录: $output_dir"
    
    # 安装依赖
    install_dependencies
    
    # 检查工具
    if ! check_tools; then
        log_error "工具检查失败"
        exit 1
    fi
    
    # 设置权限
    set_permissions
    
    # 解析ROM信息
    local rom_info
    rom_info=$(parse_rom_info "$rom_path")
    if [ $? -ne 0 ]; then
        log_error "ROM信息解析失败"
        exit 1
    fi
    
    # 提取解析结果
    IFS=',' read -r codename version android_version <<< "$rom_info"
    
    log_info "开始构建流程..."
    log_info "设备代号: $codename"
    log_info "MIUI版本: $version"
    log_info "Android版本: $android_version"
    
    # 获取ROM文件路径
    local rom_file_path=""
    
    if [[ "$rom_path" =~ ^http ]]; then
        # 下载ROM文件
        log_info "从URL下载ROM..."
        rom_file_path=$(download_rom "$rom_path" "$output_dir")
        if [ $? -ne 0 ]; then
            log_error "ROM下载失败"
            exit 1
        fi
    else
        # 使用本地ROM文件
        if [ ! -f "$rom_path" ]; then
            log_error "本地ROM文件不存在: $rom_path"
            exit 1
        fi
        
        # 检查文件类型
        if file "$rom_path" | grep -q "Zip archive"; then
            rom_file_path="$rom_path"
            log_info "使用本地ROM文件: $rom_path"
        else
            log_error "文件不是有效的ZIP压缩包: $rom_path"
            exit 1
        fi
    fi
    
    # 提取ROM
    log_info "提取ROM文件..."
    local img_port_dir
    img_port_dir=$(extract_rom "$rom_file_path" "$output_dir")
    if [ $? -ne 0 ]; then
        log_error "ROM提取失败"
        exit 1
    fi
    
    # 查找并复制JAR文件
    log_info "复制JAR文件..."
    if ! find_and_copy_jars "$img_port_dir" "$output_dir"; then
        log_error "JAR文件复制失败"
        exit 1
    fi
    
    # 调用patcher脚本
    log_info "开始修补流程..."
    local module_file
    module_file=$(call_patcher \
        "$android_version" \
        "$codename" \
        "$version" \
        "$device_name" \
        "$features" \
        "$output_dir" \
        "$auto_yes")
    
    if [ $? -eq 0 ]; then
        log_success "==========================================="
        log_success "构建成功完成！"
        log_success "生成的模块文件: $module_file"
        log_success "输出目录: $output_dir"
        log_success "==========================================="
        
        # 显示文件信息
        echo ""
        echo "📦 构建结果:"
        echo "  ├─ 设备: $(get_device_name "$codename" "$device_name" "$auto_yes")"
        echo "  ├─ 代号: $codename"
        echo "  ├─ 版本: $version"
        echo "  ├─ Android: $android_version"
        echo "  └─ 模块文件: $(basename "$module_file")"
        echo ""
        
        # 复制模块文件到当前目录（如果输出目录不同）
        if [ "$output_dir" != "$WORK_DIR" ] && [ -f "$module_file" ]; then
            cp "$module_file" "$WORK_DIR/"
            log_info "已将模块文件复制到: $WORK_DIR/$(basename "$module_file")"
        fi
    else
        log_error "构建失败"
        exit 1
    fi
    
    # 清理临时文件
    cleanup "$keep_files" "$output_dir"
    
    # 记录结束时间
    echo "构建结束时间: $(date)" >> "$LOG_FILE"
    echo "构建状态: 成功" >> "$LOG_FILE"
    echo "===========================================" >> "$LOG_FILE"
    
    log_info "详细日志请查看: $LOG_FILE"
    return 0
}

# 运行主函数
main "$@"