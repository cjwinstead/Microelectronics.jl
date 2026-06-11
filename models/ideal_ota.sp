.subckt ota inp inn out
+ Gm=10m Rc=15Meg Cc=1n 

  G1 0 out inp inn {Gm}
  Rc out 0 {Rc}
  Cc out 0 {Cc}

.ends
