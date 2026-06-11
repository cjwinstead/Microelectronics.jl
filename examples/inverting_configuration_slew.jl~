using Microelectronics

RF = 2u"kΩ"
RI = 1u"kΩ"

fs = 1u"kHz"
Vs = 1u"V"

Ts = 1/fs |> u"s"

tmax  = 4*Ts
tstep = Ts/20

source = vsin("v1",1,0;frequency=fs,amplitude=Vs)

components = [ resistor("RI",1,2, RI),
               resistor("RF",2,3, RF),
               opamp(name="OA1",nplus=0,nminus=2,out=3,model="opamp")
               ]

netlist="""
* Half Wave Rectifier

.include models/two_stage_opamp.sp

$source
$components

.end
"""

load_netlist(netlist)

simulate(:tran;tmax,tstep)

G = measure(:Av;in="1",out="3")
report("Gain magnitude is $G")

plot([node"1",node"2",node"3"];labels=["vin" "vminus" "vout"])



