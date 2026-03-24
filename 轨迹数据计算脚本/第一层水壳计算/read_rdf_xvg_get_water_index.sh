#!/bin/bash

# 读取RDF文件并找到第一个谷对应的距离
# RDF (Radial Distribution Function) 用于分析蛋白质周围水分子的分布
# 第一个谷对应于第一个水合壳层的外边界距离
# 用法: ./read_rdf_xvg_get_water_shell_distance.sh /home/yons/wwm_temp/4907_ca_2_apo/rdf.xvg complex.xtc complex.tpr

# ============================================================================
# 第一步：准备工作 - 转换轨迹格式并生成必要的文件
# ============================================================================

# 将AMBER格式转换为GROMACS格式
echo "正在转换轨迹格式..."
cpptraj -p complex_solv.prmtop -y step8_prod_npt.nc -x complex.xtc

# 生成GROMACS拓扑和运行参数文件
echo "正在生成GROMACS拓扑文件..."
gmx grompp -f md.mdp -c complex_solv_GMX.gro -p complex_solv_GMX.top -o complex.tpr -maxwarn 1

# ============================================================================
# 第二步：自动生成索引文件 - 根据gmx make_ndx的输出动态决定命令
# ============================================================================

# 首先获取gmx make_ndx的所有可用组信息
echo "正在分析可用的原子组..."
gmx make_ndx -f complex.tpr -o index_temp.ndx <<EOF
q
EOF

#  0 System              : 36049 atoms
#  1 Protein             :  4053 atoms
#  2 Protein-H           :  2066 atoms
#  3 C-alpha             :   290 atoms
#  4 Backbone            :   870 atoms
#  5 MainChain           :  1161 atoms
#  6 MainChain+Cb        :  1416 atoms
#  7 MainChain+H         :  1443 atoms
#  8 SideChain           :  2610 atoms
#  9 SideChain-H         :   905 atoms
# 10 Prot-Masses         :  4053 atoms
# 11 non-Protein         : 31996 atoms
# 12 Ion                 :     2 atoms
# 13 Other               :    38 atoms
# 14 CA                  :     2 atoms
# 15 Na+                 :    21 atoms
# 16 Cl-                 :    17 atoms
# 17 Water               : 31956 atoms
# 18 SOL                 : 31956 atoms
# 19 non-Water           :  4093 atoms
# 20 Water_and_ions      : 31958 atoms





water_index=$(python3 << 'PYTHON_EOF'
file_path = 'index_temp.ndx'

bracket_count = 0
water_index = 0

with open(file_path, 'r') as f:
    for line in f:
        # 检查这一行是否包括 [
        if '[' in line:
            bracket_count += 1
            # 检查是否是 [ Water ]
            if '[ Water ]' in line:
                water_index = bracket_count
                break

print(water_index)
PYTHON_EOF
)
water_index=$((water_index - 1))
echo "[ Water ] 是第 $water_index 个 ["

total_groups=$(grep -c "^\[" index_temp.ndx)
echo "总共有 $total_groups 个组"

# 新的组号是
new_group_num=$((total_groups - 1 + 1))
echo "新的组号是 $new_group_num"


gmx make_ndx -f complex.tpr -o index.ndx <<EOF
$water_index & a O
name $((total_groups)) Water_O
q
EOF

# 验证索引文件是否成功生成
if [ ! -f "index.ndx" ]; then
    echo "错误：索引文件生成失败"
    exit 1
fi

echo "✓ 索引文件已生成: index.ndx"

# 清理临时文件
rm -f index_temp.ndx

# ============================================================================
# 第四步：处理RDF文件并计算第一层水分子数量
# ============================================================================

# 检查命令行参数
if [ $# -lt 1 ]; then
    echo "用法: $0 <rdf.xvg文件> [traj.xtc文件] [topol.tpr文件]"
    exit 1
fi

# 保存输入的RDF文件路径
rdf_file="$1"
# 保存轨迹文件路径（可选，默认为complex.xtc）
traj_file="${2:-complex.xtc}"
# 保存拓扑文件路径（可选，默认为complex.tpr）
tpr_file="${3:-complex.tpr}"

# 使用awk处理RDF数据文件，提取第一个谷的距离
# awk是一个强大的文本处理工具，用于逐行处理文件
valley_distance=$(awk '
BEGIN {
    # 初始化变量
    prev_value = 0        # 存储前一行的g(r)值
    is_decreasing = 0     # 标志：是否处于下降阶段（0=否，1=是）
    found_valley = 0      # 标志：是否已找到谷（0=否，1=是）
}

# 条件：跳过注释行(#)和元数据行(@)，只处理包含2个字段的数据行
!/^[#@]/ && NF == 2 {
    distance = $1         # 第一列：距离(nm)
    g_r = $2              # 第二列：g(r)值（径向分布函数值）

    # 判断是否进入下降阶段
    # 当g(r)值小于前一个值时，说明开始下降
    if (prev_value > 0 && g_r < prev_value) {
        is_decreasing = 1
    }

    # 检测谷点（局部最小值）
    # 条件：
    # 1. is_decreasing == 1：之前处于下降阶段
    # 2. g_r > prev_value：当前值大于前一个值（从下降转为上升）
    # 3. found_valley == 0：还没有找到谷
    # 这三个条件同时满足，说明找到了第一个谷
    if (is_decreasing && g_r > prev_value && found_valley == 0) {
        # 只输出距离值（不输出其他文本），便于后续处理
        print prev_distance
        # 标记已找到谷，防止继续查找
        found_valley = 1
        # 退出awk程序
        exit
    }

    # 更新前一行的值，用于下一次迭代比较
    prev_value = g_r
    prev_distance = distance
}
' "$rdf_file")

# 检查是否成功提取到距离值
if [ -z "$valley_distance" ]; then
    echo "错误：无法从RDF文件中找到第一个谷"
    exit 1
fi

# 输出提取到的距离
echo ""
echo "=========================================="
echo "第一个谷对应的距离: $valley_distance nm"
echo "=========================================="

# 检查文件是否存在
if [ ! -f "$traj_file" ]; then
    echo "错误：轨迹文件 $traj_file 不存在"
    exit 1
fi

if [ ! -f "$tpr_file" ]; then
    echo "错误：拓扑文件 $tpr_file 不存在"
    exit 1
fi

# 生成输出文件名
output_file="first_shell_water_index_${valley_distance}.dat"

echo ""
echo "正在计算第一层水分子数量..."
echo "使用距离阈值: $valley_distance nm"
echo "输出文件: $output_file"
echo ""

# 使用gmx select命令计算在指定距离内的水分子数量
# -f: 指定轨迹文件
# -s: 指定拓扑文件
# -n: 指定索引文件（包含Water_O组）
# -select: 选择条件（Water_O原子在Protein的指定距离内）
# -os: 输出文件（包含每一帧的水分子数量）
gmx select -f "$traj_file" -s "$tpr_file" -n index.ndx \
    -select "group Water_O and within $valley_distance of group Protein" \
    -oi "$output_file"

# 检查gmx select是否执行成功
if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 计算完成！结果已保存到: $output_file"
    rm complex.xtc

else
    echo "✗ gmx select命令执行失败"
    exit 1
fi
