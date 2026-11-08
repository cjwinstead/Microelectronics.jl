#=
Docstrings for names whose definitions are generated in loops (the
independent sources and the text builders), or are one-liners spread over
several files. Kept together here so each family is documented in one place.
=#

#===================== Netlist objects =====================#

"""
    Element


The supertype of everything that can go in a [`Netlist`](@ref) or
[`Subcircuit`](@ref): [`Component`](@ref)s (resistors, capacitors, diodes,
MOSFETs, subcircuit instances, ...), independent [`Source`](@ref)s, the
controlled sources [`VCVS`](@ref), [`VCCS`](@ref), [`CCVS`](@ref) and
[`CCCS`](@ref), and raw SPICE text ([`SpiceLine`](@ref)).

`string(e)` gives the element's SPICE line.
"""
Element

"""
    Component


A netlist element with a name, nodes, and optionally a value, a model name
and instance parameters. Components are usually made with
[`Resistor`](@ref), [`Capacitor`](@ref), [`Inductor`](@ref),
[`Diode`](@ref), [`Subckt`](@ref), [`Opamp`](@ref), [`NMOS`](@ref),
[`PMOS`](@ref) or [`MOSFET`](@ref).

Fields: `name`, `species` (e.g. `"resistor"`), `prefix` (the SPICE letter,
e.g. `"R"`), `nodes`, `value`, `model` and `parameters`.

The keyword constructor
`Component(; name, species, prefix, nodes, value, model, parameters)` adds
the prefix to the name when it is missing, and chooses the next free name
(R1, R2, ...) when no name is given.
"""
Component

"""
    Resistor(name, nplus, nminus, value)
    Resistor(; name, nplus, nminus, value)


A resistor between nodes `nplus` and `nminus`. The `value` can be a
quantity (`1u"kΩ"`), a number in ohms, a SPICE string (`"4.7k"`) or a
parameter name as a Symbol (`:R`, written `{R}`). The `R` prefix is added
to the name if it is missing; without a name the next free name (R1, R2,
...) is used. Nodes can be integers, strings or symbols.

# Examples

```jldoctest
julia> Resistor("R1", 1, 2, 2.2u"kΩ")
R1    1     2     2200

julia> Resistor("load", "out", 0, :RL)
Rload out   0     {RL}
```
"""
Resistor

"""
    Capacitor(name, nplus, nminus, value)
    Capacitor(; name, nplus, nminus, value)


A capacitor between nodes `nplus` and `nminus`. The `value` is given as for
[`Resistor`](@ref), e.g. `1u"nF"`, `:C` or `"10p"`.

# Example

```jldoctest
julia> Capacitor("C1", "out", 0, 10u"nF")
C1    out   0     1e-08
```
"""
Capacitor

"""
    Inductor(name, nplus, nminus, value)
    Inductor(; name, nplus, nminus, value)


An inductor between nodes `nplus` and `nminus`. The `value` is given as for
[`Resistor`](@ref), e.g. `1u"mH"`.

# Example

```jldoctest
julia> Inductor("L1", 1, 2, 1u"mH")
L1    1     2     0.001
```
"""
Inductor

"""
    Diode(name, nplus, nminus, model)
    Diode(; name, nplus, nminus, model)


A diode from anode `nplus` to cathode `nminus`, using the diode `model`.
The [`model_library`](@ref) includes `D1N4004`, `D1N914`, `D1N4148`,
`SFH235` and `SFH4554`.

# Example

```jldoctest
julia> Diode("D1", "in", "out", "D1N4004")
D1    in    out   D1N4004
```
"""
Diode

"""
    Opamp(name, nplus, nminus, out, model, parameters=[])
    Opamp(; name, nplus, nminus, out, model, parameters=[])


An op-amp: an instance of the three-terminal subcircuit `model`, connected
as (non-inverting input, inverting input, output). The
[`model_library`](@ref) includes `ideal_opamp`, `saturating_opamp`,
`two_stage_opamp`, `ideal_ota` and `saturating_ota`.

# Example

```jldoctest
julia> Opamp("A1", "inp", "inn", "out", "ideal_opamp")
XA1   inp   inn   out   ideal_opamp
```
"""
Opamp

