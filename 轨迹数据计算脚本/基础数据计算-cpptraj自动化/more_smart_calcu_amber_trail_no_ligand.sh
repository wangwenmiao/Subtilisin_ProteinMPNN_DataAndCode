#!/bin/bash
# 最大并发数（比如 4 个 GPU 或 4 核 CPU）
MAX_JOBS=1
# 默认值
DEFAULT_DIR=""
DEFAULT_STEPS=""
# 生成cpptraj输入文件的Python函数
generate_cpptraj_inputs(){
    echo "🐍 正在生成cpptraj输入文件..."
    python3 << 'EOF'
def extract_residue_labels(prmtop_file):
    """
    从prmtop文件中提取RESIDUE_LABEL部分的内容，去除水分子和离子

    Parameters:
    -----------
    prmtop_file : str
        prmtop文件路径

    Returns:
    --------
    clean_residues : list
        清理后的残基列表
    """
    try:
        with open(prmtop_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # 查找RESIDUE_LABEL标志的开始位置
        start_flag = "%FLAG RESIDUE_LABEL"
        end_flag = "%FLAG RESIDUE_POINTER"

        start_pos = content.find(start_flag)
        if start_pos == -1:
            print("未找到 %FLAG RESIDUE_LABEL 标志")
            return []

        end_pos = content.find(end_flag, start_pos)
        if end_pos == -1:
            print("未找到 %FLAG RESIDUE_POINTER 标志")
            return []

        # 提取两个标志之间的文本
        residue_section = content[start_pos:end_pos]

        # 跳过标志行和格式行，提取实际的残基数据
        lines = residue_section.split('\n')
        residue_data = []

        # 跳过前两行（标志行和格式行）
        for line in lines[2:]:
            line = line.strip()
            if line and not line.startswith('%'):
                residue_data.append(line)

        # 将所有行合并并分割成单个残基
        all_residues_text = ' '.join(residue_data)
        all_residues = all_residues_text.split()

        # 定义要过滤的残基/离子类型
        filter_out = {'WAT', 'Na+', 'Cl-'}

        # 过滤掉水分子和离子
        clean_residues = [res.strip() for res in all_residues if res.strip() not in filter_out]

        return clean_residues

    except FileNotFoundError:
        print(f"文件 {prmtop_file} 未找到")
        return []
    except Exception as e:
        print(f"读取文件时出错: {e}")
        return []


def print_residue_sequence(prmtop_file):
    """
    打印清理后的残基序列，并找到特定残基模式和CA的索引

    Parameters:
    -----------
    prmtop_file : str
        prmtop文件路径

    Returns:
    --------
    tuple : (residues, aapa_indices, ca_index)
        residues: 清理后的残基列表
        aapa_indices: ALA ALA PRO ALA 连续四个残基的索引列表
        ca_index: CA残基的索引
    """
    residues = extract_residue_labels(prmtop_file)
    aapa_indices = []
    ca_index = None

    if residues:
        print(f"提取到 {len(residues)} 个蛋白质残基:")
        print("-" * 60)

        # 每行打印20个残基
        for i in range(0, len(residues), 20):
            line_residues = residues[i:i + 20]
            line_numbers = [str(j + 1).rjust(3) for j in range(i, min(i + 20, len(residues)))]

            print("位置: " + " ".join(line_numbers))
            print("残基: " + " ".join([res.ljust(3) for res in line_residues]))
            print()

        # 打印连续的单字母序列（如果需要转换的话）
        print("完整序列:")
        print(" ".join(residues))
        print()

        # 查找 ALA ALA PRO ALA 连续四个残基的索引
        # target_pattern = ['ALA', 'ALA', 'PRO', 'ALA']
        target_pattern = ['ACE', 'ALA', 'ALA', 'PRO', 'PHE', 'ALA', 'NME']
        for i in range(len(residues) - len(target_pattern) + 1):
            if residues[i:i + len(target_pattern)] == target_pattern:
                aapa_indices = list(range(i, i + len(target_pattern)))  # 0-based索引
                print(f"找到 ACE ALA ALA PRO PHE ALA NME 模式:")
                print(f"  位置: {[idx + 1 for idx in aapa_indices]} (1-based)")
                print(f"  索引: {aapa_indices} (0-based)")
                print(f"  残基: {[residues[idx] for idx in aapa_indices]}")
                break

        if not aapa_indices:
            print("未找到 ACE ALA ALA PRO PHE ALA NME 连续模式")
           

        # 查找 CA 残基的索引
        ca_indices = []
        for i, res in enumerate(residues):
            if res == 'CA':
                ca_indices.append(i)

        if ca_indices:
            print(f"\n找到 CA 残基:")
            for ca_index in ca_indices:
                print(f"  位置: {ca_index + 1} (1-based)")
                print(f"  索引: {ca_index} (0-based)")
        else:
            print("\n未找到 CA 残基")

        # 生成用于cpptraj的索引字符串
        print("\n" + "=" * 60)
        print("CPPTRAJ 索引信息:")
        print("=" * 60)

        if aapa_indices:
            # cpptraj使用1-based索引
            aapa_cpptraj = [idx + 1 for idx in aapa_indices]

            # 检查索引是否连续
            is_continuous = all(aapa_cpptraj[i] == aapa_cpptraj[i - 1] + 1 for i in range(1, len(aapa_cpptraj)))

            if is_continuous and len(aapa_cpptraj) > 1:
                # 如果连续且有多个索引，使用范围格式
                aapa_format = f"{aapa_cpptraj[0]}-{aapa_cpptraj[-1]}"
            else:
                # 如果不连续或只有一个索引，使用逗号分隔格式
                aapa_format = ','.join(map(str, aapa_cpptraj))

            print(f"ALA ALA PRO ALA 残基索引 (cpptraj格式): :{aapa_format}")
        if not aapa_indices:
        
            print("未找到 ACE ALA ALA PRO PHE ALA NME 连续模式")
            aapa_format = ""
            

        if ca_indices:
            ca_cpptraj = ','.join(str(idx + 1) for idx in ca_indices)
            print(f"CA 残基索引 (cpptraj格式):{ca_cpptraj}")

        # 生成蛋白质索引范围（排除CA和特定模式）
        protein_indices = []
        exclude_indices = set(aapa_indices) if aapa_indices else set()
        if ca_index is not None:
            for ca_item in ca_indices:
                exclude_indices.add(ca_item)

        for i, res in enumerate(residues):
            if i not in exclude_indices:
                protein_indices.append(i + 1)  # 转换为1-based



        if protein_indices:
            # 生成连续范围的字符串
            ranges = []
            start = protein_indices[0]
            end = start

            for idx in protein_indices[1:]:
                if idx == end + 1:
                    end = idx
                else:
                    if start == end:
                        ranges.append(str(start))
                    else:
                        ranges.append(f"{start}-{end}")
                    start = end = idx
            # 添加最后一个范围
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append(f"{start}-{end}")

            print(f"其他蛋白质残基索引 (cpptraj格式):{','.join(ranges)}")

        print(f"蛋白质残基索引是{protein_indices}")
        print(f"底物残基索引是{aapa_indices}")
        print(f"钙离子残基索引是{ca_indices}")

    else:
        print("未提取到任何残基")

    return ranges[0], aapa_format, ca_cpptraj



center = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
rms first :protein_index@CA
trajout centered.nc
go
quit"""

hbondp = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
hbond donormask :protein_index acceptormask :WAT out nhbp.dat avgout avghbp.dat
go
quit"""

hbondw = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
hbond donormask :WAT acceptormask :protein_index out nhbw.dat avgout avghbw.dat
go
quit"""

pca_amber = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
rms first :protein_index@CA
average crdset AVG
run
rms ref AVG :protein_index@CA
matrix covar name CovarMatrix :protein_index@CA
createcrd CRD1
run
runanalysis diagmatrix CovarMatrix out pca_eigenval.dat vecs 200 name Evecs
crdaction CRD1 projection evecs Evecs :protein_index@CA out pca_protein.dat beg 1 end 2
run"""

rg = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
strip :WAT
radgyr :protein_index&!(@H=) out rg.dat mass nomax
go"""

sasa = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
rms first :protein_index@CA
surf out surf.dat
go"""

sasa_complex = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
rms first :protein_index@CA
surf :complex_index out surf_complex.dat
go"""

sasa_ligand = """parm complex_solv.prmtop
trajin centered.nc
surf :ligand_index out surf_ligand.dat
go"""

sasa_protein = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
rms first :protein_index@CA
surf :protein_index out surf_protein.dat
go"""

stable = """parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
rms first :protein_index@CA
rmsd RMSD_Calpha :protein_index@CA out rmsd_output.dat
rmsf RMSF_Calpha :protein_index@CA out rmsf_output.dat
go"""


receptor_prmtop = """#!/bin/bash
rm -rf receptor.prmtop
parmed complex_solv.prmtop << EOF
strip :WAT
strip :Na+
strip :Cl-
outparm receptor.prmtop
quit
EOF"""

ligand_prmtop = """#!/bin/bash
rm -rf ligand.prmtop
parmed complex_solv.prmtop << EOF
strip :complex_index
strip :WAT
strip :Na+
strip :Cl-
outparm ligand.prmtop
quit
EOF"""

complex_prmtop = """#!/bin/bash
rm -rf complex.prmtop
parmed complex_solv.prmtop << EOF
strip :WAT
strip :Na+
strip :Cl-
outparm complex.prmtop
quit
EOF"""


# 创建脚本名称和内容的字典
scripts = {
    'center': center,
    'hbondp': hbondp,
    'hbondw': hbondw,
    'pca_amber': pca_amber,
    'rg': rg,
    'sasa': sasa,
    'sasa_complex': sasa_complex,
    'sasa_protein': sasa_protein,
    'stable': stable,
    'receptor_prmtop': receptor_prmtop,
    'complex_prmtop': complex_prmtop
}

import os

protein_index, aapa_indices, ca_index = print_residue_sequence("complex_solv.prmtop")
print(protein_index, aapa_indices, ca_index)
# 创建 inputfiles 文件夹
output_dir = "inputfiles_calcu_trail"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
    print(f"创建文件夹: {output_dir}")
else:
    print(f"文件夹已存在: {output_dir}")

# 处理每个脚本
for script_name, script_content in scripts.items():
    # 初始化更新后的脚本内容
    updated_para = script_content

    # 进行字符串替换
    if "protein_index" in updated_para:
        updated_para = updated_para.replace("protein_index", f"{protein_index}")

    if "complex_index" in updated_para:
        # 根据需要调整complex_index的值
        complex_value = f"{protein_index},{ca_index}" if ca_index else protein_index
        updated_para = updated_para.replace("complex_index", f"{complex_value}")

    if "ligand_index" in updated_para:
        updated_para = updated_para.replace("ligand_index", f"{aapa_indices}")

    # 构建文件路径，将文件保存在 inputfiles 文件夹中
    file_path = os.path.join(output_dir, f'{script_name}.cpp')

    # 写入文件
    with open(file_path, 'w') as f:
        f.write(updated_para)

    print(f"Generated {file_path}")
EOF

    if [ $? -eq 0 ]; then
        echo "✅ Python脚本执行成功，输入文件已生成"
    else
        echo "❌ Python脚本执行失败"
        exit 1
    fi
}
# bcdehij
# 定义所有可用的命令
declare -a COMMANDS=(
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/center.cpp"
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/hbondw.cpp"
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/hbondp.cpp"
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/stable.cpp"
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/rg.cpp"
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/sasa_protein.cpp"
    "mpirun -n 24 cpptraj.MPI -i ../inputfiles_calcu_trail/sasa_complex.cpp"
    "cpptraj.cuda -i ../inputfiles_calcu_trail/pca_amber.cpp"
    "bash ../inputfiles_calcu_trail/receptor_prmtop.cpp"
    "bash ../inputfiles_calcu_trail/complex_prmtop.cpp"
)

# 命令描述
declare -a COMMAND_NAMES=(
    "center"
    "hbondw"
    "hbondp"
    "stable"
    "rg"
    "sasa_protein"
    "sasa_complex"
    "pca_amber"
    "receptor_prmtop"
    "complex_prmtop"
)

# 显示帮助信息
show_help() {
    echo "用法: $0 [-d directory] [-s steps] [-j max_jobs] [-h]"
    echo ""
    echo "参数说明:"
    echo "  -d directory   指定要处理的目录名 (默认: $DEFAULT_DIR)"
    echo "  -s steps       指定要执行的步骤，用字母表示 (默认: $DEFAULT_STEPS)"
    echo "                 例如: -s abcd 表示执行前4个命令"
    echo "                      -s bchi 表示执行第2,3,8,9个命令"
    echo "  -j max_jobs    最大并发任务数 (默认: $MAX_JOBS)"
    echo "  -h             显示此帮助信息"
    echo ""
    echo "可用的命令步骤:"
    for i in "${!COMMAND_NAMES[@]}"; do
        letter=$(printf "\\$(printf '%03o' $((97+i)))")
        echo "  $letter. ${COMMAND_NAMES[$i]}"
    done
    echo ""
    echo "示例:"
    echo "  $0 -d _wt_ca -s abcd        # 在_wt_ca目录执行前4个命令"
    echo "  $0 -d _mutant -s bchi       # 在_mutant目录执行第2,3,8,9个命令"
    echo "  $0 -s aei -j 8              # 执行第1,5,9个命令，最大8个并发"
}

# 解析命令行参数
TARGET_DIR="$DEFAULT_DIR"
STEPS="$DEFAULT_STEPS"

while getopts "d:s:j:h" opt; do
    case $opt in
        d)
            TARGET_DIR="$OPTARG"
            ;;
        s)
            STEPS="$OPTARG"
            ;;
        j)
            MAX_JOBS="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "无效的选项: -$OPTARG" >&2
            show_help
            exit 1
            ;;
    esac
