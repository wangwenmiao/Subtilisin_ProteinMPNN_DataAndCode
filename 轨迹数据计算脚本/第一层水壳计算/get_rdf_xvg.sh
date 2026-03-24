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
mpirun -n 16 cpptraj.MPI -i combine_traj.in
python3 /media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID/gmx_calcu_sasa/input-files/acpype.py -p complex_solv.prmtop -x complex_solv.inpcrd
python3 /home/yons/wwm_temp/gmx_calcu_sasa/input-files/convert2gmx.py
cpptraj -p complex_solv.prmtop -y combine.nc -x complex.xtc

mv combine.nc /media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/1648_ca_2_apo

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


gmx rdf -s complex.tpr -f complex.xtc -n index.ndx -ref 'group "Protein-H"' -sel 'group "Water_O"' -surf mol -bin 0.005 -rmax 1.2 -cn cn_Ow_Prot-H.xvg


# 检查gmx select是否执行成功
if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 计算完成！结果已保存到: $output_file"
    # rm complex.xtc
    mv complex.xtc /media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/1648_ca_2_apo

else
    echo "✗ gmx select命令执行失败"
    exit 1
fi
