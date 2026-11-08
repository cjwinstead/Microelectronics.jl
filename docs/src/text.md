# SPICE text functions

```@meta
CurrentModule = Microelectronics
```

Circuits can also be written with functions that return each SPICE line as
text. [`build_netlist`](@ref) takes their results, mixed with element
objects and SPICE text written by hand, and loads the netlist:

```julia
build_netlist(; title="text", sources=[vdc("V1", 1, 0, 1u"V")],
                              components=[resistor("R1", 1, 0, 1u"kΩ")])
```

```
* text
.include .../model_library.sp
V1    1     0      DC 1
R1    1     0     1000
.end
```

Each function returns [`SpiceText`](@ref), a string that is displayed
without quotes, one line per row, and can be passed to `load_netlist`.

| SPICE line | Text function | Object |
|:---------- |:------------- |:------ |
| resistor, capacitor, inductor, diode | [`resistor`](@ref), [`capacitor`](@ref), [`inductor`](@ref), [`diode`](@ref) | [`Resistor`](@ref), ... |
| DC, AC, sine, pulse, PWL source | [`vdc`](@ref), [`vac`](@ref), [`vsin`](@ref), [`vpulse`](@ref), [`vpwl`](@ref), [`idc`](@ref), ... | [`Vdc`](@ref), ... |
| controlled source | [`dependent_source`](@ref) | [`VCVS`](@ref), ... |
| op-amp, subcircuit instance | [`opamp`](@ref), [`subckt_instance`](@ref) | [`Opamp`](@ref), [`Subckt`](@ref) |
| MOSFET | [`mosfet`](@ref) | [`MOSFET`](@ref) |
| `.param` lines | [`spice_parameters`](@ref) | [`Parameter`](@ref) |

[`sin_string`](@ref), [`pulse_string`](@ref) and [`pwl_string`](@ref) give
just a source's waveform, and [`qstr`](@ref) converts one value.