"""
    Instance(args...; kwargs...)


Another name for [`Subckt`](@ref).
"""
Instance

"""
    VCVS(; name, nplus, nminus, control, gain)


A voltage-controlled voltage source (`E`): the voltage from `nplus` to
`nminus` is `gain` times the voltage between the two `control` nodes.
`gain` can be a number or a parameter name as a Symbol.

# Example

```jldoctest
julia> VCVS(name="E1", nplus="out", nminus="0", control=["inp","inn"], gain=1000)
E1    out   0     inp   inn   1000
```
"""
VCVS

"""
    VCCS(; name, nplus, nminus, control, gain)


A voltage-controlled current source (`G`): the current from `nplus` to
`nminus` through the source is `gain` (a transconductance, e.g. `1u"mS"`)
times the voltage between the two `control` nodes.

# Example

```jldoctest
julia> VCCS(name="G1", nplus="out", nminus="0", control=["in","0"], gain=1u"mS")
G1    out   0     in    0     0.001
```
"""
VCCS

"""
    CCVS(; name, nplus, nminus, control, gain)


A current-controlled voltage source (`H`): the voltage from `nplus` to
`nminus` is `gain` (a transresistance, e.g. `1u"kΩ"`) times the current in
the voltage source named `control`. The `V` prefix is added to `control`
if it is missing.

# Example

```jldoctest
julia> CCVS(name="H1", nplus="out", nminus="0", control="sense", gain=1u"kΩ")
H1    out   0     Vsense 1000
```
"""
CCVS

"""
    CCCS(; name, nplus, nminus, control, gain)


A current-controlled current source (`F`): the current from `nplus` to
`nminus` through the source is `gain` times the current in the voltage
source named `control`. The `V` prefix is added to `control` if it is
missing.

# Example

```jldoctest
julia> CCCS(name="F1", nplus="out", nminus="0", control="Vsense", gain=50)
F1    out   0     Vsense 50
```
"""
CCCS

"""
    Parameter(name, value)
    Parameter(name => value)
    Parameter((name, value))


A named value: a `.param` line in a [`Netlist`](@ref), a default in a
[`Subcircuit`](@ref), or an instance parameter such as a MOSFET's `W`.
The `value` can be a quantity (written in SI units), a number, a SPICE
expression as a string (`"{2*R}"`), or another parameter's name as a Symbol
(`:R`, written `{R}`). The name can be a String or a Symbol.

`Parameter(table)` gives a vector of parameters from a table made with
[`@table`](@ref). Constructors take lists of parameters in many forms; see
[`parameter_list`](@ref).

# Example

```jldoctest
julia> string(Parameter("R", 1u"kΩ"))
"R=1000"
```
"""
Parameter

"""
    Model(name, definition)


A `.model` line: `Model("dx", "D(IS=1e-14)")` writes
`.model dx D(IS=1e-14)`. A `definition` that is already a complete SPICE
line (starting with `.`) is written as it is. Put models in a
[`Netlist`](@ref)'s `models`.

# Example

```jldoctest
julia> string(Model("dx", "D(IS=1e-14 N=1.8)"))
".model dx D(IS=1e-14 N=1.8)"
```
"""
Model

"""
    Include(filename)


An `.include filename` line, to read models or subcircuits from a file. A
[`Netlist`](@ref) includes the package's [`model_library`](@ref) by
default; its `includes` keyword also takes plain file names.
"""
Include

"""
    Point(time, value)
    Point((time, value))


One point of a piecewise-linear (PWL) waveform. Times and values can be
quantities or plain numbers (seconds, and volts or amperes). A vector of
`(time, value)` tuples can be used wherever points are expected, e.g. in
[`Vpwl`](@ref).
"""
Point

