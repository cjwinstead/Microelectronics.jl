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


* ======================================================================
* AMI 0.6 um (C5N) CMOS PROCESS: ami06N / ami06P
* BSIM3 version 3.1 parameters (HSPICE level 49) from the MOSIS run
* N8BN (Jan 1999), as used in the ECE 5420 VLSI labs. ngspice reads
* level 49 as BSIM3; VERSION is set to 3.3 so that ngspice uses its
* maintained BSIM3v3.3 code (the results match its BSIM3v3.1 code).
* Draw with L=0.6u and W >= 1.2u (lambda = 0.3 um).
* ======================================================================

*N8BN SPICE BSIM3 VERSION 3.1 (HSPICE Level 49) PARAMETERS
* DATE: Jan 25/99
* LOT: n8bn                  WAF: 03
* Temperature_parameters=Default
.MODEL ami06N NMOS (                                LEVEL   = 49
+VERSION = 3.3            TNOM    = 27             TOX     = 1.41E-8
+XJ      = 1.5E-7         NCH     = 1.7E17         VTH0    = 0.7086
+K1      = 0.8354582      K2      = -0.088431      K3      = 41.4403818
+K3B     = -14            W0      = 6.480766E-7    NLX     = 1E-10
+DVT0W   = 0              DVT1W   = 5.3E6          DVT2W   = -0.032
+DVT0    = 3.6139113      DVT1    = 0.3795745      DVT2    = -0.1399976
+U0      = 533.6953445    UA      = 7.558023E-10   UB      = 1.181167E-18
+UC      = 2.582756E-11   VSAT    = 1.300981E5     A0      = 0.5292985
+AGS     = 0.1463715      B0      = 1.283336E-6    B1      = 1.408099E-6
+KETA    = -0.0173166     A1      = 0              A2      = 1
+RDSW    = 2.268366E3     PRWG    = -1E-3          PRWB    = 6.320549E-5
+WR      = 1              WINT    = 2.043512E-7    LINT    = 3.034496E-8
+DWG     = -1.446149E-8
+DWB     = 2.077539E-8    VOFF    = -0.1137226     NFACTOR = 1.2880596
+CIT     = 0              CDSC    = 1.506004E-4    CDSCD   = 0
+CDSCB   = 0              ETA0    = 3.815372E-4    ETAB    = -1.029178E-3
+DSUB    = 2.173055E-4    PCLM    = 0.6171774      PDIBLC1 = 0.185986
+PDIBLC2 = 3.473187E-3    PDIBLCB = -1E-3          DROUT   = 0.4037723
+PSCBE1  = 5.998012E9     PSCBE2  = 3.788068E-8    PVAG    = 0.012927
+DELTA   = 0.01           MOBMOD  = 1              PRT     = 0
+UTE     = -1.5           KT1     = -0.11          KT1L    = 0
+KT2     = 0.022          UA1     = 4.31E-9        UB1     = -7.61E-18
+UC1     = -5.6E-11       AT      = 3.3E4          WL      = 0
+WLN     = 1              WW      = 0              WWN     = 1
+WWL     = 0              LL      = 0              LLN     = 1
+LW      = 0              LWN     = 1              LWL     = 0
+CAPMOD  = 2              XPART   = 0.4            CGDO    = 1.99E-10
+CGSO    = 1.99E-10       CGBO    = 0              CJ      = 4.233802E-4
+PB      = 0.9899238      MJ      = 0.4495859      CJSW    = 3.825632E-10
+PBSW    = 0.1082556      MJSW    = 0.1083618      PVTH0   = 0.0212852
+PRDSW   = -16.1546703    PK2     = 0.0253069      WKETA   = 0.0188633
+LKETA   = 0.0204965       )

* N8BN SPICE BSIM3 VERSION 3.1 (HSPICE Level 49) PARAMETERS
* DATE: Jan 25/99
* LOT: n8bn                  WAF: 03
* Temperature_parameters=Default
.MODEL ami06P PMOS (                               LEVEL   = 49
+VERSION = 3.3            TNOM    = 27             TOX     = 1.41E-8
+XJ      = 1.5E-7         NCH     = 1.7E17         VTH0    = -0.9179952
+K1      = 0.5575604      K2      = 0.010265       K3      = 14.0655075
+K3B     = -2.3032921     W0      = 1.147829E-6    NLX     = 1.114768E-10
+DVT0W   = 0              DVT1W   = 5.3E6          DVT2W   = -0.032
+DVT0    = 2.2896412      DVT1    = 0.5213085      DVT2    = -0.1337987
+U0      = 202.4540953    UA      = 2.290194E-9    UB      = 9.779742E-19
+UC      = -3.69771E-11   VSAT    = 1.307891E5     A0      = 0.8356881
+AGS     = 0.1568774      B0      = 2.365956E-6    B1      = 5E-6
+KETA    = -5.769328E-3   A1      = 0              A2      = 1
+RDSW    = 2.746814E3     PRWG    = 2.34865E-3     PRWB    = 0.0172298
+WR      = 1              WINT    = 2.586255E-7    LINT    = 7.205014E-8
+DWG     = -2.133054E-8
+DWB     = 9.857534E-9    VOFF    = -0.0837499     NFACTOR = 1.2415529
+CIT     = 0              CDSC    = 4.363744E-4    CDSCD   = 0
+CDSCB   = 0              ETA0    = 0.11276        ETAB    = -2.9484E-3
+DSUB    = 0.3389402      PCLM    = 4.9847806      PDIBLC1 = 2.481735E-5
+PDIBLC2 = 0.01           PDIBLCB = 0              DROUT   = 0.9975107
+PSCBE1  = 3.497872E9     PSCBE2  = 4.974352E-9    PVAG    = 10.9914549
+DELTA   = 0.01           MOBMOD  = 1              PRT     = 0
+UTE     = -1.5           KT1     = -0.11          KT1L    = 0
+KT2     = 0.022          UA1     = 4.31E-9        UB1     = -7.61E-18
+UC1     = -5.6E-11       AT      = 3.3E4          WL      = 0
+WLN     = 1              WW      = 0              WWN     = 1
+WWL     = 0              LL      = 0              LLN     = 1
+LW      = 0              LWN     = 1              LWL     = 0
+CAPMOD  = 2              XPART   = 0.4            CGDO    = 2.4E-10
+CGSO    = 2.4E-10        CGBO    = 0              CJ      = 7.273568E-4
+PB      = 0.9665597      MJ      = 0.4959837      CJSW    = 3.114708E-10
+PBSW    = 0.99           MJSW    = 0.2653654      PVTH0   = 9.420541E-3
+PRDSW   = -231.2571566   PK2     = 1.396684E-3    WKETA   = 1.862966E-3
+LKETA   = 5.728589E-3     )


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

