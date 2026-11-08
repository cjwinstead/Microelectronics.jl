import Base.getindex
import Base.convert

mutable struct Include
    filename::String
end

mutable struct Model
    name::String
    definition::String
end

struct Point
    time::Number
    value::Number
end
Point(t::Tuple) = Point(t[1],t[2])


mutable struct Parameter
    name::String
    value::Union{Number,String,Symbol}
end

mutable struct Waveform
    wave::Symbol
    parameters::Union{Vector{Point},OrderedDict{String,Any}}
end

struct Spectrum
    fundamental::Quantity
    f::Vector{Quantity}
    mag::Vector{Quantity}
    phase::Vector{Quantity}
    db::Vector{}  
    harmonics::Vector{Tuple{Quantity,Quantity}}
    thd::Float64
end

abstract type Element end
abstract type DependentSource <: Element end

"""
   SpiceLine(text)

A line (or block) of raw SPICE text. Netlists wrap any String they are
given in a SpiceLine, so text from the older string-returning functions
can be mixed freely with element objects.
"""
struct SpiceLine <: Element
    text::String
    SpiceLine(text::AbstractString) = new(rstrip(text,['\n','\r']))
end

@kwdef struct CCCS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::String
    gain::Union{Number,Quantity,String,Symbol}
end

@kwdef struct VCCS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::Vector{String}
    gain::Union{Number,Quantity,String,Symbol}
end

@kwdef struct CCVS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::String
    gain::Union{Number,Quantity,String,Symbol}
end

@kwdef struct VCVS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::Vector{String}
    gain::Union{Number,Quantity,String,Symbol}
end

mutable struct Source <: Element
    name::String
    species::String
    prefix::String
    nodes::Vector{String}
    waveforms::Vector{Waveform}
end


mutable struct Component <: Element
    name::String
    species::String
    prefix::String
    nodes::Vector{String}
    value::Union{Number,String,Symbol,Nothing}
    model::Union{String,Nothing}
    parameters::Vector{Parameter}
end




"""
   Subcircuit(; name, terminals, parameters=[], components=[])

A subcircuit definition (`.subckt name terminals ... .ends`), to list among
a `Netlist`'s `models` and use with [`Subckt`](@ref). Terminals are node
names (strings, symbols or integers). `parameters` are defaults that each
instance may override, in any of the forms [`parameter_list`](@ref) accepts.
`components` are taken in the same forms as a `Netlist`'s.
"""
struct Subcircuit
    name::String
    terminals::Vector{String}
    parameters::Vector{Parameter}
    components::Vector{Element}
    Subcircuit(name, terminals, parameters, components) =
        new(string(name), node_names(terminals isa Union{AbstractVector,Tuple} ? terminals : [terminals]),
            parameter_list(parameters), netlist_items(components))
end
Subcircuit(; name, terminals, parameters=Parameter[], components=Element[]) =
    Subcircuit(name, terminals, parameters, components)
    


struct Netlist 
    title::String
    models::Vector{Union{Model,Subcircuit,SpiceLine}}
    includes::Vector{Include}
    parameters::Vector{Union{Parameter,SpiceLine}}
    sources::Vector{Element}
    components::Vector{Element}
    globals::Vector{String}
end

#=
Global nets (.global): nodes such as vdd that are shared by the whole
circuit, including inside subcircuit definitions, without being passed in
as subcircuit terminals. Ground (node 0) is always global.
=#
function global_names(g)
    names = g isa Union{AbstractString,Symbol,Integer} ? [g] : collect(something(g, String[]))
    out = String[]
    for n in names
        n isa Quantity && throw(ArgumentError("a global net name can't be a quantity ($n)"))
        s = string(n)
        (s == "0" || s in out) || push!(out, s)
    end
    return out
end

# ".global vdd vss", or nothing when there are no global nets
global_line(globals) = isempty(globals) ? nothing : ".global " * join(globals, " ")


#=
function printsubckt(io::IO,n::Netlist)
    for field in [:parameters,:sources,:components]
        v = getfield(n,field)
        for x in v
            println(io,x)
        end        
    end
end
=#



export Subcircuit,Element,CCCS,VCVS,VCCS,CCVS,SpiceLine

#=
Netlist contents can be given as objects, Strings (from the string API),
dictionaries (from @table), or nested vectors of these. netlist_items
flattens all of that into a list of objects.
=#
netlist_items(x) = Any[x]
netlist_items(::Nothing) = Any[]
netlist_items(x::AbstractString) = isempty(strip(x)) ? Any[] : Any[SpiceLine(x)]
netlist_items(x::AbstractVector) = reduce(vcat, map(netlist_items,x); init=Any[])
netlist_items(x::Tuple) = netlist_items(collect(x))