"""
    Waveform(kind, args...; kwargs...)


The value of an independent source: one of

- `Waveform(:dc, value)`, written `DC value`
- `Waveform(:ac, magnitude=1)`, written `AC magnitude`, for AC analyses
- `Waveform(:sin; offset, amplitude, frequency, phase)`, or
  `Waveform(:sin, offset, amplitude, frequency, phase=0)`
- `Waveform(:pulse; low, high, delay, risetime, falltime, width, period, pulses)`
- `Waveform(:pwl, points)`, with points as [`Point`](@ref)s or tuples
- `Waveform(:raw, text)`, SPICE text written as it is

Defaults for the sine are 0 V offset, 5 mV amplitude, 1 kHz and 0°; for
the pulse 0 to 5 V, 10 ns delay and edges, 490 ns width and a 1 ms period.
A sine's `frequency` may be given in rad/s; it is converted to Hz.
A [`Source`](@ref) holds one or more waveforms. In a notebook, a source
is displayed as a summary of its waveforms; `print` shows its SPICE line.

# Examples

```jldoctest
julia> print(Waveform(:sin; amplitude=1u"V", frequency=10u"kHz"))
 SIN (0,1,10000,0)

julia> print(Waveform(:dc, 5u"V"))
 DC 5
```
"""
Waveform

"""
    Source


An independent voltage or current source with one or more
[`Waveform`](@ref)s, e.g. a DC value for the operating point, an AC
magnitude for AC analyses and a sine for transient analyses. Sources are
usually made with [`Vdc`](@ref), [`Vac`](@ref), [`Vsin`](@ref),
[`Vpulse`](@ref), [`Vpwl`](@ref) or [`Vsource`](@ref), and their current
source equivalents (`Idc`, `Iac`, ...).

Fields: `name`, `species` (`"vsource"` or `"isource"`), `prefix`
(`"V"` or `"I"`), `nodes` and `waveforms`.

See also [`alter`](@ref), to change a sine source's settings.
"""
Source


#===================== Independent sources =====================#

const SOURCE_KEYWORDS = """
Every source also takes the keywords `dc`, `ac`, `pwl` and `pulse` to add
more waveforms, e.g. `Vsin("in", 1, 0; amplitude=1u"V", ac=1)` for a source
that drives both transient and AC analyses. DC and AC values are always
written first. The `V` (or `I`) prefix is added to the name if it is
missing, and without a name the next free name is used."""

"""
    Vdc(name, nplus, nminus, value=0; kwargs...)
    Idc(name, nplus, nminus, value=0; kwargs...)


A DC voltage (current) source from `nplus` to `nminus`, e.g. `5u"V"`
(`1u"mA"`). A current source's current flows from `nplus` through the
source to `nminus`.

$SOURCE_KEYWORDS

# Examples

```jldoctest
julia> print(Vdc("DD", "vdd", 0, 5u"V"))
VDD   vdd   0     DC 5

julia> print(Idc("I1", "vdd", "d", 100u"μA"))
I1    vdd   d     DC 0.0001
```
"""
Vdc

"""
    Idc(name, nplus, nminus, value=0; kwargs...)


A DC current source; the same as [`Vdc`](@ref) for a current.
"""
Idc

"""
    Vac(name, nplus, nminus, value=1; kwargs...)
    Iac(name, nplus, nminus, value=1; kwargs...)


A voltage (current) source with AC magnitude `value`, for AC (frequency
response) analyses. With magnitude 1, node voltages in the results are
transfer functions.

$SOURCE_KEYWORDS

# Example

```jldoctest
julia> print(Vac("in", "in", 0))
Vin   in    0     AC 1
```
"""
Vac

"""
    Iac(name, nplus, nminus, value=1; kwargs...)


A current source with an AC magnitude; the same as [`Vac`](@ref) for a current.
"""
Iac

"""
    Vsin(name, nplus, nminus; offset, amplitude, frequency, phase, kwargs...)
    Isin(name, nplus, nminus; offset, amplitude, frequency, phase, kwargs...)


A sinusoidal voltage (current) source for transient analyses. Defaults:
`offset=0u"V"`, `amplitude=5u"mV"`, `frequency=1u"kHz"`, `phase=0u"°"`. The
frequency may be given in rad/s (it is converted to Hz), and the phase in
degrees or radians.

$SOURCE_KEYWORDS

# Examples

```jldoctest
julia> print(Vsin("in", "in", 0; amplitude=1u"V", frequency=10u"kHz"))
Vin   in    0     SIN (0,1,10000,0)

julia> print(Vsin("in", "in", 0; amplitude=1u"V", ac=1))
Vin   in    0     AC 1 SIN (0,1,1000,0)
```
"""
Vsin

