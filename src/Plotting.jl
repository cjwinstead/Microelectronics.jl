#=
Plotting

Microelectronics depends only on RecipesBase. It describes *what* to draw;
a plotting package that understands recipes (Plots.jl) draws it once loaded:

    using Microelectronics, Plots
    plot(signals("in", "out"))
    bode("out")

This keeps the package light and avoids adding methods to Plots' own
functions for types Microelectronics doesn't own.
=#

"Plot `x` with the loaded plotting package, or explain how to load one."
function plot_recipe(x; kw...)
    isempty(methods(RecipesBase.plot)) &&
        error("plotting needs a plotting package that supports recipes; run `using Plots` first")
    RecipesBase.plot(x; kw...)
end

# Prefixed units to choose from, by dimension, largest first (factor 1e3 ... 1e-12)
const SCALED_UNITS = Dict(dimension(u"V") => (u"kV", u"V", u"mV", u"μV", u"nV", u"pV"),
                          dimension(u"A") => (u"kA", u"A", u"mA", u"μA", u"nA", u"pA"))

"""
   autoscale(v)

Convert a vector of voltages or currents to the prefixed unit (kV, V, mV,
μV, ...) that suits its largest magnitude. Other quantities are returned
unchanged.
"""
function autoscale(v::AbstractVector)
    isempty(v) && return v
    units = get(SCALED_UNITS, dimension(first(v)), nothing)
    isnothing(units) && return v
    m = maximum(x -> abs(ustrip(units[2], x)), v)
    for (u, factor) in zip(units, (1e3, 1.0, 1e-3, 1e-6, 1e-9, 1e-12))
        m >= factor && return uconvert.(u, v)
    end
    return uconvert.(units[2], v)              # all (nearly) zero
end

# ngspice vector name -> label: "out" -> "V(out)", "V(1)" -> "V(1)", "v1#branch" -> "I(v1)"
function signal_label(vec)
    endswith(vec, "#branch") && return "I($(vec[1:end-7]))"
    m = match(r"^v\((.*)\)$"i, vec)
    return isnothing(m) ? "V($vec)" : "V($(m[1]))"
end


#========================== signals ==========================#

"""
   Signals

Node voltages and source currents from the latest simulation, with the
analysis' independent variable. Created by [`signals`](@ref).

- `s.kind`: the analysis, `:tran`, `:dc`, `:ac` or `:op`
- `s.x`: time, sweep values or frequency, with units (`nothing` for `:op`)
- `s["out"]`, `s["V1"]`, `s[1]`: one signal, with units (V or A, complex for AC)
- `keys(s)`: the signal labels, e.g. `["V(out)", "I(v1)"]`

With Plots loaded, `plot(s)` draws the signals against `s.x`; voltages and
currents go on separate panels.
"""
struct Signals
    kind::Symbol
    x::Union{Nothing,AbstractVector}
    xlabel::String
    names::Vector{String}            # as requested
    vectors::Vector{String}          # ngspice vector names
    labels::Vector{String}
    data::Vector{AbstractVector}
    voltage::Vector{Bool}
end

"""
   signals(names...; nodes=[], branches=[])

Collect node voltages and source currents from the latest simulation into a
[`Signals`](@ref) object.

Positional `names` can be nodes or voltage sources: each is looked up as a
node first, then as a source current. Use the keywords to be explicit:
`nodes` are only matched as node voltages and `branches` only as source
currents, which matters when a node and a source share a name. Names are not
case sensitive.

# Examples

```julia-repl
julia> s = signals("in", "out", "V1");      # V1's current

julia> s = signals(nodes=["in","out"], branches=["V1"]);

julia> s["out"]                             # voltage at node out, with units

julia> plot(s)                              # after `using Plots`
```
"""
function signals(names...; nodes=(), branches=())
    k = analysis_kind()
    k in (:op, :dc, :ac, :tran) ||
        throw(ArgumentError("there are no simulation results to read; run simulate(...) first"))
    requests = [[(string(n), find_vec(n)) for n in names];
                [(string(n), find_vec(n; branch=false)) for n in nodes];
                [(string(n), find_vec(n; node=false)) for n in branches]]
    isempty(requests) && throw(ArgumentError("name at least one node or voltage source"))

    vectors = last.(requests)
    info = [NgHerb.getvec(v) for v in vectors]          # (name, type, data)
    for (v, i) in zip(vectors, info)
        i[2] in ("voltage", "current") ||
            throw(ArgumentError("\"$v\" is neither a node voltage nor a source current"))
    end
    voltage = [i[2] == "voltage" for i in info]
    data = AbstractVector[autoscale(i[3] .* (isv ? u"V" : u"A")) for (i, isv) in zip(info, voltage)]
    x, xlabel = k == :op ? (nothing, "") : (simx(), simxlabel())
    Signals(k, x, xlabel, first.(requests), vectors, signal_label.(vectors), data, voltage)
