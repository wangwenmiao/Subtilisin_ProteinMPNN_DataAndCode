#!/bin/bash

dirs=(
"/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo"
"/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_holo"
"/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo"
"/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_holo"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/1648_ca_2_apo"
"/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/1648_ca_2_holo"
"/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/11117_ca_2_apo"
"/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/wt_ca_2_holo"
"/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/11117_ca_2_holo"
"/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/wt_ca_2_apo"
)

# 遍历每个目录
for idx in "${!dirs[@]}"; do
    dir="${dirs[$idx]}"

    echo "处理: $dir"

    # 遍历 md1 到 md10
    for i in {1..10}; do
        md_dir="$dir/md$i"

        if [[ -d "$md_dir" && "$md_dir" == *apo* ]]; then
            cd "$md_dir"
            echo "执行: md$i"
            echo "执行: inner_hbond_apo.cpp"
            mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_ncic/ncic_apo_04nm_byresi.in
            mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_ncic/ncic_apo_06nm_byresi.in
            
            cd - > /dev/null
        fi
        
        if [[ -d "$md_dir" && "$md_dir" == *holo* ]]; then 
            cd "$md_dir"
            echo "执行: md$i"
            echo "执行: inner_hbond_holo.cpp"
            mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_ncic/ncic_holo_04nm_byresi.in
            mpirun -n 24 cpptraj.MPI -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/calcu_ncic/ncic_holo_06nm_byresi.in
            cd - > /dev/null
        fi
    done

    echo ""
done

echo "完成！"