done

# 验证步骤参数
if ! [[ "$STEPS" =~ ^[a-z]+$ ]]; then
    echo "错误: 步骤参数只能包含小写字母a-z" >&2
    exit 1
fi

# 验证并发数参数
if ! [[ "$MAX_JOBS" =~ ^[0-9]+$ ]] || [ "$MAX_JOBS" -lt 1 ]; then
    echo "错误: 最大并发数必须是正整数" >&2
    exit 1
fi

# 定义脚本开始执行的基础目录
BASE_DIR="$(dirname "$(realpath "$0")")"
echo "脚本在以下目录开始运行: $BASE_DIR"
echo "目标目录: $TARGET_DIR"
echo "执行步骤: $STEPS"
echo "最大并发数: $MAX_JOBS"

# 解析要执行的命令
SELECTED_COMMANDS=()
SELECTED_NAMES=()

for (( i=0; i<${#STEPS}; i++ )); do
    step_char="${STEPS:$i:1}"
    if [[ "$step_char" =~ ^[a-z]$ ]]; then
        index=$(($(printf '%d' "'$step_char") - 97))
        if [ $index -lt ${#COMMANDS[@]} ]; then
            SELECTED_COMMANDS+=("${COMMANDS[$index]}")
            SELECTED_NAMES+=("${COMMAND_NAMES[$index]}")
        else
            echo "警告: 步骤 $step_char 超出范围，忽略"
        fi
    fi
done

if [ ${#SELECTED_COMMANDS[@]} -eq 0 ]; then
    echo "错误: 没有有效的命令可执行"
    exit 1
fi

echo "将执行以下命令:"
for i in "${!SELECTED_NAMES[@]}"; do
    echo "  $((i+1)). ${SELECTED_NAMES[$i]}"
done
echo ""

# 执行命令

# 在目标目录执行generate_cpptraj_inputs函数
target_dir="$BASE_DIR"/$TARGET_DIR
if [ -d "$target_dir" ]; then
    (
        cd "$target_dir" || exit
        echo "📂 当前路径: $(pwd)"

        # 只生成cpptraj输入文件
        generate_cpptraj_inputs

        echo "✅ cpptraj输入文件生成完成"
    )
else
    echo "错误: 目录 $target_dir 不存在"
    exit 1
fi


# 然后在每个md目录中执行cpptraj命令
# 先收集所有目录
declare -a ALL_DIRS=()
for dir in "$BASE_DIR"/$TARGET_DIR/md*/; do
    if [ -d "$dir" ]; then
        ALL_DIRS+=("$dir")
    fi
done

echo "找到 ${#ALL_DIRS[@]} 个md目录"

# 对每个命令，在所有目录中并行执行
for cmd in "${SELECTED_COMMANDS[@]}"; do
    echo "🔄 开始执行命令: $cmd"
    
    # 在所有目录中并行执行当前命令
    for dir in "${ALL_DIRS[@]}"; do
        (
            cd "$dir" || exit
            echo "📂 目录: $(basename "$dir") | 执行: $cmd"
            eval "$cmd"
            echo "✅ 目录: $(basename "$dir") | 命令: $cmd 执行完成"
        ) &
        
        # 控制并发数：检查后台任务数:
        while (( $(jobs -r | wc -l) >= MAX_JOBS )); do
            sleep 1
        done
    done
    
    # 等待当前命令在所有目录中执行完毕
    wait
    echo "✅ 命令 $cmd 在所有目录中执行完毕"
done

# 等待所有任务完成
echo "✅ 所有命令在所有目录中执行完毕！"
