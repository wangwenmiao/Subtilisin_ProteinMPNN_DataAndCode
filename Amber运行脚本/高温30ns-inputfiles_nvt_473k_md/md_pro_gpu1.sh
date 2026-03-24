#!/bin/bash
export CUDA_VISIBLE_DEVICES=1
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles_nvt_473k_md/step8_prod_nvt.in -o step8_prod_nvt.out -p complex_solv.prmtop -c step5_equil_nvt_573K_4.rst7 -r step8_prod_nvt.rst7 -ref step5_equil_nvt_573K_4.rst7 -x step8_prod_nvt.nc
