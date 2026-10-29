#=
Transistors

- NMOS, PMOS and MOSFET constructors, and the string-returning mosfet()
- the transistor quantities ngspice can report (drain current, gm, gds,
  threshold, ...), kept automatically for every MOSFET in the circuit
- nested DC sweeps, for families of characteristic curves

This file is shared by the main and dev branches, so it only uses functions
that exist on both: Component, Parameter, nextname, qstr, spice_name,
analysis_kind, simx and dc_sweep.
=#

#===================== Constructors =====================#

"MOSFET instance parameters that can be given as keywords."
const MOSFET_INSTANCE_PARAMETERS = ("W", "L", "M", "AD", "AS", "PD", "PS", "NRD", "NRS")

# A terminal is named by a number, String or Symbol. A quantity in a terminal
# position is an argument-order mistake.
function terminal_name(x)
    x isa Quantity && throw(ArgumentError(
        "a MOSFET terminal can't be a quantity ($x). The terminals come first: " *
        "(name, drain, gate, source[, body]); give sizes as keywords, e.g. W=20u\"μm\""))
    string(x)
end

function mosfet_parameters(parameters, kw)
    params = Parameter[p isa Parameter ? p :
                       p isa Pair ? Parameter(string(p.first), p.second) : Parameter(p)
                       for p in parameters]
    for (k, v) in pairs(kw)
        key = uppercase(string(k))
        key in MOSFET_INSTANCE_PARAMETERS || throw(ArgumentError(
            "unknown MOSFET parameter `$k`; use one of $(join(MOSFET_INSTANCE_PARAMETERS, ", "))"))
        isnothing(v) || push!(params, Parameter(key, v))
    end
    return params
end

function mosfet_component(species, name, drain, gate, source, body, model, parameters=Parameter[]; kw...)
    name = (isnothing(name) || name == "") ? nextname("M") : string(name)
    Component(; name, species, prefix="M",
              nodes=[terminal_name(t) for t in (drain, gate, source, body)],
              model=string(model), parameters=mosfet_parameters(parameters, kw))
end

"""
   NMOS(name, drain, gate, source, body=source; model="ald1105n", W, L, M, ...)
   NMOS(; name, drain, gate, source, body=source, model="ald1105n", W, L, M, ...)

An n-channel MOSFET. The body is tied to the source unless given, and the
model defaults to the ALD1105 n-channel device in the model library, whose
default size is W = 20 μm, L = 10 μm.

Instance parameters are keywords, with or without units: `W` and `L` (channel
size), `M` (number of devices in parallel), and `AD`, `AS`, `PD`, `PS`,
`NRD`, `NRS`. Without a name, the next free name (M1, M2, ...) is used.

# Examples

```julia-repl
julia> NMOS("M1", "d", "g", 0)                     # body tied to the source
M1    d     g     0     0     ald1105n

julia> NMOS("M2", "d", "g", "s", 0; model="CD4007N", W=60u"μm", L=10u"μm")
M2    d     g     s     0     CD4007N W=6e-05 L=1e-05
```
"""
NMOS(name, drain, gate, source, body=source; model="ald1105n", parameters=Parameter[], kw...) =
    mosfet_component("nmos", name, drain, gate, source, body, model, parameters; kw...)
NMOS(; name=nothing, drain, gate, source, body=source, model="ald1105n", parameters=Parameter[], kw...) =
    NMOS(name, drain, gate, source, body; model, parameters, kw...)

"""
   PMOS(name, drain, gate, source, body=source; model="ald1105p", W, L, M, ...)
   PMOS(; name, drain, gate, source, body=source, model="ald1105p", W, L, M, ...)

A p-channel MOSFET; see [`NMOS`](@ref). The body is tied to the source unless
given (a PMOS body belongs at the most positive voltage, usually VDD), and
the model defaults to the ALD1105 p-channel device.

# Example

```julia-repl
julia> PMOS("M3", "out", "in", "vdd")
M3    out   in    vdd   vdd   ald1105p
```
"""
PMOS(name, drain, gate, source, body=source; model="ald1105p", parameters=Parameter[], kw...) =
    mosfet_component("pmos", name, drain, gate, source, body, model, parameters; kw...)