# A netlist's parameters: .param text, or parameters in any form parameter_list takes
netlist_parameters(x::AbstractString) = netlist_items(x)
netlist_parameters(x::AbstractVector) = reduce(vcat, map(netlist_parameters, x); init=Any[])
netlist_parameters(x::Tuple) = is_name_value(x) ? Any[parameter_items(x)...] :
                               reduce(vcat, map(netlist_parameters, x); init=Any[])
netlist_parameters(x) = Any[parameter_items(x)...]

"""
   Netlist(; title, models, includes, parameters, sources, components, globals)

A circuit. `globals` names nets shared by the whole circuit, including
inside subcircuit definitions, e.g. `globals=["vdd"]` writes `.global vdd`.
"""
function Netlist(;title="circuit",models=[],includes=[Include(model_library())],
                 parameters=[],sources=[],components=[],globals=String[])
    includes = [x isa Include ? x : Include(string(x))
                for x in (includes isa AbstractVector ? includes : [includes])]
    params = netlist_parameters(parameters)
    unique_parameters(Parameter[p for p in params if p isa Parameter])
    models, components = netlist_items(models), netlist_items(components)
    check_instance_parameters(models, components)
    Netlist(string(title), models, includes, params,
            netlist_items(sources), components, global_names(globals))
end

# netlists made without global nets
Netlist(title,models,includes,parameters,sources,components) = Netlist(title,models,includes,parameters,sources,components,String[])
        
load_netlist(n::Netlist) = load_netlist(string(n))
export load_netlist

Parameter(t::Tuple) = Parameter(string(t[1]),t[2])
Parameter(p::Pair) = Parameter(string(p.first),p.second)
Parameter(v::Vector) = [x isa Parameter ? x : Parameter(x) for x in v]
Parameter(d::AbstractDict) = [Parameter(string(k),v) for (k,v) in d]

#=
Parameter lists. Netlists, subcircuits, subcircuit instances and other
elements all take their parameters in any of these forms, alone or in a
vector or tuple of them (nested collections are flattened):

    Parameter("R", 1u"kΩ")     "R" => 1u"kΩ"      ("R", 1u"kΩ")
    (R=1u"kΩ", C=1u"nF")        @table R C         nothing

SPICE names are not case sensitive, so R and r name the same parameter, and
giving one twice is an error.
=#
Parameter(name::Symbol, value) = Parameter(string(name), value)

# ("R", 1u"kΩ") is one parameter; other tuples are collections of them
is_name_value(t::Tuple) = length(t) == 2 && t[1] isa Union{AbstractString,Symbol} &&
                          t[2] isa Union{Number,AbstractString,Symbol}

const PARAMETER_FORMS = """give parameters as Parameter("R", 1u"kΩ"), "R" => 1u"kΩ", """ *
                        """("R", 1u"kΩ"), (R=1u"kΩ", C=1u"nF") or @table R C, or a vector of these"""

parameter_items(::Nothing) = Parameter[]
parameter_items(p::Parameter) = Parameter[p]
parameter_items(p::Pair) = Parameter[Parameter(string(p.first), p.second)]
parameter_items(d::AbstractDict) = Parameter[Parameter(string(k), v) for (k, v) in d]
parameter_items(n::NamedTuple) = Parameter[Parameter(string(k), v) for (k, v) in pairs(n)]
parameter_items(v::AbstractVector) = reduce(vcat, map(parameter_items, v); init=Parameter[])
parameter_items(t::Tuple) = is_name_value(t) ? Parameter[Parameter(string(t[1]), t[2])] :
                            reduce(vcat, map(parameter_items, t); init=Parameter[])
parameter_items(x::AbstractString) = throw(ArgumentError(
    "the text $(repr(String(x))) can't be used as a parameter here; " * PARAMETER_FORMS))
parameter_items(x) = throw(ArgumentError("can't make a parameter from $(repr(x)); " * PARAMETER_FORMS))

# Error if two parameters have the same (case-insensitive) name
function unique_parameters(ps::AbstractVector{Parameter})
    seen = Dict{String,String}()
    for p in ps
        k = lowercase(p.name)
        if haskey(seen, k)
            also = seen[k] == p.name ? "" : " (as $(seen[k]) and $(p.name); SPICE names are not case sensitive)"
            throw(ArgumentError("parameter $(p.name) is given twice$also"))
        end
        seen[k] = p.name
    end
    return ps
