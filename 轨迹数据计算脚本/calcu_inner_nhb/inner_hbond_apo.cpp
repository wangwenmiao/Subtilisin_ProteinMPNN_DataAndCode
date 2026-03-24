parm complex_solv.prmtop
trajin step8_prod_npt.nc
autoimage
hbond donormask :1-290 acceptormask :1-290 out inner_nhb.dat avgout inner_avghb.dat
go
quit
