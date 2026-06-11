using Microelectronics

Gm   = 1u"mA/V"
Rin  = 100u"kΩ"
Rout = 100u"kΩ"

Rsig = 10u"Ω"
RL   = 100u"kΩ"

vs  = 1u"V"
fs  = 1u"kHz"

Ts    = 1/fs
tmax  = 4*Ts
tstep = 0.05*Ts

circuit_parameters = @parameters(Gm,Rin,Rout,Rsig,RL,vs,fs)
simulation_parameters = @parameters(tmax,tstep)

components=[ vsin(;name="Vsig",nplus=1,nminus=0,
                  offset=0,amplitude=:vs,frequency=:fs),
             resistor(;name="Rsig",nplus=1,nminus=2,value=:Rsig),
             resistor(;name="Rin",nplus=2,nminus=0,value=:Rin),
             dependent_source(;name="I1",nplus=3,inunit="V",outunit="I",
                              nminus=0,control=(2,0),gain=:Gm),
             resistor(;name="Rout",nplus=3,nminus=0,value=:Rout),
             vdc(;name="Vm1",nplus=3,nminus=4),
             resistor(;name="RL",nplus=4,nminus=0,value=:RL)
             ]

netlist="""
* Transconductance Amp Model

$(spice_parameters(circuit_parameters))

$components

.end
"""


println(netlist)

load_netlist(netlist)

transient(;tstep,tmax)

plot(d"time",[d"Vm1#branch"])