end

"""
   parameter_list(x) -> Vector{Parameter}

The parameters in `x`, which can be a `Parameter`, a `name => value` pair, a
`(name, value)` tuple, a named tuple `(R=1u"kΩ", C=1u"nF")`, a table from
[`@table`](@ref), `nothing`, or a vector or tuple of these. Names must be
unique, ignoring case. Used by `Netlist`, `Subcircuit` and the element
constructors, so they all accept the same forms.
"""
parameter_list(x) = unique_parameters(parameter_items(x))

#=
Subcircuit instances (X...) may only set parameters that their subcircuit
declares: ngspice silently ignores any others, so a misspelt name would go
unnoticed. Checked for subcircuits defined in the same netlist.
=#
function check_instance_parameters(models, components)
    defs = Dict(lowercase(m.name) => m for m in models if m isa Subcircuit)
    for c in Iterators.flatten((components, (x for s in values(defs) for x in s.components)))
        (c isa Component && uppercase(c.prefix) == "X" && !isnothing(c.model)) || continue
        sub = get(defs, lowercase(c.model), nothing)
        isnothing(sub) && continue
        declared = Set(lowercase(p.name) for p in sub.parameters)
        for p in c.parameters
            lowercase(p.name) in declared && continue
            has = isempty(sub.parameters) ? "has no parameters" :
                  "only has " * join((q.name for q in sub.parameters), ", ")
            throw(ArgumentError("$(c.name) sets parameter $(p.name), but subcircuit $(sub.name) $has"))
        end
    end
end
export parameter_list


#=
Node names may be given as Integers, Strings or Symbols. A Quantity in a
node position is almost always an argument-order mistake, such as
vdc(1,0,5u"V") where vdc(name,nplus,nminus,value) was meant.
=#
function node_name(x)
    x isa Quantity && throw(ArgumentError(
        "a node name can't be a quantity ($x). Check the argument order: " *
        "most elements take (name, nplus, nminus, value)."))
    string(x)
end
node_names(v) = [node_name(x) for x in v]

# Prepend the SPICE prefix letter `p` unless `name` already starts with it.
with_prefix(p,name) = (n = string(name); uppercase(first(n,1)) == uppercase(p) ? n : p*n)

# Use the given name, or generate the next one (R1, R2, ...) if none is given.
element_name(prefix,name) = (isnothing(name) || name == "") ? nextname(prefix) : string(name)

Base.convert(::Type{Vector{Parameter}},d::AbstractDict) = Parameter(d)


function fixname!(c::Component)
    regx = Regex("^$(c.prefix)\\w+","i")
    if isnothing(match(regx,c.name))
        c.name=string(c.prefix,c.name)
    end
    c
end

function Component(;name=nothing,species="",prefix="",nodes=[],model=nothing,value=nothing,parameters=Parameter[])
    params = parameter_list(parameters)
    fixname!(Component(element_name(prefix,name),species,prefix,node_names(nodes),value,
                       isnothing(model) ? nothing : string(model),params))
end

Resistor(name,nplus,nminus,value) = Component(;name,nodes=(nplus,nminus),value,species="resistor",prefix="R")
Resistor(;name=nothing,nplus,nminus,value) = Resistor(name,nplus,nminus,value)
Capacitor(name,nplus,nminus,value) = Component(;name,nodes=(nplus,nminus),value,species="capacitor",prefix="C")
Capacitor(;name=nothing,nplus,nminus,value) = Capacitor(name,nplus,nminus,value)
Inductor(name,nplus,nminus,value) = Component(;name,nodes=(nplus,nminus),value,species="inductor",prefix="L")
Inductor(;name=nothing,nplus,nminus,value) = Inductor(name,nplus,nminus,value)
Diode(name,nplus,nminus,model) = Component(;name,nodes=(nplus,nminus),model,species="diode",prefix="D")
Diode(;name=nothing,nplus,nminus,model) = Diode(name,nplus,nminus,model)
Subckt(name,nodes,model::AbstractString,parameters=Vector{Parameter}())=Component(;name,prefix="X",nodes,model,parameters)
Subckt(;name=nothing,nodes,model::AbstractString,parameters=Vector{Parameter}())=Subckt(name,nodes,model,parameters)
Instance(args...;kwargs...) = Subckt(args...;kwargs...)

