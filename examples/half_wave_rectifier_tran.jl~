using Microelectronics

R = 1u"kΩ"
D = "D1N4004"  # diode model type

start = -5u"V"
stop  = +5u"V"
step  = 0.1u"V"

source = vdc("v1",1,0,1u"V")

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

simulate(:dc;device="v1",start,stop,step)

plot([node"2"];labels=["vout"])



