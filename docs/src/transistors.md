# Transistors

```@meta
CurrentModule = Microelectronics
```

## MOSFETs

[`NMOS`](@ref) and [`PMOS`](@ref) make MOSFETs with terminals in the order
drain, gate, source and (optionally) body; the body is tied to the source
unless given. [`MOSFET`](@ref) takes all four terminals and works for either
polarity. Sizes and other instance parameters are keywords, with or without
units:

```julia
NMOS("M1", "d", "g", 0)                                  # ald1105n, body at the source
NMOS("M2", "d", "g", "s", 0; model="CD4007N", W=60u"μm", L=10u"μm")
PMOS("M3", "out", "in", "vdd")                           # ald1105p
```

The [`model_library`](@ref) provides `ald1105n`/`ald1105p` (the default
models) and `CD4007N`/`CD4007P`.

## Operating point

After an operating point, DC sweep or transient analysis,
[`device_values`](@ref) gives a MOSFET's drain current, terminal voltages,
threshold and saturation voltages, small-signal parameters and region of
operation:

```julia
n = Netlist(title="bias", sources=[Vdc("DD", "d", 0, 5u"V"), Vdc("G", "g", 0, 3u"V")],
            components=[NMOS("M1", "d", "g", 0)])
load_netlist(n)
simulate(:op)
device_values("M1")
# (id = 0.001363 A, vgs = 3.0 V, vds = 5.0 V, vbs = 0.0 V, vth = 0.7 V, vdsat = 2.3 V,
#  gm = 0.001185 S, gds = 3.452e-5 S, gmbs = 0.0005309 S, region = :saturation)
```

These quantities are kept automatically for every MOSFET in the circuit.
`M1["gm"]` (for an element `M1`) gives the ngspice name of one of them,
for use with ngspice commands.

## Characteristic curves

A nested DC sweep gives a family of curves, e.g. drain current against
drain voltage for several gate voltages. The drain current is the (negated)
current in the drain source:

```julia
n = Netlist(title="NMOS curves", sources=[Vdc("DS", "d", 0, 0u"V"), Vdc("GS", "g", 0, 0u"V")],
            components=[NMOS("M1", "d", "g", 0)])
load_netlist(n)
simulate(:dc; device="VDS", start=0u"V", stop=5u"V", step=0.1u"V",
              sweep2=("VGS", 1u"V", 3u"V", 1u"V"))
plot(signals(branches=["VDS"]))       # one curve per VGS, labelled "VGS = 1 V", ...
```