Opamp(name,nplus,nminus,out,model,parameters=Vector{Parameter}())=Subckt(name,(nplus,nminus,out),model,parameters)
Opamp(;name,nplus,nminus,out,model,parameters=Vector{Parameter}())=Opamp(name,nplus,nminus,out,model,parameters)

Waveform(;wave=:dc,parameters=OrderedDict{String,Any}())=Waveform(wave,parameters)
Waveform(s::Symbol,args...;kwargs...) = Waveform(Val(s),args...;kwargs...)
Waveform(::Val{:dc},value=0;kwargs...) = Waveform(:dc,OrderedDict{String,Any}("value"=>value))
Waveform(::Val{:ac},value=1;kwargs...) = Waveform(:ac,OrderedDict{String,Any}("value"=>value))
Waveform(::Val{:sin},offset,amplitude,frequency,phase=SIN_DEFAULTS.phase,args...;kwargs...) =
    Waveform(:sin,OrderedDict{String,Any}("offset"=>offset,"amplitude"=>amplitude,"frequency"=>frequency,"phase"=>phase))
Waveform(::Val{:sin};offset=SIN_DEFAULTS.offset,amplitude=SIN_DEFAULTS.amplitude,
         frequency=SIN_DEFAULTS.frequency,phase=SIN_DEFAULTS.phase,kwargs...) =
    Waveform(:sin,offset,amplitude,frequency,phase)
Waveform(::Val{:pwl},points::AbstractVector;kwargs...) = Waveform(:pwl,Point[p isa Point ? p : Point(p) for p in points])
Waveform(::Val{:pulse},low,high,delay,risetime,falltime,width,period,pulses="";kwargs...) =
    Waveform(:pulse;low,high,delay,risetime,falltime,width,period,pulses)
Waveform(::Val{:pulse};kwargs...) =
    Waveform(:pulse,OrderedDict{String,Any}(string(k)=>v for (k,v) in pairs(merge(PULSE_DEFAULTS,
             (k=>v for (k,v) in pairs(kwargs) if haskey(PULSE_DEFAULTS,k))))))
# Raw SPICE text for a source value, e.g. "DISTOF1 0.1"
Waveform(::Val{:raw},text;kwargs...) = Waveform(:raw,OrderedDict{String,Any}("text"=>string(text)))

function Source(;species="vsource",prefix="V",name=nothing,nplus,nminus,waveforms=Waveform[],args...)
    waveforms = Waveform[waveforms...]     # copy, so the caller's vector isn't modified
    if haskey(args,:dc)
        push!(waveforms,Waveform(:dc,args[:dc]))
    end
    if haskey(args,:ac) && args[:ac] != 0
        push!(waveforms,Waveform(:ac,args[:ac]))
    end
    if haskey(args,:pwl)
        push!(waveforms,Waveform(:pwl,args[:pwl]))
    end
    if haskey(args,:pulse)
        push!(waveforms,Waveform(:pulse,args[:pulse]...))
    end
    name = with_prefix(prefix,element_name(prefix,name))
    Source(name,species,prefix,node_names((nplus,nminus)),waveforms)
end

for U in ("V","I")
    u = lowercase(U)
    s="""
$(U)source(name,nplus,nminus;args...)      = Source(;species="$(u)source",prefix="$(U)",name,nplus,nminus,args...)
$(U)dc(name,nplus,nminus,value=0;args...)  = Source(;species="$(u)source",prefix="$(U)",name,nplus,nminus,waveforms=[Waveform(:dc,value)],args...)
$(U)ac(name,nplus,nminus,value=1;args...)  = Source(;species="$(u)source",prefix="$(U)",name,nplus,nminus,waveforms=[Waveform(:ac,value)],args...)
$(U)sin(name,nplus,nminus;args...)         = Source(;species="$(u)source",prefix="$(U)",name,nplus,nminus,waveforms=[Waveform(:sin;args...)],args...)
$(U)pwl(name,nplus,nminus,points;args...)  = Source(;species="$(u)source",prefix="$(U)",name,nplus,nminus,waveforms=[Waveform(:pwl,points)],args...)
$(U)pulse(name,nplus,nminus;args...)       = Source(;species="$(u)source",prefix="$(U)",name,nplus,nminus,waveforms=[Waveform(:pulse;args...)],args...)
"""
    eval.(Meta.parse.(eachsplit(s,"\n")))
    for w in ["source","dc","ac","sin","pwl","pulse"]
        eval(Meta.parse("export $(U)$(w)"))
    end
end


