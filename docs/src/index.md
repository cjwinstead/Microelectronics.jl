```@meta
CurrentModule = Microelectronics
```

# Microelectronics.jl

!!! note "Next major version"
    These pages document the `dev` branch, which will become the next major
    version and differs from the current release in places. For the release
    used in courses, see the [stable documentation](https://cjwinstead.github.io/Microelectronics.jl/stable/).

Microelectronics.jl builds circuits in Julia, simulates them with
[ngspice](https://ngspice.sourceforge.io/) (through
[NgHerb.jl](https://github.com/cjwinstead/NgHerb.jl)), and reads, plots and
tabulates the results. It is written for teaching circuit design in Jupyter
notebooks, so component values carry units (`1u"kΩ"`, `10u"nF"`) and results
come back with units too.

## Installation

The package is registered in the LEFT registry. In Julia's package mode
(press `]`):

```
pkg> registry add https://github.com/cjwinstead/LEFT_registry
pkg> add Microelectronics
```

Plotting is optional: install [Plots.jl](https://docs.juliaplots.org/) as
well to draw results.

## A first circuit

An RC low-pass filter, its frequency response, and its cutoff frequency:

```julia
using Microelectronics

n = Netlist(title="RC low-pass",
            sources=[Vac("in", "in", 0)],
            components=[Resistor("R1", "in", "out", 1u"kΩ"),
                        Capacitor("C1", "out", 0, 1u"μF")])
load_netlist(n)
simulate(:ac; start=10u"Hz", stop=100u"kHz", steps=10)
measure(:cutoff; name="out")       # 159.4 Hz
```

`print(n)` shows the SPICE netlist that was simulated:

```
* RC low-pass
.include .../model_library.sp
Vin   in    0     AC 1
R1    in    out   1000
C1    out   0     1e-06
.end
```

With Plots loaded, `bode("out")` draws the magnitude and phase.

## Where to go next

- [Building netlists](netlists.md): components, sources, parameters, subcircuits
  and global nets
- [Simulations and results](simulations.md): analyses, and reading voltages,
  currents and sweeps
- [Plots and reports](plots.md): plotting with Plots.jl and parameter tables
- [Transistors](transistors.md): MOSFETs, their operating points and characteristic curves
- [SPICE text functions](text.md): the older functions that return SPICE lines as text
- [Reference](reference.md): every function and type
