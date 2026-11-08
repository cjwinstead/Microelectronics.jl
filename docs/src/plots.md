# Plots and reports

```@meta
CurrentModule = Microelectronics
```

## Plotting

Microelectronics doesn't depend on a plotting package. It describes what to
draw, and any package that supports RecipesBase recipes draws it; Plots.jl
is the usual choice:

```julia
using Microelectronics, Plots

simulate(:tran; tstep=1u"μs", tmax=2u"ms")
plot(signals("in", "out", "Vin"))     # voltages and currents on separate panels

simulate(:ac; start=10u"Hz", stop=100u"kHz", steps=10)
bode("out")                           # magnitude in dB and phase in degrees
```

- `plot(signals(...))` draws each signal against time, the swept source or
  frequency, with units on the axes. Voltages and currents go on separate
  panels, and each curve of a nested DC sweep is its own series, labelled
  with the outer source's value. See [`signals`](@ref).
- [`bode`](@ref) draws magnitude and phase after an AC analysis.
- `plot(Spectrum(...))` draws a spectrum with lines at the harmonics; see
  [`Spectrum`](@ref).

Plots keyword arguments work as usual, e.g. `plot(signals("out"); title="Step response")`.
Drawing a plot before a plotting package is loaded gives an error that says
to run `using Plots`.

## Parameter tables

[`@table`](@ref) collects named values into a [`ParameterTable`](@ref),
which is displayed as a table with readable units, at most four significant
digits per value:

```julia
R = 1u"kΩ"; C = 10u"nF"
@table R C fc=Hz(1/(R*C))
```

```
| Parameter  |  Value        | Unit        |
|------------|---------------|-------------|
|R           |              1|           kΩ|
|C           |             10|           nF|
|fc          |          15.92|          kHz|
```

The same table can be used as netlist parameters: `Netlist(...; parameters=@table R C)`.

[`report`](@ref) prints a table from a named tuple or any dictionary, and
prints elements, netlists and messages in a readable form:

```julia
report((gain=-9.87, Rin=10e3u"Ω", fc=1592.5u"Hz"))
```

```
| Parameter  |  Value        | Unit        |
|------------|---------------|-------------|
|gain        |          -9.87|             |
|Rin         |             10|           kΩ|
|fc          |          1.593|          kHz|
```
