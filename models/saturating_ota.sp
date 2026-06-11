.subckt ota inp inn out
+ Gm=10m Rc=15Meg Cc=1n 
+ Imax=100u
  B1 0 out i={Imax*tanh(Gm*(v(inp)-v(inn))/Imax)}
  Rc out 0 {Rc}
  Cc out 0 {Cc}

.ends