PMOS(; name=nothing, drain, gate, source, body=source, model="ald1105p", parameters=Parameter[], kw...) =
    PMOS(name, drain, gate, source, body; model, parameters, kw...)

"""
   MOSFET(name, drain, gate, source, body, model, parameters=[]; W, L, M, ...)
   MOSFET(; name, drain, gate, source, body, model, parameters=[], W, L, M, ...)

A MOSFET of any polarity: the model decides. All four terminals are required;
[`NMOS`](@ref) and [`PMOS`](@ref) tie the body to the source by default.
Instance parameters can be keywords or a vector of `Parameter`s.
"""
MOSFET(name, drain, gate, source, body, model, parameters=Parameter[]; kw...) =
    mosfet_component("mosfet", name, drain, gate, source, body, model, parameters; kw...)

function MOSFET(; name=nothing, drain, gate, source, body=nothing, substrate=nothing,
                model, parameters=Parameter[], kw...)
    b = isnothing(body) ? substrate : body
    isnothing(b) && throw(ArgumentError(
        "MOSFET needs a body terminal (body=...); NMOS and PMOS tie it to the source by default"))
    MOSFET(name, drain, gate, source, b, model, parameters; kw...)
end

"""
   mosfet(name, drain, gate, source, body, model="ald1105n"; W, L, M, ...)

SPICE text for a MOSFET: the same as `string(MOSFET(...))`. Sizes and other
instance parameters are only written when given, so the model's own defaults
(e.g. W = 30 μm, L = 10 μm for the CD4007N) apply otherwise.
"""
mosfet(name, drain, gate, source, body, model="ald1105n"; kw...) =
    string(MOSFET(name, drain, gate, source, body, model; kw...))

export NMOS, PMOS, MOSFET, mosfet

"""
   element[quantity]

The ngspice name of a device quantity, e.g. `M1["gm"]` is `"@m1[gm]"`.
"""
Base.getindex(c::Component, quantity::AbstractString) = "@$(lowercase(c.name))[$(lowercase(quantity))]"


#===================== Transistor quantities =====================#

#=
ngspice only keeps node voltages and source currents unless asked for more.
When a netlist is loaded, its top-level MOSFETs are recorded, and before each
analysis ngspice is asked to keep these quantities for all of them.
=#

"Top-level MOSFETs in the loaded circuit: lowercase name => (drain, gate, source, body)."
const LOADED_MOSFETS = OrderedDict{String,NTuple{4,String}}()

"Quantities kept for every MOSFET (ngspice names)."
const MOSFET_QUANTITIES = ("id", "gm", "gds", "gmbs", "vgs", "vds", "vbs", "vdsat", "von")

"Record the top-level MOSFETs of a netlist (called by load_netlist)."
function register_mosfets(netlist::AbstractString)
    empty!(LOADED_MOSFETS)
    depth = 0
    for (i, line) in enumerate(eachsplit(netlist, '\n'))
        i == 1 && continue                                # the title line
        t = split(lowercase(strip(line)))
        isempty(t) && continue
        if t[1] == ".subckt"
            depth += 1
        elseif t[1] == ".ends"
            depth = max(depth - 1, 0)
        elseif depth == 0 && startswith(t[1], "m") && length(t) >= 6
            LOADED_MOSFETS[t[1]] = (t[2], t[3], t[4], t[5])
        end
    end
    return nothing
end

"Ask ngspice to keep the MOSFET quantities in the next analysis (called by simulate)."
function save_mosfet_quantities()
    isempty(LOADED_MOSFETS) && return nothing
    NgHerb.cmd("save all " * join(("@$m[$q]" for m in keys(LOADED_MOSFETS) for q in MOSFET_QUANTITIES), " "))
    return nothing
end

# Node voltages of the latest analysis (ground is "0")
node_volts(n, len) = n == "0" ? zeros(len) : NgHerb.getrealvec(n)

