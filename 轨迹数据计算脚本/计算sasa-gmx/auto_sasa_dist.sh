#!/bin/bash
# File: D:\pycharm_projects\pymol\MPNN_2\标准代码\使用gmx计算溶剂可极性面积和近距离原子接触\auto_sasa_dist.sh

# ============================================
# 批量处理 MD 模拟数据的脚本
# 功能：遍历多个目录，对每个目录下的 md1-md10 子目录执行一系列命令
# ============================================

set -uo pipefail

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================
# 配置区域 - 请根据实际情况修改
# ============================================

# 定义需要处理的目录列表
DIRECTORY_LIST=(
"/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo"
)
: <<'END_COMMENT'
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/wt_ca_2"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/wt_ca_2_apo"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/11117_ca_2"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/11117_ca_2_apo"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/1648_ca_2"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/1648_ca_2_apo"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo"
END_COMMENT

# 定义 md 子目录的数量（1-10）
MD_START=1
MD_END=10

# 定义工具路径
ACPYPE_CONVERT_SCRIPT="/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/gmx_calcu_sasa/input-files/acpype.py"
CONVERT_SCRIPT="/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/gmx_calcu_sasa/input-files/convert2gmx.py"
NCIC_SCRIPT="/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/gmx_calcu_sasa/input-files/ncic.sh"

# 日志文件
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"
MAIN_LOG="$LOG_DIR/batch_process_$(date '+%Y%m%d_%H%M%S').log"

# ============================================
# 核心处理函数
# ============================================

process_md_directory() {
    local base_dir="$1"
    local md_num="$2"
    local md_dir="${base_dir}/md${md_num}"

    # 为每个任务创建独立的日志文件
    local task_log="$LOG_DIR/md${md_num}_$(basename "$base_dir").log"

    {
        log_info "开始处理: $md_dir"

        # 检查目录是否存在
        if [ ! -d "$md_dir" ]; then
            log_warning "目录不存在，跳过: $md_dir"
            return 1
        fi

        # 进入目录
        cd "$md_dir" || {
            log_error "无法进入目录: $md_dir"
            return 1
        }

        # 检查必需文件
        if [ ! -f "complex_solv.prmtop" ] || [ ! -f "step8_prod_npt.nc" ]; then
            log_error "缺少必需文件: complex_solv.prmtop 或 step8_prod_npt.nc"
            cd - > /dev/null
            return 1
        fi
: <<'COMMENT_BLOCK'
        # 步骤 1: cpptraj 转换
        log_info "步骤 1/7: 运行 cpptraj.cuda..."
        if ! cpptraj -p complex_solv.prmtop -y step8_prod_npt.nc -x complex.trr; then
            log_error "cpptraj.cuda 执行失败"
            cd - > /dev/null
            return 1
        fi

        # 步骤 2: convert2gmx 转换
        log_info "步骤 2/7: 运行 convert2gmx.py..."
        if ! python3 /media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/gmx_calcu_sasa/input-files/acpype.py -p complex_solv.prmtop -x complex_solv.inpcrd; then
            log_error "acpype.py 执行失败"
            cd - > /dev/null
            return 1
        fi
        
        if ! python3 "$CONVERT_SCRIPT"; then
            log_error "convert2gmx.py 执行失败"
            cd - > /dev/null
            return 1
        fi

        # 步骤 3: gmx trjconv
        log_info "步骤 3/7: 运行 gmx trjconv..."
        if ! echo 0 | gmx trjconv -f complex.trr -s complex_solv_GMX.gro -o complex.xtc; then
            log_error "gmx trjconv 执行失败"
            cd - > /dev/null
            return 1
        fi

        # 步骤 4: gmx grompp
        log_info "步骤 4/7: 运行 gmx grompp..."
        if ! gmx grompp -f md.mdp -c complex_solv_GMX.gro -p complex_solv_GMX.top -o complex.tpr -maxwarn 1; then
            log_error "gmx grompp 执行失败"
            cd - > /dev/null
            return 1
        fi

        # 步骤 5: gmx sasa
        log_info "步骤 5/7: 运行 gmx sasa..."
        if ! echo "1" | gmx sasa -f complex.xtc -s complex.tpr -output '"Hydrophobic" group protein and charge {-0.2 to 0.2};"Hydrophilic" group protein and not charge {-0.2 to 0.2}'; then
            log_error "gmx sasa 执行失败"
            cd - > /dev/null
            return 1
        fi
        
        # 步骤 8: 清理 complex.trr（已转换完成，不再需要）
        log_info "步骤 8/7: 清理临时文件 (complex.trr)..."
        if rm -f complex.trr 2>/dev/null; then
            log_info "complex.trr 清理完成"
        else
            log_warning "complex.trr 清理失败或文件不存在"
        fi
COMMENT_BLOCK
     
        # 步骤 6: ncic.sh
        log_info "步骤 6/7: 运行 ncic.sh..."
        if ! bash "$NCIC_SCRIPT"; then
            log_error "ncic.sh 执行失败"
            cd - > /dev/null
            return 1
        fi

        # 步骤 7: 清理临时文件 (只删除 complex.xtc)
        log_info "步骤 7/7: 清理临时文件 (complex.xtc)..."
        if rm -f complex.xtc 2>/dev/null; then
            log_info "complex.xtc 清理完成"
        else
            log_warning "complex.xtc 清理失败或文件不存在"
        fi
        
        
        # 返回原目录
        cd - > /dev/null

        log_info "完成处理: $md_dir"
        return 0

    } > "$task_log" 2>&1
}