"""
    Isin(name, nplus, nminus; offset, amplitude, frequency, phase, kwargs...)


A sinusoidal current source; the same as [`Vsin`](@ref) for a current.
"""
Isin

"""
    Vpulse(name, nplus, nminus; low, high, delay, risetime, falltime, width, period, pulses, kwargs...)
    Ipulse(name, nplus, nminus; low, high, delay, risetime, falltime, width, period, pulses, kwargs...)


A pulse (square wave) voltage (current) source for transient analyses.
Defaults: from `low=0u"V"` to `high=5u"V"`, `delay`, `risetime` and
`falltime` of 10 ns, `width=490u"ns"` and `period=1u"ms"`. `pulses` limits
the number of pulses.

$SOURCE_KEYWORDS

# Example

```jldoctest
julia> print(Vpulse("clk", "clk", 0; high=3.3u"V", width=0.5u"ms", period=1u"ms"))
Vclk  clk   0     PULSE (0 3.3 1e-08 1e-08 1e-08 0.0005 0.001  )
```
"""
Vpulse

"""
    Ipulse(name, nplus, nminus; low, high, delay, risetime, falltime, width, period, pulses, kwargs...)


A pulse current source; the same as [`Vpulse`](@ref) for a current.
"""
Ipulse

"""
    Vpwl(name, nplus, nminus, points; kwargs...)
    Ipwl(name, nplus, nminus, points; kwargs...)


A piecewise-linear voltage (current) source for transient analyses, through
`points` given as `(time, value)` tuples or [`Point`](@ref)s. The
[`@pwl_str`](@ref) macro reads points from a two-column table.

$SOURCE_KEYWORDS

# Example

```jldoctest
julia> print(Vpwl("ramp", "in", 0, [(0, 0), (1u"ms", 1u"V"), (2u"ms", 1u"V")]))
Vramp in    0     PWL ( 0 0 0.001 1 0.002 1)
```
"""
Vpwl

"""
    Ipwl(name, nplus, nminus, points; kwargs...)


A piecewise-linear current source; the same as [`Vpwl`](@ref) for a current.
"""
Ipwl

"""
    Vsource(name, nplus, nminus; dc, ac, pwl, pulse)
    Isource(name, nplus, nminus; dc, ac, pwl, pulse)


A voltage (current) source with only the waveforms given by keywords; with
none, a source with no value (0 V, which can still measure a current).

# Example

```jldoctest
julia> print(Vsource("sense", "a", "b"))
Vsense a     b
```
"""
Vsource

"""
    Isource(name, nplus, nminus; dc, ac, pwl, pulse)


A current source with the waveforms given by keywords; the same as [`Vsource`](@ref) for a current.
"""
Isource


#===================== Text builders =====================#

"""
    resistor(nplus, nminus, value)
    resistor(name, nplus, nminus, value)
    resistor(; name, nplus, nminus, value)


The SPICE line for a resistor, as [`SpiceText`](@ref): the same as
`string(Resistor(...))`. Without a name the next free name is used.
[`capacitor`](@ref), [`inductor`](@ref) and [`diode`](@ref) (with a model
name as the value) work the same way.

# Example

```jldoctest
julia> resistor("R1", 1, 2, 1u"kΩ")
R1    1     2     1000
```
"""
resistor

for (f, what) in ((:capacitor, "a capacitor"), (:inductor, "an inductor"),
                  (:diode, "a diode (the value is the model name)"))
    @eval @doc $("""
        $f(nplus, nminus, value)
        $f(name, nplus, nminus, value)
        $f(; name, nplus, nminus, value)

    The SPICE line for $what, as [`SpiceText`](@ref); see [`resistor`](@ref).
    """) $f
end

