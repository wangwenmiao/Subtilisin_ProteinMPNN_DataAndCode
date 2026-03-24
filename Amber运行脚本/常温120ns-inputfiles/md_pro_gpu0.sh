#!/bin/bash
export CUDA_VISIBLE_DEVICES=0
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step8_prod_npt.in -o step8_prod_npt.out -p complex_solv.prmtop -c step7.7_equil_npt_weak_constr.rst7 -r step8_prod_npt.rst7 -x step8_prod_npt.nc
