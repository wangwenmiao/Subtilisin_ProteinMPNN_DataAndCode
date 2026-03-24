#!/bin/bash
export OMP_NUM_THREADS=24
# 输入轨迹和tpr文件
XTC="complex.xtc"
TPR="complex.tpr"
#gmx mindist -f complex.xtc -s complex.tpr -d 0.4 -on contacts_0_4nm.xvg -od mindist_0_4nm.xvg
# 定义两个 cutoff 距离
for d in 0.4 0.6; do
    # 替换点为下划线用于文件命名
    suffix=$(echo $d | sed 's/\./_/')

    echo "Processing with cutoff = ${d} nm"

    gmx mindist \
        -f $XTC \
        -s $TPR \
        -d $d \
        -on contacts_${suffix}nm.xvg \
        -od mindist_${suffix}nm.xvg << EOF
1
1
EOF

done

