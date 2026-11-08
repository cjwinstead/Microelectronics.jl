# Plots and reports

```@meta
CurrentModule = Microelectronics
```

## Plotting

`using Microelectronics` loads [Plots](https://docs.juliaplots.org/), and
adds methods to its `plot` function for simulation results:

```julia
simulate(:tran; tstep=1u"μs", tmax=2u"ms")
plot("in", "out", "Vin")        # node voltages, and the current in source Vin

simulate(:ac; start=10u"Hz", stop=100u"kHz", steps=10)
bode("out")                     # magnitude in dB and phase in degrees
```

- `plot(names...)` draws node voltages and source currents against time,
  the swept source or frequency. Voltages and currents together get two y
  axes, with currents dashed. Each curve of a nested DC sweep is its own
  series, labelled with the outer source's value. See [`plot`](@ref).
- `plot([v1, v2, ...])` draws vectors you have read or computed, e.g.
  `plot([node"out" .- node"in"])`.
- [`bode`](@ref) draws magnitude and phase after an AC analysis.
- `plot(spectrum)` draws a [`Spectrum`](@ref) with lines at the harmonics.

Plots keyword arguments work as usual, e.g.
`plot("out"; title="Step response", labels="output")`.

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
