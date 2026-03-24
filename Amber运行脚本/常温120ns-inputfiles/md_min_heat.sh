#!/bin/bash
export CUDA_VISIBLE_DEVICES=0
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step1_min_solvent.in -o step1_min_solvent.out -p complex_solv.prmtop -c complex_solv.inpcrd -r step1_min_solvent.rst7 -ref complex_solv.inpcrd -x step1_min_solvent.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step2_min_hydrogens.in -o step2_min_hydrogens.out -p complex_solv.prmtop -c step1_min_solvent.rst7 -r step2_min_hydrogens.rst7 -ref step1_min_solvent.rst7 -x step2_min_hydrogens.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step3_min_unconstr.in -o step3_min_unconstr.out -p complex_solv.prmtop -c step2_min_hydrogens.rst7 -r step3_min_unconstr.rst7 -x step3_min_unconstr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step4_heat_nvt.in -o step4_heat_nvt.out -p complex_solv.prmtop -c step3_min_unconstr.rst7 -r step4_heat_nvt.rst7 -ref step3_min_unconstr.rst7 -x step4_heat_nvt.nc
