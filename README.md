# Microelectronics

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cjwinstead.github.io/Microelectronics.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cjwinstead.github.io/Microelectronics.jl/dev/)
[![Build Status](https://github.com/cjwinstead/Microelectronics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cjwinstead/Microelectronics.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/cjwinstead/Microelectronics.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/cjwinstead/Microelectronics.jl)

This package is intended to provide a convenient interface to `ngspice`
from within JupyterNotebooks, JupyterLab or JupyterHub using Julia
kernels. Microelectronics.jl relies on the NgHerb.jl package (derived
from NgSpice.jl), with various additons that support the author's teaching 
needs. Primary features of Microelectronics.jl include:

* **Netlist creation** -- SPICE elements are instantiated via a variety of Julia functions.
* **Unitful conversions** -- set component parameters with Unitful, e.g. `1u"nF"` is rendered as `1e-9` in the netlist.
* **Plots** -- plot recipes for simulation results (`plot(signals("in","out"))`), Bode plots
  (`bode("out")`) and spectra. Load a plotting package to draw them: `using Microelectronics, Plots`.

## Dependencies

Microelectronics keeps its dependencies small: NgHerb (the ngspice interface),
Unitful, OrderedCollections, RecipesBase, Reexport, and the Printf standard library.
Plotting uses recipes, so any package that supports RecipesBase recipes can draw
the results; Plots.jl is the usual choice:

```julia
using Microelectronics, Plots

build_netlist(; sources=[Vsin("VIN","in",0; amplitude=1u"V", frequency=1u"kHz")],
                components=[Resistor("R1","in","out",1u"kΩ"), Capacitor("C1","out",0,100u"nF")])
simulate(:tran; tstep=10u"μs", tmax=2u"ms")
plot(signals("in", "out", "VIN"))       # voltages and the source current
```
