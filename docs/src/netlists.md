# Building netlists

```@meta
CurrentModule = Microelectronics
```

A [`Netlist`](@ref) is a circuit: a title, models and subcircuit definitions,
`.param` parameters, sources and components. Each element is a Julia object
that prints as one SPICE line, and `print(n)` shows the whole netlist.

```julia
n = Netlist(title="divider",
            sources=[Vdc("in", "in", 0, 1u"V")],
            components=[Resistor("R1", "in", "out", 1u"kΩ"),
                        Resistor("R2", "out", 0, 3u"kΩ")])
load_netlist(n)          # send it to ngspice
simulate(:op)
node"out"                # 750 mV
```

[`build_netlist`](@ref) does both steps at once: it takes the same keywords,
loads the netlist and returns its text.

## Names, nodes and values

Every element constructor takes its arguments in the order
`(name, nodes..., value)`, or all as keywords
(`Resistor(name="R1", nplus="in", nminus="out", value=1u"kΩ")`).

- **Names** get their SPICE prefix letter if it is missing:
  `Resistor("load", ...)` is `Rload` and `Vdc("in", ...)` is `Vin`. Without a
  name (`Resistor(nplus=1, nminus=2, value=1u"kΩ")`) the next free name, R1,
  R2, ..., is chosen. SPICE names are not case sensitive.
- **Nodes** can be integers, strings or symbols. Node `0` is ground. A
  quantity where a node belongs (`Vdc(1, 0, 5u"V")`, which is missing its
  name) is reported as an argument-order mistake.
- **Values** can be quantities with units, which are written in SI units
  (`2.2u"kΩ"` becomes `2200`), plain numbers in SI units, SPICE text
  (`"4.7k"`), or a parameter name as a Symbol (`:R`, written `{R}`).

## Components and sources

| Element | Constructor |
|:------- |:----------- |
| resistor, capacitor, inductor | [`Resistor`](@ref), [`Capacitor`](@ref), [`Inductor`](@ref) |
| diode | [`Diode`](@ref) |
| MOSFET | [`NMOS`](@ref), [`PMOS`](@ref), [`MOSFET`](@ref) (see [Transistors](transistors.md)) |
| op-amp | [`Opamp`](@ref) |
| subcircuit instance | [`Subckt`](@ref) |
| controlled sources | [`VCVS`](@ref), [`VCCS`](@ref), [`CCVS`](@ref), [`CCCS`](@ref) |
| DC, AC, sine, pulse, PWL sources | [`Vdc`](@ref), [`Vac`](@ref), [`Vsin`](@ref), [`Vpulse`](@ref), [`Vpwl`](@ref), and `Idc`, `Iac`, ... for currents |

A source can have several values at once, for different analyses:

```julia
Vsin("in", "in", 0; amplitude=1u"V", frequency=1u"kHz", ac=1, dc=0u"V")
# Vin   in    0     DC 0 AC 1 SIN (0,1,1000,0)
```

The package's [`model_library`](@ref) is included in every netlist by
default. It provides op-amp subcircuits (`ideal_opamp`, `saturating_opamp`,
...), diodes (`D1N4004`, `D1N914`, ...), BJTs and MOSFETs. More models go in
`models`, as [`Model`](@ref)s or SPICE text, and more files in `includes`.

## Parameters

Parameters become `.param` lines, and elements refer to them by name with a
Symbol. They can be given in whatever form is convenient:

```julia
n = Netlist(title="parameterized divider",
            parameters=(Rtop=1u"kΩ", Rbot=3u"kΩ"),
            sources=[Vdc("in", "in", 0, 1u"V")],
            components=[Resistor("R1", "in", "out", :Rtop),
                        Resistor("R2", "out", 0, :Rbot)])
```

```
* parameterized divider
.include .../model_library.sp
.param  Rtop=1000
.param  Rbot=3000
Vin   in    0     DC 1
R1    in    out   {Rtop}
R2    out   0     {Rbot}
.end
```

The same parameters could be written as `@table Rtop Rbot` (taking the
values of variables `Rtop` and `Rbot`), `["Rtop" => 1u"kΩ", "Rbot" => 3u"kΩ"]`,
`[Parameter("Rtop", 1u"kΩ"), Parameter("Rbot", 3u"kΩ")]`, or `.param` text;
see [`parameter_list`](@ref). A parameter can be an expression of others:
`Parameter("R2", "{3*Rtop}")`.

Values with units are written in SI units, and angular frequencies are not
converted: `1u"krad/s"` is written as `1000`. Where a parameter is used as a
frequency in Hz (e.g. `Vsin(...; frequency=:fs)`), give it in Hz:
`@table fs=Hz(ω)`.

SPICE names are not case sensitive, so giving `R` and `r` is an error, as is
giving any name twice.

## Subcircuits

A [`Subcircuit`](@ref) is a reusable block with terminals and default
parameters. Put its definition in `models` and add instances with
[`Subckt`](@ref), connected to nodes in the order of its terminals. An
instance can override the defaults:

```julia
divider = Subcircuit(name="divider", terminals=["top", "mid"], parameters=(R=1u"kΩ",),
                     components=[Resistor("R1", "top", "mid", :R),
                                 Resistor("R2", "mid", 0, :R)])
n = Netlist(title="two dividers", models=[divider],
            sources=[Vdc("in", "in", 0, 2u"V")],
            components=[Subckt("X1", ["in", "a"], "divider"),
                        Subckt("X2", ["a", "b"], "divider", (R=10u"kΩ",))])
```

```
.subckt divider top mid
+params: R=1000
R1    top   mid   {R}
R2    mid   0     {R}
.ends
...
X1    in    a     divider
X2    a     b     divider R=10000
```

ngspice silently ignores an instance parameter that its subcircuit doesn't
declare, so a misspelled name would have no effect. A `Netlist` checks
instances against the subcircuits it defines:

```julia
Netlist(models=[divider], components=[Subckt("X3", ["in", "c"], "divider", (Rx=1,))])
# ArgumentError: X3 sets parameter Rx, but subcircuit divider only has R
```

## Global nets

Nets such as a supply rail can be shared by the whole circuit, including
inside subcircuits, without passing them in as terminals. Ground (`0`) is
always global.

```julia
load = Subcircuit(name="loaded", terminals=["out"],
                  components=[Resistor("RL", "vdd", "out", 10u"kΩ")])
n = Netlist(title="globals", globals=["vdd"], models=[load],
            sources=[Vdc("DD", "vdd", 0, 5u"V")],
            components=[Subckt("X1", ["out"], "loaded"), Resistor("R2", "out", 0, 10u"kΩ")])
```

This writes `.global vdd` at the top of the netlist.

## Mixing in SPICE text

Anywhere a netlist takes elements, it also takes SPICE text: a line written by
hand, or the result of the [SPICE text functions](text.md). Vectors may be
nested; empty strings and `nothing` are dropped.

```julia
Netlist(components=[Resistor("R1", 1, 2, 1u"kΩ"), "C1 2 0 1n", resistor("R2", 2, 0, 1u"kΩ")])
```
