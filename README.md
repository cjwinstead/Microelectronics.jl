# Microelectronics

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cjwinstead.github.io/Microelectronics.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cjwinstead.github.io/Microelectronics.jl/dev/)
[![Build Status](https://github.com/cjwinstead/Microelectronics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cjwinstead/Microelectronics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/cjwinstead/Microelectronics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/cjwinstead/Microelectronics.jl)

Microelectronics.jl builds circuits in Julia, simulates them with
[ngspice](https://ngspice.sourceforge.io/) through
[NgHerb.jl](https://github.com/cjwinstead/NgHerb.jl), and reads, plots and
tabulates the results. It was written for teaching circuit design in Jupyter
notebooks: component values carry units (`1u"kΩ"`, `10u"nF"`), and so do the
results.

## Installation

Microelectronics is registered in the
[LEFT registry](https://github.com/cjwinstead/LEFT_registry). In Julia's
package mode (press `]`):

```
pkg> registry add https://github.com/cjwinstead/LEFT_registry
pkg> add Microelectronics
```

`using Microelectronics` also loads Unitful (for `u"..."` units) and Plots.

## Example

An RC low-pass filter: build it, simulate its frequency response, and find
the cutoff frequency.

```julia
using Microelectronics

n = Netlist(title="RC low-pass",
            sources=[Vac("in", "in", 0)],
            components=[Resistor("R1", "in", "out", 1u"kΩ"),
                        Capacitor("C1", "out", 0, 1u"μF")])
load_netlist(n)
simulate(:ac; start=10u"Hz", stop=100u"kHz", steps=10)

measure(:cutoff; name="out")      # 159.4 Hz
bode("out")                       # magnitude and phase plots
```

## Features

- **Netlists from Julia objects**: resistors, capacitors, inductors, diodes,
  MOSFETs, op-amps, controlled sources, and DC, AC, sine, pulse and PWL
  sources, with values in any units. Parameters, subcircuits with default
  parameters, and global nets.
- **SPICE text functions** (`resistor`, `vsin`, `build_netlist`, ...) that
  return netlist lines as text, for writing netlists line by line.
- **Simulations**: operating point, transient, DC sweeps (including nested
  sweeps for families of curves) and AC analyses.
- **Results with units**: `node"out"`, `i"VDD"`, `dB"out"` and `phase"out"`,
  MOSFET operating points with `device_values`, and measurements such as
  gain, slew rate and cutoff frequency.
- **Plots and tables**: `plot("in", "out")`, Bode plots, spectra, and
  parameter tables with `@table` and `report`.
- **A model library** with op-amp subcircuits, diodes, BJTs and MOSFETs,
  included in every netlist.

## Documentation

The [documentation](https://cjwinstead.github.io/Microelectronics.jl/stable/)
has a guide to building netlists, running simulations and plotting results,
and a reference for every function.
