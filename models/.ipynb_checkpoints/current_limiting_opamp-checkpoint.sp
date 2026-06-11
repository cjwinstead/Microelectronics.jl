.subckt opamp inp inn out
+ Av=63 Rc=1592k Cc=10n Rout=1 
+ VR=10v
+ Gm=1m Imax=100u
+ Ilimit=20m

  B1 0 na i={Imax*tanh(Gm*(v(inp) - v(inn))/Imax)}
  Rc na 0 {Rc}
  Cc na 0 {Cc}

  B2 nb 0   v={vr*tanh(Av*v(na)/vr)}

  Rout nb nc {Rout}

  Vm nc out DC 0v
  B3 out 0 i={i(vm)-Ilimit*tanh(i(vm)/Ilimit)}
  R3 out 0 1Meg
  C3 out 0 100f
.ends