"""
    vdc(name, nplus, nminus, dc; kwargs...)
    vac(name, nplus, nminus, ac; kwargs...)
    vsin(name, nplus, nminus, offset, amplitude, frequency; kwargs...)
    vpulse(name, nplus, nminus; kwargs...)
    vpwl(name, nplus, nminus; points, kwargs...)


The SPICE line for a voltage source, as [`SpiceText`](@ref). [`idc`](@ref),
[`iac`](@ref), [`isin`](@ref), [`ipulse`](@ref) and [`ipwl`](@ref) give
current sources. All of them also
take everything as keywords, e.g. `vsin(; name, nplus, nminus, amplitude)`,
with the same defaults as [`Vsin`](@ref), [`Vpulse`](@ref) etc. Mixing
waveform keywords gives a source with several values, e.g.
`vsin(...; ac=1)`.

These are the text versions of [`Vdc`](@ref), [`Vac`](@ref),
[`Vsin`](@ref), [`Vpulse`](@ref) and [`Vpwl`](@ref).

# Examples

```jldoctest
julia> vdc("DD", "vdd", 0, 5u"V")
VDD   vdd   0     DC 5

julia> vsin("in", "in", 0; amplitude=1u"V", frequency=1u"kHz", ac=1)
Vin   in    0     AC 1 SIN (0,1,1000,0)
```
"""
vdc

for (f, obj) in ((:vac, :Vac), (:vsin, :Vsin), (:vpulse, :Vpulse), (:vpwl, :Vpwl),
                 (:idc, :Idc), (:iac, :Iac), (:isin, :Isin), (:ipulse, :Ipulse), (:ipwl, :Ipwl))
    @eval @doc $("""
        $f(name, nplus, nminus, ...; kwargs...)
        $f(; name, nplus, nminus, kwargs...)

    The SPICE line for a source, as [`SpiceText`](@ref): the text version of
    [`$obj`](@ref). See [`vdc`](@ref) for the forms it takes.
    """) $f
end

"""
    subckt_instance(; name, terminals, model)


The SPICE line for an instance of subcircuit `model`, as
[`SpiceText`](@ref). `terminals` is a vector of nodes or a string of
space-separated node names. The text version of [`Subckt`](@ref).

# Example

```jldoctest
julia> subckt_instance(name="X1", terminals="in out", model="divider")
X1    in    out   divider
```
"""
subckt_instance


#===================== Units =====================#

"""
    parallel(R1, R2, ...)


The resistance of resistors in parallel, in Ω.

# Example

```jldoctest
julia> parallel(1u"kΩ", 1u"kΩ")
500.0 Ω
```
"""
parallel

"""
    scale_quantity(x)


`x` in the SI prefix that reads best for its magnitude: e.g. `0.0047u"A"`
becomes 4.7 mA and `1500u"Ω"` becomes 1.5 kΩ. Handles time, frequency (Hz
and rad/s), resistance, capacitance, voltage, current and transconductance;
other quantities are returned unchanged. [`report`](@ref) uses it for its
table.

[`scale_resistor`](@ref), [`scale_capacitor`](@ref), [`scale_Hz`](@ref),
[`scale_rad`](@ref) and [`scale_s`](@ref) do the same for one kind of quantity.

# Example

```jldoctest
julia> scale_quantity(0.0047u"A")
4.7 mA
```
"""
scale_quantity

for (f, units) in ((:scale_resistor, "Ω, kΩ or MΩ"), (:scale_capacitor, "fF, pF, nF or μF"),
                   (:scale_Hz, "mHz, Hz, kHz, MHz or GHz"), (:scale_rad, "mrad/s ... Grad/s"),
                   (:scale_s, "fs, ps, ns, μs, ms or s"))
    @eval @doc $("""
        $f(x)

    `x` converted to $units, whichever suits its magnitude; see [`scale_quantity`](@ref).
    """) $f
end

"""
    isHz(x::Quantity)


Whether `x` is a frequency in Hz. [`isradps`](@ref), [`israd`](@ref),
[`is°`](@ref), [`iss`](@ref), [`isvoltage`](@ref), [`iscurrent`](@ref),
[`isresistor`](@ref), [`iscapacitor`](@ref) and [`istransconductance`](@ref)
check for other kinds of quantity. The frequency and angle checks look at
the unit, since Hz and rad/s (and rad and °) have the same dimension.

# Example

```jldoctest
julia> isHz(1u"kHz"), isHz(1u"rad/s"), isradps(1u"rad/s")
(true, false, true)
```
"""
isHz

