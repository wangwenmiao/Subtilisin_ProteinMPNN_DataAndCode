#!/bin/bash

# 定义脚本开始执行的基础目录
BASE_DIR="/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID"

# 默认值
TARGET_DIR=""
STEPS=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -s|--step)
            STEPS="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 -d <目录> -s <步骤>"
            echo "  -d, --dir   指定目录名称（如 _2654_ca* 或 _wt_test）"
            echo "  -s, --step  指定执行步骤（123 的组合）"
            echo "              1: 当前目录串行执行代码"
            echo "              2: 创建目录并复制文件到 md1..10"
            echo "              3: 串行进入 md1..10 执行代码"
            echo "示例: $0 -d _wt_test -s 13"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 -h 查看帮助"
            exit 1
            ;;
    esac
done

# 检查必需参数
if [ -z "$TARGET_DIR" ] || [ -z "$STEPS" ]; then
    echo "错误: 必须指定目录和步骤"
    echo "使用 -h 查看帮助"
    exit 1
fi

echo "脚本在以下目录开始运行: $BASE_DIR"
echo "目标目录: $TARGET_DIR"
echo "执行步骤: $STEPS"

# 构建目录路径
dir="$BASE_DIR/$TARGET_DIR"
if [ ! -d "$dir" ]; then
    echo "❌ 目录不存在: $dir"
    exit 1
fi

pushd "$dir" > /dev/null

# 根据步骤参数执行相应的步骤
for (( i=0; i<${#STEPS}; i++ )); do
    step="${STEPS:$i:1}"
    case $step in
        1)
            echo ""
            echo "🔧 执行步骤1：在当前目录串行执行代码"
            # 替换为你要在当前目录执行的命令
            pwd
            bash /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles_nvt_300k_md/md_min_heat_equil_gpu1.sh
            ;;
        2)
            echo ""
            echo "📂 执行步骤2：创建 md1..10 并复制当前目录内容"
            for j in $(seq 1 3); do
                md_dir="md$j"
                if [ ! -d "$md_dir" ]; then
                    echo "  创建子目录: $md_dir"
                    mkdir -p "$md_dir"
                else
                    echo "  子目录已存在: $md_dir"
                fi
                echo "  复制文件到 '$md_dir'..."
                find . -maxdepth 1 -type f -exec cp {} "$md_dir"/ \;
            done
            ;;
        3)
            echo ""
            echo "🚀 执行步骤3：串行进入 md1..10 执行代码"
            for j in $(seq 1 3); do
                md_dir="md$j"
                if [ -d "$md_dir" ]; then
                    echo "  → 进入 $(realpath "$md_dir") 并执行命令"
                    pushd "$md_dir" > /dev/null
                    # 替换为你要在 md 子目录执行的命令
                    pwd
                    bash /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles_nvt_300k_md/md_pro_gpu1.sh
                    popd > /dev/null
                else
                    echo "  ⚠️ 目录 $md_dir 不存在，跳过"
                fi
            done
            ;;
        *)
            echo "❌ 无效步骤: $step"
            ;;
    esac
done

popd > /dev/null

echo "---"
echo "全部步骤执行完毕。"

