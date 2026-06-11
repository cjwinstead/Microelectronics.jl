.subckt ideal_opamp inp inn out
+ Av=100k Rc=10.6Meg Cc=1n Rout=10 

  E1  na   0   inp inn {Av}

  Rc  na   nb   {Rc}
  Cc  nb   0   {Cc}

  E2   nc   0   nb   0   1

  Rout nc out {Rout}
.ends