for (f, what) in ((:isradps, "an angular frequency in rad/s"), (:israd, "an angle in radians"),
                  (:is°, "an angle in degrees"), (:iss, "a time"), (:isvoltage, "a voltage"),
                  (:iscurrent, "a current"), (:isresistor, "a resistance"),
                  (:iscapacitor, "a capacitance"), (:istransconductance, "a transconductance"))
    @eval @doc $("""
        $f(x::Quantity)

    Whether `x` is $what; see [`isHz`](@ref).
    """) $f
end


#===================== Simulation helpers =====================#

"""
    model_library()


The path of the SPICE model library that comes with the package. A
[`Netlist`](@ref) includes it by default. It defines op-amps
(`ideal_opamp`, `saturating_opamp`, `two_stage_opamp`, `ideal_ota`,
`saturating_ota`), diodes (`D1N4004`, `D1N914`, `D1N4148`, `SFH235`,
`SFH4554`), BJTs (`Q2N2222`, `Q2N2907A`, `Q2N3904`, `Q2N3906`) and MOSFETs
(`ald1105n`, `ald1105p`, `CD4007N`, `CD4007P`).
"""
model_library

"""
    dumpbuffer()


Print the messages ngspice has written since they were last printed or
cleared. Useful after [`be_quiet`](@ref), to see why an analysis failed.
"""
dumpbuffer

"""
    transient(; tstep, tmax, maxstep=nothing)


Run a transient analysis from 0 to `tmax`, with results every `tstep`;
`maxstep` limits ngspice's internal time step. The same as
`simulate(:tran; tstep, tmax, maxstep)`; see [`simulate`](@ref).
"""
transient

"""
    alter(source; frequency, amplitude, offset, phase)


Change the settings of a sine [`Source`](@ref) in place, e.g. to sweep its
frequency over several simulations. The source must have exactly one sine
waveform; only the given settings change. Rebuild and reload the netlist
for the change to take effect.

# Example

```jldoctest
julia> s = Vsin("in", "in", 0; amplitude=1u"V", frequency=1u"kHz");

julia> alter(s; frequency=2u"kHz");

julia> print(s)
Vin   in    0     SIN (0,1,2000,0)
```
"""
alter

"""
    device_prefix(species)


The SPICE prefix letter for a device species, e.g. `device_prefix("resistor")`
is `"R"` and `device_prefix("vcvs")` is `"E"`.
"""
device_prefix

"""
    Spectrum(node, fundamental; N=20, D=50)


Run a transient analysis of `N` periods of the `fundamental` frequency (with
`D` time steps per period) and analyse the spectrum of the voltage at
`node`. Fields:

- `fundamental`, the frequency analysed
- `f`, `mag`, `phase` and `db`, the FFT spectrum, with units
- `harmonics`, `(amplitude, phase)` of harmonics 1, 2, ...
- `thd`, the total harmonic distortion (a ratio, not a percentage)

With Plots loaded, `plot(spectrum)` draws it. See also [`fft`](@ref) and
[`distortion`](@ref).
"""
Spectrum


#===================== String macros =====================#

"""
    node"name"


The voltage at node `name` from the latest simulation, as a vector with
units (scaled to V, mV, μV, ... to suit its size). The macro expands to a
function call, so it reads the latest results each time the code runs.

# Example

```julia-repl
julia> simulate(:op); node"out"
1-element Vector{Quantity{Float64, ...}}:
 2.5 V
```
"""
:(@node_str)

"""
    i"source"


The current in voltage source `source` from the latest simulation, as a
vector with units (A, mA, μA, ...). ngspice's convention is that a positive
current flows into the source's `nplus` node, through the source.
"""
:(@i_str)

"""
    dB"name"


The magnitude of node `name`'s voltage (or of another ngspice vector) in
decibels, `20 log10 |x|`, from the latest AC analysis.
"""
:(@dB_str)

"""
    phase"name"


The phase of node `name`'s voltage (or of another ngspice vector) in
degrees, from the latest AC analysis.
"""
:(@phase_str)

"""
    pwl"table"


Points for a piecewise-linear source from a two-column table of times and
values with units, one point per line.

# Example

```jldoctest
julia> pwl\"\"\"
       0s    0V
       1ms   1V
       \"\"\"
2-element Vector{Tuple{Number, Number}}:
 (0 s, 0 V)
 (1 ms, 1 V)
```
"""
:(@pwl_str)
