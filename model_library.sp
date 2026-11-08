* Library of Device Models for Microelectronics Assignments

.subckt saturating_opamp inp inn out
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

.subckt ideal_opamp inp inn out
+ Av=100k Rc=10.6Meg Cc=1n Rout=10 

  E1  na   0   inp inn {Av}

  Rc  na   nb   {Rc}
  Cc  nb   0   {Cc}

  E2   nc   0   nb   0   1

  Rout nc out {Rout}
.ends

.subckt two_stage_opamp inp inn out
+ Av=6.0 Rc=1.59Meg Cc=10n Rout=1 
+ VR=10
+ Gm=10m Imax=1m

  B1 0 na i={Imax*tanh(Gm*(v(inp) - v(inn))/Imax)}
  Rc na 0 {Rc}
  Cc na 0 {Cc}

  B2 nb 0   v={vr*tanh(Av*v(na)/vr)}

  Rout nb out {Rout}
.ends

.model SFH235 D(IS=3.5e-11 N=1.01 IKF=6e-5 Rs=6.5 Cjo=73.01p M=0.452 
+ Vj=0.304 BV=200)

.MODEL SFH4554 D        
+       IS =    8.04E-17
+       N =     1.584035846
+       RS =    1.976811554
+       IKF =   0.074579378
+       IBV =   1.50E-08
+       NBV =   70
+       BV =    16
+       CJO =   3.71E-11
+       TT =    1.00E-08
+       EG =    1.46


.subckt ideal_ota inp inn out
+ Gm=10m Rc=15Meg Cc=1n 

  G1 0 out inp inn {Gm}
  Rc out 0 {Rc}
  Cc out 0 {Cc}

.ends


.subckt saturating_ota inp inn out
+ Gm=10m Rc=15Meg Cc=1n 
+ Imax=100u
  B1 0 out i={Imax*tanh(Gm*(v(inp)-v(inn))/Imax)}
  Rc out 0 {Rc}
  Cc out 0 {Cc}

.ends


* Diode Models
* 1N4004 small-signal diode model
.model D1N4004 D(Is=168.1E-21 N=1 Rs=.1 Ikf=0 Xti=3 Eg=1.11 Cjo=4p 
+ M=.3333 Vj=.75 Fc=.5 Isr=100p Nr=2 Bv=100 Ibv=100u Tt=11.54n) 


* 1N914 Diode Model 
.model D1N914 D(Is=168.1E-21 N=1 Rs=.1 Ikf=0 Xti=3 Eg=1.11 Cjo=4p 
+ M=.3333 Vj=.75 Fc=.5 Isr=100p Nr=2 Bv=100 Ibv=100u Tt=11.54n) 

* 1N4148 Diode Model 
.model D1N4148 D(Is=168.1E-21 N=1 Rs=.1 Ikf=0 Xti=3 Eg=1.11 Cjo=4p 
+ M=.3333 Vj=.75 Fc=.5 Isr=100p Nr=2 Bv=100 Ibv=100u Tt=11.54n) 


* ======================================================================
* DEVICE MODELS FOR ALD1105 ARRAY
* ======================================================================

.model ald1105n nmos (level=1
+ cbd=0.5p cbs=0.5p cgdo=0.1p cgso=0.1p gamma=0.85
+ kp=225u l=10e-6 lambda=0.029 phi=0.9 vto=0.7 w=20e-6)

.model ald1105p pmos (level=1
+ cbd=0.5p cbs=0.5p cgdo=0.1p cgso=0.1p gamma=0.45
+ kp=100u l=10e-6 lambda=0.0304 phi=0.8 vto=-0.7 w=20e-6)


*=====================================================
* BJT models
*=====================================================

.model Q2N2222 NPN (Is=14.34f Xti=3 Eg=1.11 Vaf=74.03 Bf=255.9 Ne=1.307
+Ise=14.34f Ikf=.2847 Xtb=1.5 Br=6.092 Nc=2 Isc=0 Ikr=0 Rc=1
+Cjc=7.306p Mjc=.3416 Vjc=.75 Fc=.5 Cje=22.01p Mje=.377 Vje=.75
+Tr=46.91n Tf=411.1p Itf=.6 Vtf=1.7 Xtf=3 Rb=10)

.model Q2N2907A PNP (Is=650.6E-18 Xti=3 Eg=1.11 Vaf=115.7 Bf=231.7 Ne=1.829
+Ise=54.81f Ikf=1.079 Xtb=1.5 Br=3.563 Nc=2 Isc=0 Ikr=0 Rc=.715
+Cjc=14.76p Mjc=.5383 Vjc=.75 Fc=.5 Cje=19.82p Mje=.3357 Vje=.75
+Tr=111.3n Tf=603.7p Itf=.65 Vtf=5 Xtf=1.7 Rb=10)

.model Q2N3904 NPN (Is=6.734f Xti=3 Eg=1.11 Vaf=74.03 Bf=416.4 Ne=1.259
+Ise=6.734f Ikf=66.78m Xtb=1.5 Br=.7371 Nc=2 Isc=0 Ikr=0 Rc=1
+Cjc=3.638p Mjc=.3085 Vjc=.75 Fc=.5 Cje=4.493p Mje=.2593 Vje=.75
+Tr=239.5n Tf=301.2p Itf=.4 Vtf=4 Xtf=2 Rb=10)

.model Q2N3906 PNP (Is=1.41f Xti=3 Eg=1.11 Vaf=18.7 Bf=180.7 Ne=1.5 Ise=0
+Ikf=80m Xtb=1.5 Br=4.977 Nc=2 Isc=0 Ikr=0 Rc=2.5 Cjc=9.728p
+Mjc=.5776 Vjc=.75 Fc=.5 Cje=8.063p Mje=.3677 Vje=.75 Tr=33.42n
+Tf=179.3p Itf=.4 Vtf=4 Xtf=6 Rb=10)

*----------------------------------------------------------------------------
* CD4007 NMOS and PMOS SPICE models
.model CD4007N NMOS
+ Level=1 Gamma= 0 Xj=0 W=30e-6 L=10e-6
+ Tox=1200n Phi=.6 Rs=0 Kp=111u Vto=2.0 Lambda=0.01
+ Rd=0 Cbd=2.0p Cbs=2.0p Pb=.8 Cgso=0.1p
+ Cgdo=0.1p Is=16.64p N=1

*The default W and L is 30 and 10 um respectively and AD and AS
*should not be included.

.model CD4007P PMOS
+ Level=1 Gamma= 0 Xj=0 W=60e-6 L=10e-6
+ Tox=1200n Phi=.6 Rs=0 Kp=55u Vto=-1.5 Lambda=0.04
+ Rd=0 Cbd=4.0p Cbs=4.0p Pb=.8 Cgso=0.2p
+ Cgdo=0.2p Is=16.64p N=1

*The default W and L is 60 and 10 um respectively and AD and AS
*should not be included.