#=
For a PMOS, ngspice reports id, vgs, vds and vbs with their signs reversed
(as if it were an NMOS), but von and vdsat with their true signs. The
polarity is found by comparing ngspice's vgs, vds or vbs with the actual
node voltages: +1 for NMOS, -1 for PMOS.
=#
function mosfet_polarity(m)
    d, g, s, b = LOADED_MOSFETS[m]
    for (q, (n1, n2)) in (("vgs", (g, s)), ("vds", (d, s)), ("vbs", (b, s)))
        reported = NgHerb.getrealvec("@$m[$q]")
        actual = node_volts(n1, length(reported)) .- node_volts(n2, length(reported))
        i = findfirst(x -> abs(x) > 1e-6, actual)
        isnothing(i) || return sign(reported[i]) == sign(actual[i]) ? 1 : -1
    end
    return 1        # all terminals at one voltage: no current flows either way
end

function loaded_mosfet(name)
    m = spice_name(name)
    haskey(LOADED_MOSFETS, m) && return m
    known = isempty(LOADED_MOSFETS) ? "there are none" : "they are " * join(keys(LOADED_MOSFETS), ", ")
    throw(ArgumentError("there is no MOSFET named \"$name\" in the loaded circuit ($known)"))
end

"""
   device_values(name)

Operating values of MOSFET `name` in the latest operating-point, DC or
transient analysis, with units:

- `id`: current into the drain
- `vgs`, `vds`, `vbs`: terminal voltages
- `vth`: threshold voltage, including the body effect
- `vdsat`: drain-source saturation voltage (`vgs - vth` for level-1 models)
- `gm`, `gds`, `gmbs`: transconductance, output conductance, body transconductance
- `region`: `:cutoff`, `:triode` or `:saturation`

Voltages and currents follow the circuit's sign convention, so for a PMOS
`vgs`, `vds`, `vth` and `id` are normally negative. After an operating-point
analysis each value is a single number; after a DC sweep or transient
analysis each is a vector.

# Example

```julia-repl
julia> build_netlist(; sources=[Vdc("VDD","d",0,5u"V"), Vdc("VG","g",0,3u"V")],
                       components=[NMOS("M1","d","g",0)]);

julia> simulate(:op); device_values("M1")
(id = 0.001363 A, vgs = 3.0 V, vds = 5.0 V, vbs = 0.0 V, vth = 0.7 V, vdsat = 2.3 V,
 gm = 0.001185 S, gds = 3.45e-5 S, gmbs = 0.000... S, region = :saturation)
```
"""
function device_values(name)
    m = loaded_mosfet(name)
    k = analysis_kind()
    k in (:op, :dc, :tran) || throw(ArgumentError(
        "device_values needs an :op, :dc or :tran analysis, but the latest analysis is :$k"))
    get(q) = NgHerb.getrealvec("@$m[$q]")
    t = mosfet_polarity(m)
    vgs, vds, vbs, id = t .* get("vgs"), t .* get("vds"), t .* get("vbs"), t .* get("id")
    vth, vdsat = get("von"), get("vdsat")
    region = [t*(g - v) <= 0 ? :cutoff : t*d >= t*s ? :saturation : :triode
              for (g, v, d, s) in zip(vgs, vth, vds, vdsat)]
    pick(x) = k == :op ? x[1] : x
    return (id = pick(id .* u"A"), vgs = pick(vgs .* u"V"), vds = pick(vds .* u"V"),
            vbs = pick(vbs .* u"V"), vth = pick(vth .* u"V"), vdsat = pick(vdsat .* u"V"),
            gm = pick(get("gm") .* u"S"), gds = pick(get("gds") .* u"S"),
            gmbs = pick(get("gmbs") .* u"S"), region = pick(region))
end
export device_values

# Device current vector name for a MOSFET, or nothing (used by find_vec)
mosfet_current_vector(name) = haskey(LOADED_MOSFETS, name) ? "@$name[id]" : nothing

