#!/bin/bash


#bash /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/read_rdf_xvg_get_water_shell_distance.sh /home/yons/wwm_temp/4907_ca_2_apo/rdf.xvg complex.xtc complex.tpr

# 目录列表和对应的rdf.xvg路径
dirs=(
    "/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_apo"
    "/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/4907_ca_2_holo"
    "/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_apo"
    "/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/17831_ca_2_holo"
    "/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/1648_ca_2_apo"
    "/media/yons/wwm_data/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/1648_ca_2_holo"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/11117_ca_2_apo"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/11117_ca_2_holo"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/wt_ca_2_apo"
    "/media/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID_new/wt_ca_2_holo"
)

rdf_dirs=(

    "/home/yons/wwm_temp/4907_ca_2_apo"
    "/home/yons/wwm_temp/4907_ca_2_holo"
    "/home/yons/wwm_temp/17831_ca_2_apo"
    "/home/yons/wwm_temp/17831_ca_2_holo"
    "/home/yons/wwm_temp/1648_ca_2_apo"
    "/home/yons/wwm_temp/1648_ca_2_holo"
    "/home/yons/wwm_temp/11117_ca_2_apo"
    "/home/yons/wwm_temp/11117_ca_2_holo"
    "/home/yons/wwm_temp/wt_ca_2_apo"
    "/home/yons/wwm_temp/wt_ca_2_holo"

)

    
       

script="/home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/read_rdf_xvg_get_water_index.sh"

# 遍历每个目录
for idx in "${!dirs[@]}"; do
    dir="${dirs[$idx]}"
    rdf_dir="${rdf_dirs[$idx]}"
    rdf_file="$rdf_dir/rdf.xvg"

    echo "处理: $dir"

    # 遍历 md1 到 md10
    for i in {1..10}; do
        md_dir="$dir/md$i"

        if [ -d "$md_dir" ]; then
            cd "$md_dir"
            echo "执行: md$i"
            bash "$script" "$rdf_file" complex.xtc complex.tpr
            cd - > /dev/null
        fi
    done

    echo ""
done

echo "完成！"
