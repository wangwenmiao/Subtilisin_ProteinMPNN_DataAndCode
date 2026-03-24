#!/bin/bash

MMPBSA.py -O -i ../mmpbsa.in -o MMPB_GB_SA.dat -sp complex_solv.prmtop -cp complex.prmtop -rp receptor.prmtop -lp ligand.prmtop -y mmpbsa_frame.nc

