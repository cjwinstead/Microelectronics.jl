.subckt current_limiting_opamp inp inn out
+ Av=100 Rc=1.5Meg Cc=20.0n Rout=1
+ VR=10 Gm=1m Imax=0.1m
+ Ilimit=25m
+ R3=1Meg C3=10f

  B1 0 na i={Imax*tanh(Gm*(v(inp) - v(inn))/Imax)}
  Rc na 0 {Rc}
  Cc na 0 {Cc}

  B2 nb 0   v={vr*tanh(Av*v(na)/vr)}

  Rout nb nc {Rout}

  Vm nc out DC 0v
  B3 out 0 i={i(vm)-Ilimit*tanh(i(vm)/Ilimit)}
  R3 out 0 {R3}
  C3 out 0 {C3}
.ends
