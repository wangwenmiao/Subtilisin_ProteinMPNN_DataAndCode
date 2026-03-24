#!/bin/bash
export CUDA_VISIBLE_DEVICES=0
mpirun -np 16 pmemd.MPI -O -i /home/yons/wwm/4519_subtilisin_120ns_ace_aapfa_nme_HID/inputfiles/step5_equil_npt_strong_constr.in -o step5_equil_npt_strong_constr.out -p complex_solv.prmtop -c step4_heat_nvt.rst7 -r step5_equil_npt_strong_constr.rst7 -ref step4_heat_nvt.rst7 -x step5_equil_npt_strong_constr.nc

