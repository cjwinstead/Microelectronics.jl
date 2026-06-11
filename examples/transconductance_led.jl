using Microelectronics

RI = 150u"Ω"
D  = "SFH4554"

print(@table RI D)

models="""
.include "models/sfh4554.sp"
.include "models/current_limiting_opamp.sp"
"""


sources=[vsin("vin",1,0;offset=2u"V",amplitude=2u"V",frequency=1u"kHz"),
         vdc("vm1",4,2,0)
         ]

components=[opamp(;name="OA1",nplus=1,nminus=2,out=3,model="current_limiting_opamp"),
            resistor("RI",2,0,RI),
            diode("D1",3,4,D)
            ]

build_netlist("Transconductance configuration driving LED";
              models,sources,components)


tstep = 10u"μs"
tmax  = 4u"ms"

simulate(:tran;tstep,tmax)

display(plot([i"vm1"];labels=["Iout"]))


Gm = 1000*measure(:Gm;in="1",out="vm1")u"mA/V"

report("Gm = $(Gm)")
