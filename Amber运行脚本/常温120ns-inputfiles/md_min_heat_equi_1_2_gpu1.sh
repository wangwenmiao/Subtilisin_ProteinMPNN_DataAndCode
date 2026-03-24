#!/bin/bash
# 指定使用GPU 0
export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH
export CUDA_HOME=/usr/local/cuda-12.8
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export CUDA_VISIBLE_DEVICES=1
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step1_min_solvent.in -o step1_min_solvent.out -p complex_solv.prmtop -c complex_solv.inpcrd -r step1_min_solvent.rst7 -ref complex_solv.inpcrd -x step1_min_solvent.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step2_min_hydrogens.in -o step2_min_hydrogens.out -p complex_solv.prmtop -c step1_min_solvent.rst7 -r step2_min_hydrogens.rst7 -ref step1_min_solvent.rst7 -x step2_min_hydrogens.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step3_min_unconstr.in -o step3_min_unconstr.out -p complex_solv.prmtop -c step2_min_hydrogens.rst7 -r step3_min_unconstr.rst7 -x step3_min_unconstr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step4_heat_nvt.in -o step4_heat_nvt.out -p complex_solv.prmtop -c step3_min_unconstr.rst7 -r step4_heat_nvt.rst7 -ref step3_min_unconstr.rst7 -x step4_heat_nvt.nc
mpirun -np 24 pmemd.MPI -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step5_equil_npt_strong_constr.in -o step5_equil_npt_strong_constr.out -p complex_solv.prmtop -c step4_heat_nvt.rst7 -r step5_equil_npt_strong_constr.rst7 -ref step4_heat_nvt.rst7 -x step5_equil_npt_strong_constr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step6_equil_npt_medium_constr.in -o step6_equil_npt_medium_constr.out -p complex_solv.prmtop -c step5_equil_npt_strong_constr.rst7 -r step6_equil_npt_medium_constr.rst7 -ref step5_equil_npt_strong_constr.rst7 -x step6_equil_npt_medium_constr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step7_equil_npt_weak_constr.in -o step7_equil_npt_weak_constr.out -p complex_solv.prmtop -c step6_equil_npt_medium_constr.rst7 -r step7_equil_npt_weak_constr.rst7 -ref step6_equil_npt_medium_constr.rst7 -x step7_equil_npt_weak_constr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step7.3_equil_npt_weak_constr.in -o step7.3_equil_npt_weak_constr.out -p complex_solv.prmtop -c step7_equil_npt_weak_constr.rst7 -r step7.3_equil_npt_weak_constr.rst7 -ref step7_equil_npt_weak_constr.rst7 -x step7.3_equil_npt_weak_constr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step7.5_equil_npt_weak_constr.in -o step7.5_equil_npt_weak_constr.out -p complex_solv.prmtop -c step7.3_equil_npt_weak_constr.rst7 -r step7.5_equil_npt_weak_constr.rst7 -ref step7.3_equil_npt_weak_constr.rst7 -x step7.5_equil_npt_weak_constr.nc
pmemd.cuda -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step7.7_equil_npt_weak_constr.in -o step7.7_equil_npt_weak_constr.out -p complex_solv.prmtop -c step7.5_equil_npt_weak_constr.rst7 -r step7.7_equil_npt_weak_constr.rst7 -ref step7.5_equil_npt_weak_constr.rst7 -x step7.7_equil_npt_weak_constr.nc