"""
   signal_data(vector)

The type ("voltage" or "current") and values of an ngspice result vector. A
MOSFET drain current (`"@m1[id]"`) is returned as the current into the
drain, with the circuit's sign convention.
"""
function signal_data(vec)
    m = match(r"^@(.+)\[id\]$"i, vec)
    if !isnothing(m) && haskey(LOADED_MOSFETS, lowercase(m[1]))
        return "current", mosfet_polarity(lowercase(m[1])) .* NgHerb.getrealvec(vec)
    end
    _, vtype, data = NgHerb.getvec(vec)
    return vtype, data
end

# ngspice vector name -> label: "out" -> "V(out)", "V(1)" -> "V(1)",
# "v1#branch" -> "I(v1)", "@m1[id]" -> "ID(m1)"
function signal_label(vec)
    endswith(vec, "#branch") && return "I($(vec[1:end-7]))"
    m = match(r"^@(.+)\[id\]$"i, vec)
    isnothing(m) || return "ID($(m[1]))"
    m = match(r"^v\((.*)\)$"i, vec)
    return isnothing(m) ? "V($vec)" : "V($(m[1]))"
end


#===================== Nested DC sweeps =====================#

"The outer source of the latest nested DC sweep: (device, start, step), or nothing."
const OUTER_SWEEP = Ref{Any}(nothing)

# sweep2 = ("VGS", 1, 3, 0.5) or (device="VGS", start=1, stop=3, step=0.5)
function sweep_spec(s)
    s isa NamedTuple ? (string(s.device), s.start, s.stop, s.step) :
    length(s) == 4   ? (string(s[1]), s[2], s[3], s[4]) :
    throw(ArgumentError("sweep2 is (device, start, stop, step), e.g. (\"VGS\", 1u\"V\", 3u\"V\", 0.5u\"V\")"))
end

"The second half of a nested `dc` command, recording the outer sweep for plotting."
function outer_sweep_command(sweep2)
    if isnothing(sweep2)
        OUTER_SWEEP[] = nothing
        return ""
    end
    device, start, stop, step = sweep_spec(sweep2)
    OUTER_SWEEP[] = (device, start, step)
    return " $(spice_name(device)) $(qstr(start)) $(qstr(stop)) $(qstr(step))"
end

# Label for one outer-sweep value: "VGS = 1.5 V"
function outer_label(device, value)
    if value isa Quantity
        v = scale_quantity(value)
        return "$device = $(@sprintf("%g", ustrip(v))) $(unit(v))"
    end
    u = Dict('v' => " V", 'i' => " A", 'r' => " Ω")
    return "$device = $(value)$(get(u, lowercase(first(device)), ""))"
end

"""
   sweep_curves(n)

How the `n` points of the latest analysis divide into curves. After a nested
DC sweep (`simulate(:dc; ..., sweep2=...)`) there is one `(indices, label)`
pair per value of the outer source, e.g. `(1:51, "VGS = 1 V")`; otherwise a
single pair `(1:n, "")`.
"""
function sweep_curves(n::Integer)
    outer = OUTER_SWEEP[]
    (analysis_kind() != :dc || isnothing(outer)) && return [(1:n, "")]
    x = ustrip.(dc_sweep())
    n == length(x) || return [(1:n, "")]
    # the inner sweep restarts where its direction reverses
    dir = sign(x[2] - x[1])
    resets = [i for i in 2:n if sign(x[i] - x[i-1]) != dir]
    starts = [1; resets]
    stops = [resets .- 1; n]
    device, start, step = outer
    return [(a:b, outer_label(device, start + (j - 1)*step)) for (j, (a, b)) in enumerate(zip(starts, stops))]
end
export sweep_curves

"""
   curve_series(x, ys, labels)

Split each signal in `ys` into one series per curve of the latest analysis
(see [`sweep_curves`](@ref)), for plotting. Returns vectors of x data,
y data and labels.
"""
function curve_series(x, ys, labels)
    curves = sweep_curves(length(x))
    xs, yss, ls = AbstractVector[], AbstractVector[], String[]
    for (y, label) in zip(ys, labels), (idx, curve) in curves
        push!(xs, x[idx]); push!(yss, y[idx])
        push!(ls, isempty(curve) ? label : "$label, $curve")
    end
    return xs, yss, ls
end
