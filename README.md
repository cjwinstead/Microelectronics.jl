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
* **Plots** -- some common plot definitions including transient, dc sweep, and Bode plots.

This module is in an early stage. Dependencies are still being added and removed; for
example I'm still deciding whether it makes sense to have NgHerb (or NgSpice) as a 
dependency, as opposed to treating it as a companion module. My bias is to load everything 
(NgHerb, Plots, etc) so that students don't need to learn too much about Julia packages
before they can complete assignments.