function Spectrum(node,fundamental::Quantity;N=20,D=50)
    spectrum = fft(node;frequency=fundamental,N,D)
    spectrum = distortion(spectrum)
    #println("completed fft and distortion analysis")
    f     = spectrum.f .* u"Hz"
    mag  = spectrum.mag .* u"V"
    #println("added units to frequency and magnitude vectors")
    db   = spectrum.db .* u"dB"
    #println("added units to db vector")
    phase = spectrum.phase .* u"rad"
    #println("added units to phase vector")
    thd   = spectrum.thd

    harmonics  = [ (h[1]*u"V",h[2]*u"rad") for h in spectrum.harmonics]
    #println("added units to harmonics vector")
    
    Spectrum(fundamental,
             f,mag,phase,db,
             harmonics,thd)
end
export Spectrum


function alter(s::Source;frequency=nothing,amplitude=nothing,offset=nothing,phase=nothing)
    i = findall(x->x.wave==:sin,s.waveforms)
    if length(i) == 1
        idx = i[1]
        p = s.waveforms[i[1]].parameters 
        isnothing(frequency) || (p["frequency"] = frequency)
        isnothing(amplitude) || (p["amplitude"] = amplitude)
        isnothing(offset)    || (p["offset"] = offset)
        isnothing(phase)     || (p["phase"] = phase)
    else
        println("warning: source must have exactly one sinusoidal waveform")
    end
    return nothing
end


export alter

function Base.print(io::IO,p::Point)
    print.(io,qstr(p.time)," ",qstr(p.value));
    return nothing
end

function Base.print(io::IO,p::Parameter)
    print(io,p.name,"=",qstr(p.value))
    return nothing
end

Base.print(io::IO,l::SpiceLine) = print(io,l.text)

function Base.print(io::IO,m::Model)
    d = strip(m.definition)
    print(io, startswith(d,".") ? d : ".model $(m.name) $d")
end

# Name and nodes in aligned columns, then the remaining fields:
#   R1    1     2     1000
function spice_fields(name,nodes,rest...)
    fields = [rpad(name,5); rpad.(nodes,5); [r for r in rest if !isempty(r)]]
    rstrip(join(fields," "))
end

function Base.print(io::IO,v::Vector{T} where T <: Element )
    println.(io,v)
    return nothing
end

Base.show(io::IO,::MIME"text/plain",v::Vector{T} where T <: Element) = print(io,v)

function Base.print(io::IO,v::Vector{Point})
    for p in v
        print(io,p," ")
    end
    return nothing
end

function Base.print(io::IO,i::Include)
    print(io,".include ",i.filename)
    return nothing
end

# All waveform text comes from the shared formatters (sin_string etc.)
function Base.print(io::IO,w::Waveform)
    p = w.parameters
    if w.wave == :dc
        print(io," DC ",qstr(p["value"]))
    elseif w.wave == :ac
        print(io," AC ",qstr(p["value"]))
    elseif w.wave == :sin
        print(io,sin_string(p["offset"],p["amplitude"],p["frequency"],p["phase"]))
    elseif w.wave == :pulse
        print(io,pulse_string(;(Symbol(k)=>v for (k,v) in p)...))
    elseif w.wave == :pwl
        print(io," ",pwl_string(p))
    elseif w.wave == :raw
        print(io," ",p["text"])
    end
    return nothing
end

function report(io::IO,w::Waveform)
    println(io,w.wave," waveform with parameters:")
    w.parameters isa AbstractDict ? report(io,w.parameters) : print(io,w.parameters)
    return nothing
end
report(w::Waveform) = report(stdout,w)
Base.show(io::IO,::MIME"text/plain",w::Waveform) = report(io,w)


function Base.print(io::IO,c::Component)
    if length(c.prefix)==1 && length(c.name)>0 && length(c.nodes)>0
        rest = String[]
        isnothing(c.value) || push!(rest,qstr(c.value))
        isnothing(c.model) || push!(rest,c.model)
        append!(rest,string.(c.parameters))
        print(io,spice_fields(with_prefix(c.prefix,c.name),c.nodes,rest...))
    else
        print(io,"* Empty or Invalid Component")
    end
end


function Base.print(io::IO,s::Subcircuit)
    print(io,"\n.subckt ",s.name," ")
    for t in s.terminals
        print(io,t," ")
    end
    if length(s.parameters)>0
        print(io,"\n+params: ")
        for p in s.parameters
            print(io,p," ")
        end
    end
    
    print(io,"\n")
    print(io,s.components)
    print(io,"\n.ends\n")
