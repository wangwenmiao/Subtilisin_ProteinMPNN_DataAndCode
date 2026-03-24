import parmed as pmd
"""
# convert GROMACS topology to AMBER format
gmx_top = pmd.load_file('pmaawaterFE20mer2.top', xyz='pmaawaterFE20mer2.gro')
gmx_top.save('pmaa.top', format='amber')
gmx_top.save('pmaa.crd', format='rst7')

"""

# convert AMBER topology to GROMACS, CHARMM formats
amber = pmd.load_file('complex_solv.prmtop', 'complex_solv.inpcrd')
# Save a GROMACS topology and GRO files
amber.save('complex_solv_GMX.top', overwrite=True)
amber.save('complex_solv_GMX.gro', overwrite=True)

"""
# Save a CHARMM PSF and crd files
amber.save('charmm.psf')
amber.save('charmm.crd')

# Save a DLPOLY FIELD and CONFIG files
amber.save('dlpoly.field')
amber.save('dlpoly.config')

# convert mol2 to pdb file
mol2_parm = pmd.load_file('my.mol2')
mol2_parm.save('my.pdb')

# and many more
"""
