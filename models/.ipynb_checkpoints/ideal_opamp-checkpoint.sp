* Subcircuit Model for an Ideal Op Amp

.subckt ideal_opamp inp inn out
+ Av=100k Rin=1Meg Rc=1Meg Cc=1n Rout=1
  Rin inp inn {Rin}
  E1  a   0   inp inn {Av}
  Rc  a   b   {Rc}
  Cc  b   0   {Cc}
  E2  c   0   b   0   1
  Rout c out {Rout}
.ends