end



spice_prefix(::CCCS) = "F"
spice_prefix(::CCVS) = "H"
spice_prefix(::VCCS) = "G"
spice_prefix(::VCVS) = "E"
# The controlling current is sensed in a voltage source, so its name gets
# the "V" prefix the same way Vdc("sense",...) becomes Vsense.
control_nodes(c::Union{CCCS,CCVS}) = [with_prefix("V",c.control)]
control_nodes(c::Union{VCCS,VCVS}) = c.control

function Base.print(io::IO,c::DependentSource)
    print(io,spice_fields(with_prefix(spice_prefix(c),c.name),
                          [c.nplus,c.nminus,control_nodes(c)...],qstr(c.gain)))
end

function Base.print(io::IO,n::Netlist)
    println(io,"* ", n.title)
    isempty(n.globals) || println(io, global_line(n.globals))
    foreach(x->println(io,x), n.includes)
    foreach(x->println(io,x), n.models)
    for p in n.parameters
        println(io, p isa Parameter ? param_line(p.name,p.value) : p)
    end
    foreach(x->println(io,x), n.sources)
    foreach(x->println(io,x), n.components)
    println(io,".end")
end


# DC and AC values first, then transient waveforms, as SPICE users expect
const WAVEFORM_ORDER = Dict(:dc=>1, :ac=>2)

function Base.print(io::IO,s::Source)
    waves = sort(s.waveforms; by = w -> get(WAVEFORM_ORDER,w.wave,3))
    print(io,spice_fields(with_prefix(s.prefix,s.name),s.nodes,
                          (strip(sprint(print,w)) for w in waves)...))
end


function Base.show(io::IO,::MIME"text/plain",c::T where T <: Element)
    print(io,c)
end

function Base.show(io::IO,::MIME"text/plain",c::Include)
    println(io,c.filename)
end





function report(io::IO,s::Source)
    println(io,'-'^40)
    print(io,s.species," ",s.name,"   ")
    println(io,"nplus=",s.nodes[1]," nminus=",s.nodes[2])
    println(io,"\nWaveforms:")
    for i in eachindex(s.waveforms)
        println(io,i,": ",s.waveforms[i]," ")
    end
    println(io,'.'^40)
end
report(s::Source) = report(stdout,s)
Base.show(io::IO,::MIME"text/plain",s::Source) = report(io,s)


function report(io::IO,c::Component)
    print(io,c.species," ",c.name," nodes: ")
    for i in c.nodes print(io,i," "); end
    if !isnothing(c.value) print(io, "value: ",c.value); end
    if !isnothing(c.model) print(io, "model: ",c.model); end
    if length(c.parameters)>0 print(io," params: "); print.(io,c.parameters," "); end
    println(io,"")
    return nothing
end
report(c::Component) = report(stdout,c)

function report(io::IO,v::Vector{T} where T<:Element)
    report.(io,v)
    return nothing
end
report(v::Vector{T} where T<:Element) = report(stdout,v)

    
function report(io,n::Netlist)
    for field in (:title, :globals, :models, :includes, :parameters, :sources, :components)
        println(io,'-'^40)
        print(io,string(field))
        f = getfield(n,field)
        if typeof(f) <: AbstractArray
            if length(f) > 0
                println(io,":")            
                for x in eachindex(f)
                    println(io,x,": ",f[x])                    
                end
            else
                println(io,": none")
            end
        else
            print(io,": ")
            println(io,f)
        end
    end    
end
report(n::Netlist) = report(stdout,n)
Base.show(io::IO,::MIME"text/plain",n::Netlist) = report(io,n)

function report(io,n::Subcircuit)
    println(io,'-'^40)
    println(io,"   SUBCIRCUIT MODEL")
    for field in (:name, :terminals, :parameters, :components)
        println(io,'-'^40)
        print(io,string(field))
        f = getfield(n,field)
        if typeof(f) <: AbstractArray
            if length(f) > 0
                println(io,":")            
                for x in eachindex(f)
                    println(io,x,": ",f[x])                    
                end
            else
                println(io,": none")
            end
        else
            print(io,": ")
            println(io,f)
        end
    end    
end
report(n::Subcircuit) = report(stdout,n)
Base.show(io::IO,::MIME"text/plain",n::Subcircuit) = report(io,n)



export Component, Waveform, Source, Resistor, Capacitor, Netlist, Inductor, Diode, Parameter, Model, Include, Subckt, Instance, Opamp, Point

                                      
                                    


    
