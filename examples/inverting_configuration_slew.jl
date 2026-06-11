using Microelectronics

RF = 2u"kΩ"
RI = 1u"kΩ"

fs = 100u"kHz"
Vs = 1u"V"

Ts = 1/fs |> u"s"

tmax  = 4*Ts
tstep = Ts/20

models = """
.include models/current_limiting_opamp.sp
"""

sources = [ vsin("v1",1,0;frequency=fs,amplitude=Vs) ]

components = [ resistor("RI",1,2, RI),
               resistor("RF",2,3, RF),
               opamp(name="OA1",nplus=0,nminus=2,out=3,
                     model="current_limiting_opamp")
               ]

build_netlist(;title="Half Wave Rectifier",models,sources,components)


simulate(:tran;tmax,tstep)

G = measure(:Av;in="1",out="3")
report("Gain magnitude is $G")

slew = measure(:slew;node="3")
report("Observed maximum slew rate is $slew")

plot([node"1",node"2",node"3"];labels=["vin" "vminus" "vout"])



