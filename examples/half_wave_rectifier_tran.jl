using Microelectronics

R = 1u"kΩ"
D = "D1N4004"  # diode model type

tstep = 10u"μs"
tmax  = 4u"ms"

source = vsin("v1",1,0;amplitude=10u"V")

components = [ diode("D1",1, 2, D),
               resistor("R1",2,0, R)
               ]

netlist="""
* Half Wave Rectifier

.include models/diodes.sp

$source
$components

.end
"""

load_netlist(netlist)

simulate(:tran;tstep,tmax)

plot([node"1",node"2"];labels=["vin" "vout"])