# ============================================
# 主程序
# ============================================

main() {
    log_info "=========================================="
    log_info "批量处理脚本开始运行（并行模式）"
    log_info "日志文件: $MAIN_LOG"
    log_info "并行任务数: 16"
    log_info "=========================================="

    # 检查是否安装了 parallel
    if ! command -v parallel &> /dev/null; then
        log_error "未找到 GNU Parallel，请先安装: sudo apt install parallel"
        return 1
    fi

    # 导出函数和变量（正确的方式）
    export -f process_md_directory
    export -f log_info
    export -f log_error
    export -f log_warning
    export CONVERT_SCRIPT
    export NCIC_SCRIPT
    export LOG_DIR
    export RED
    export GREEN
    export YELLOW
    export NC

    # 生成所有任务列表
    local tasks=()
    for base_dir in "${DIRECTORY_LIST[@]}"; do
        if [ ! -d "$base_dir" ]; then
            log_warning "基础目录不存在，跳过: $base_dir"
            continue
        fi
        for md_num in $(seq $MD_START $MD_END); do
            tasks+=("$base_dir $md_num")
        done
    done

    local total_dirs=${#tasks[@]}
    log_info "总任务数: $total_dirs"

    # 使用 parallel 并行处理
    printf '%s\n' "${tasks[@]}" | parallel -j 12 --colsep ' ' --bar \
        'if process_md_directory {1} {2}; then echo "SUCCESS:{1}/md{2}"; else echo "FAILED:{1}/md{2}"; fi' \
        > "$LOG_DIR/parallel_results.txt" 2>&1

    # 统计结果
    local success_count=$(grep -c "SUCCESS:" "$LOG_DIR/parallel_results.txt" 2>/dev/null || echo 0)
    local fail_count=$(grep -c "FAILED:" "$LOG_DIR/parallel_results.txt" 2>/dev/null || echo 0)

    # 输出统计信息
    log_info "=========================================="
    log_info "处理完成！"
    log_info "总目录数: $total_dirs"
    log_info "成功: $success_count"
    log_info "失败: $fail_count"
    log_info "=========================================="

    # 显示失败的任务
    if [ $fail_count -gt 0 ]; then
        log_warning "以下任务执行失败："
        grep "FAILED:" "$LOG_DIR/parallel_results.txt" | sed 's/FAILED:/  - /'
        return 1
    fi

    return 0
}

# 执行主程序并记录日志
main 2>&1 | tee "$MAIN_LOG"

# 保存退出码
