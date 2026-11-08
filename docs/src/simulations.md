# Simulations and results

```@meta
CurrentModule = Microelectronics
```

After [`load_netlist`](@ref) (or [`build_netlist`](@ref)), run an analysis
with [`simulate`](@ref) and read the results. Values can be given with units
or as plain SI numbers.

| Analysis | Call |
|:-------- |:---- |
| operating point | `simulate(:op)` |
| transient | `simulate(:tran; tstep=1u"μs", tmax=2u"ms")` |
| DC sweep | `simulate(:dc; device="V1", start=0u"V", stop=5u"V", step=0.1u"V")` |
| nested DC sweep | `simulate(:dc; device="VDS", start=0, stop=5, step=0.1, sweep2=("VGS", 1, 3, 1))` |
| AC (frequency response) | `simulate(:ac; start=10u"Hz", stop=1u"MHz", steps=10)` |

An AC sweep is logarithmic by default, with `steps` points per decade; use
`mode=:oct` or `mode=:lin` to change that. Frequencies given in rad/s are
converted to Hz.

## Reading results

Names of nodes and sources are not case sensitive.

- `node"out"` is the voltage at node `out`, and `i"VDD"` the current in
  voltage source `VDD`, as vectors with units, scaled to a readable unit
  (V, mV, μV, ...). After an operating point they have one element.
- [`signals`](@ref) collects several voltages and currents, with the
  analysis' time, sweep or frequency axis, ready to plot.
- `dB"out"` and `phase"out"` give the magnitude (in dB) and phase (in
  degrees) after an AC analysis.
- [`tran_time`](@ref), [`dc_sweep`](@ref) and [`ac_freq`](@ref) give the
  independent variable of the latest analysis.
- [`device_values`](@ref) gives a MOSFET's currents, voltages and small-signal
  parameters.

```julia
load_netlist(n)
simulate(:op)
node"out"                    # [750.0 mV]

simulate(:tran; tstep=1u"μs", tmax=2u"ms")
s = signals("in", "out", "Vin")
# Signals from the :tran analysis (2048 points): V(in) [V], V(out) [mV], I(vin) [μA]
maximum(s["out"])            # 993.3 mV
```

ngspice's sign convention for currents: a positive current flows into a
source's first (`nplus`) node, through the source. A supply that delivers
current therefore shows a negative current, e.g. `i"VDD"` is `-1.363 mA`.

The string macros (`node""`, `i""`, ...) read the latest results each time
the code runs, so they also work inside loops and functions.

## Nested sweeps

With `sweep2`, the inner sweep is repeated for each value of an outer
source, giving a family of curves. [`sweep_curves`](@ref) tells which points
belong to which curve, and [`signals`](@ref) and plots use it automatically:

```julia
simulate(:dc; device="VDS", start=0u"V", stop=5u"V", step=0.1u"V",
              sweep2=("VGS", 1u"V", 3u"V", 1u"V"))
sweep_curves(length(dc_sweep()))
# (1:51, "VGS = 1 V"), (52:102, "VGS = 2 V"), (103:153, "VGS = 3 V")
```

## Measurements

[`measure`](@ref) computes common figures of merit from the latest
simulation: a transient gain (`:Av`), transconductance (`:Gm`), slew rate
(`:slew`), or the -3 dB cutoff frequency of an AC analysis (`:cutoff`).

```julia
simulate(:ac; start=10u"Hz", stop=100u"kHz", steps=10)
measure(:cutoff; name="out")         # 159.4 Hz
```

[`fft`](@ref), [`distortion`](@ref) and [`Spectrum`](@ref) analyse the
spectrum and harmonic distortion of a periodic signal.

## When something goes wrong

In notebooks ngspice's messages are hidden by default. [`be_verbose`](@ref) shows them,
[`be_quiet`](@ref) hides them again, and [`dumpbuffer`](@ref) prints the
messages collected so far, which usually explain why an analysis failed.
[`analysis_kind`](@ref) tells which analysis produced the current results.
