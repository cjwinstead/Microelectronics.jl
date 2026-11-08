# Reference

```@meta
CurrentModule = Microelectronics
```

```@contents
Pages = ["reference.md"]
Depth = 2:2
```

## Netlists

```@docs
Netlist
load_netlist
build_netlist
Subcircuit
Subckt
Instance
parameter_list
Parameter
ParameterTable
@table
Model
Include
model_library
Element
Component
SpiceLine
SpiceText
```

## Components

```@docs
Resistor
Capacitor
Inductor
Diode
Opamp
VCVS
VCCS
CCVS
CCCS
```

## Sources

```@docs
Source
Waveform
Point
Vdc
Idc
Vac
Iac
Vsin
Isin
Vpulse
Ipulse
Vpwl
Ipwl
Vsource
Isource
@pwl_str
alter
```

## Transistors

```@docs
NMOS
PMOS
MOSFET
mosfet
device_values
```

## Simulation

```@docs
simulate
transient
dc
ac
analysis_kind
be_quiet
be_verbose
dumpbuffer
```

## Results

```@docs
signals
Signals
sweep_curves
@node_str
@i_str
@dB_str
@phase_str
node_voltage
source_current
signal_dB
signal_phase
tran_time
dc_sweep
ac_freq
nodes
magnitudes
phases
measure
fft
distortion
Spectrum
```

## Plots and reports

```@docs
bode
report
dB20
```

## Units

```@docs
Hz
rad
°
parallel
scale_quantity
scale_resistor
scale_capacitor
scale_Hz
scale_rad
scale_s
isHz
isradps
israd
is°
iss
isvoltage
iscurrent
isresistor
iscapacitor
istransconductance
spice_value
qstr
```

## SPICE text functions

```@docs
resistor
capacitor
inductor
diode
bipole
vdc
vac
vsin
vpulse
vpwl
idc
iac
isin
ipulse
ipwl
independent_source
dependent_source
opamp
subckt_instance
sin_string
pulse_string
pwl_string
spice_parameters
device_prefix
```