end
export signals, Signals

Base.length(s::Signals) = length(s.data)
Base.keys(s::Signals) = s.labels
Base.getindex(s::Signals, i::Integer) = s.data[i]

function Base.getindex(s::Signals, name::AbstractString)
    key = lowercase(name)
    for i in eachindex(s.data)
        key in lowercase.((s.names[i], s.vectors[i], s.labels[i])) && return s.data[i]
    end
    throw(KeyError(name))
end

function Base.show(io::IO, s::Signals)
    n = isnothing(s.x) ? 1 : length(s.x)
    print(io, "Signals from the :$(s.kind) analysis ($n point$(n == 1 ? "" : "s")): ",
          join(("$(s.labels[i]) [$(unit(first(s.data[i])))]" for i in eachindex(s.data)), ", "))
end

RecipesBase.@recipe function f(s::Signals)
    s.kind == :ac && throw(ArgumentError(
        "AC results are complex; use bode(...) to plot magnitude and phase"))
    s.kind == :op && throw(ArgumentError(
        "an operating point has no time, sweep or frequency axis to plot against"))
    x = ustrip.(s.x)
    groups = filter(g -> !isempty(g[2]),
                    [("Voltage", findall(s.voltage)), ("Current", findall(.!s.voltage))])
    if length(groups) == 2
        layout := (2, 1)
        link := :x
    end
    for (panel, (quantity, idx)) in enumerate(groups)
        u = unit(first(autoscale(reduce(vcat, s.data[idx]))))   # one unit per panel
        for i in idx
            RecipesBase.@series begin
                subplot := panel
                label --> s.labels[i]
                xguide --> s.xlabel
                yguide --> "$quantity [$u]"
                x, ustrip.(u, s.data[i])
            end
        end
    end
end


#========================== bode ==========================#

# Magnitude (dB) and phase (degrees) for a Bode plot
struct BodeData
    f::Vector{Float64}
    labels::Vector{String}
    dB::Vector{Vector{Float64}}
    phase::Vector{Vector{Float64}}
end

function BodeData(nets...)
    require_analysis((:ac,), "bode")
    vecs = find_vecs(nets...)
    BodeData(ac_freq(), signal_label.(vecs), [dB20.(m) for m in magnitudes(vecs)], phases(vecs...))
end

"""
   bode(names...; kwargs...)

Bode plot (magnitude in dB and phase in degrees against frequency) of node
voltages and source currents from the latest AC analysis. Names are nodes or
voltage sources, as for [`signals`](@ref). Keyword arguments are passed to
the plotting package. Needs a plotting package, e.g. `using Plots`.

# Example

```julia-repl
julia> simulate(:ac; start=10u"Hz", stop=1u"MHz", steps=10)

julia> bode("out", "V1")
```
"""
bode(nets...; kwargs...) = plot_recipe(BodeData(nets...); kwargs...)
export bode

RecipesBase.@recipe function f(b::BodeData)
    layout := (2, 1)
    link := :x
    xscale --> :log10
    for i in eachindex(b.labels)
        RecipesBase.@series begin
            subplot := 1
            label --> b.labels[i]
            yguide --> "Magnitude [dB]"
            b.f, b.dB[i]
        end
        RecipesBase.@series begin
            subplot := 2
            label --> b.labels[i]
            yguide --> "Phase [°]"
            xguide --> "Frequency [Hz]"
            b.f, b.phase[i]
        end
    end
end


#========================== spectrum ==========================#

"""
   plot(𝒮::Spectrum; nh=10)

Plot the magnitude spectrum in dB on a linear frequency axis, with vertical
lines at the fundamental and harmonics. `nh` sets how many harmonics are
shown. Needs a plotting package, e.g. `using Plots`.
"""
RecipesBase.@recipe function f(S::Spectrum; nh=10)
    f0 = ustrip(u"Hz", S.fundamental)
    xguide --> "Frequency [Hz]"
    yguide --> "Magnitude [dB]"
    legend --> false
    xlims --> (0.5*f0, nh*f0)
    RecipesBase.@series begin
        ustrip.(u"Hz", S.f), ustrip.(S.db)
    end
    RecipesBase.@series begin
        seriestype := :vline
        linestyle --> :dot
        f0 .* collect(1:nh)
    end
end
