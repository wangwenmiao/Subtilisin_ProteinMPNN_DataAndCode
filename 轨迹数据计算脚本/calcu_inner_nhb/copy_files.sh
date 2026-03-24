#!/bin/bash
# File: /home/user/project/copy_directories_cp.sh

# 目标目录
TARGET_DIR="/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/inner_nhb"

# 需要复制的文件夹列表
FOLDERS_TO_COPY=(
    "4907_ca_2_apo"
    "17831_ca_2_apo"
    "4907_ca_2_holo"
    "17831_ca_2_holo"
    # "11117_ca_2_apo"
    # "wt_ca_2_holo"
    # "1648_ca_2_holo"
    # "11117_ca_2_holo"
    # "wt_ca_2_apo"
    # "1648_ca_2_apo"

    # "wt_ca_2_apo_373k"
    # "1648_ca_2_apo_373k"
    # "4907_ca_2_apo_373k"
    # "11117_ca_2_apo_373k"
    # "17831_ca_2_apo_373k"
    # "1648_ca_2_apo_473k"
    # "4907_ca_2_apo_473k"
    # "11117_ca_2_apo_473k"
    # "17831_ca_2_apo_473k"
    # "wt_ca_2_apo_573k"
    # "1648_ca_2_apo_573k"
    # "4907_ca_2_apo_573k"
    # "11117_ca_2_apo_573k"
    # "17831_ca_2_apo_573k"
    # "4519_subtilisin_120ns_ace_aapfa_nme_HID"
)

# 忽略的文件名列表（使用find命令的模式）
IGNORE_FILES=(
"inner_nhb.dat"
"inner_avghb.dat"
#"first_shell_water_index_0.325000.dat"
#"first_shell_water_index_0.320000.dat"

)
# "complex.prmtop"
# "complex_solv.inpcrd"
# "complex_solv.prmtop"
# "dry_complex.inpcrd"
# "dry_complex.prmtop"
# "eps.pdb"
# "ligand.prmtop"
# "receptor.prmtop"
# "complex.tpr"

# "pca_eigenval.dat"
# "pca_protein.dat"
# "rg.dat"
# "rmsd_output.dat"
# "rmsf_output.dat"
# "avghbp.dat"
# "avghbw.dat"
# "nhbp.dat"
# "nhbw.dat"
# "area.xvg"
# "contacts_0_4nm.xvg"
# "mindist_0_4nm.xvg"
# "contacts_0_6nm.xvg"
# "mindist_0_6nm.xvg"
# "first_shell_water_0.325000.xvg"
# "first_shell_water_0.320000.xvg"
# 创建目标目录（如果不存在）
mkdir -p "$TARGET_DIR"

# 函数：检查文件是否应该被忽略
should_ignore() {
    local file="$1"
    local basename=$(basename "$file")

    for pattern in "${IGNORE_FILES[@]}"; do
        if [[ "$basename" == $pattern ]]; then
            return 0  # 应该忽略
        fi
    done
    return 1  # 不应该忽略
}

# 函数：复制目录并排除指定文件
copy_directory() {
    local source_dir="$1"
    local target_dir="$2"

    # 创建目标目录
    mkdir -p "$target_dir"

    # 使用find遍历所有文件和目录
    # find "$source_dir" -type f -mtime -10| while read -r file; do
    find "$source_dir" -type f| while read -r file; do
        if should_ignore "$file"; then
            # 计算相对路径
            relative_path="${file#$source_dir/}"
            target_file="$target_dir/$relative_path"

            # 创建目标文件的目录
            mkdir -p "$(dirname "$target_file")"

            # 复制文件
            cp "$file" "$target_file"
        fi
    done
}

# 复制指定的文件夹
for folder in "${FOLDERS_TO_COPY[@]}"; do
    if [ -d "$folder" ]; then
        echo "正在复制文件夹: $folder"
        copy_directory "$folder" "$TARGET_DIR/$folder"
        echo "文件夹 $folder 复制完成"
    else
        echo "警告: 文件夹 $folder 不存在，跳过"
    fi
done

echo "所有指定文件夹复制完成！"
