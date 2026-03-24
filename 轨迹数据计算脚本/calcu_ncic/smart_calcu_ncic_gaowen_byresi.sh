#!/bin/bash

dirs=(
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/wt_ca_2_apo_300k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/1648_ca_2_apo_300k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo_300k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/11117_ca_2_apo_300k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo_300k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/wt_ca_2_apo_373k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/1648_ca_2_apo_373k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo_373k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/11117_ca_2_apo_373k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo_373k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/wt_ca_2_apo_473k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/1648_ca_2_apo_473k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo_473k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/11117_ca_2_apo_473k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo_473k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/wt_ca_2_apo_573k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/1648_ca_2_apo_573k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo_573k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/11117_ca_2_apo_573k"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo_573k"
)

# 遍历每个目录
for idx in "${!dirs[@]}"; do
    dir="${dirs[$idx]}"

    echo "处理: $dir"

    # 遍历 md1 到 md10
    for i in {1..3}; do
        md_dir="$dir/md$i"

        if [[ -d "$md_dir" && "$md_dir" == *apo* ]]; then
            cd "$md_dir"
            echo "执行: md$i"
            echo "执行: inner_hbond_apo.cpp"
            mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_ncic/ncic_apo_04nm_gaowen_byresi.in
            mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_ncic/ncic_apo_06nm_gaowen_byresi.in
            
            cd - > /dev/null
        fi
        
        if [[ -d "$md_dir" && "$md_dir" == *holo* ]]; then 
            cd "$md_dir"
            echo "执行: md$i"
            echo "执行: inner_hbond_holo.cpp"
            #mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_inner_nhb/ncic_holo_04nm.in
            #mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_inner_nhb/ncic_holo_06nm.in
            cd - > /dev/null
        fi
    done

    echo ""
done

echo "完成！"
