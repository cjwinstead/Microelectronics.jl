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
   Subcircuit(; name, terminals, parameters=[], components)

A subcircuit definition (`.subckt name terminals ... .ends`), to list among
a `Netlist`'s `models` and use with [`Subckt`](@ref). `parameters` are
defaults that each instance may override, in any of the forms
[`parameter_list`](@ref) accepts.
"""
struct Subcircuit
    name::String
    terminals::Vector{String}
    parameters::Vector{Parameter}
    components::Vector{Element}
    Subcircuit(name, terminals, parameters, components) =
        new(string(name), [string(t) for t in (terminals isa Union{AbstractVector,Tuple} ? terminals : [terminals])],
            parameter_list(parameters), components)
end
Subcircuit(; name, terminals, parameters=Parameter[], components) =
    Subcircuit(name, terminals, parameters, components)
    


struct Netlist 
    title::String
    models::Vector{Union{Model,Subcircuit}}
    includes::Vector{Include}
    parameters::Vector{Parameter}
    sources::Vector{Source}
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



export Subcircuit,Element,CCCS,VCVS,VCCS,CCVS

"""
   Netlist(; title, models, includes, parameters, sources, components, globals)

A circuit. `parameters` become `.param` lines and can be given in any of
the forms [`parameter_list`](@ref) accepts, e.g. `parameters=@table R C` or
`parameters=(R=1u"kΩ", C=1u"nF")`. `globals` names nets shared by the whole circuit, including
inside subcircuit definitions, e.g. `globals=["vdd"]` writes `.global vdd`.
"""
function Netlist(;title="circuit",models=Vector{Model}(),includes=Vector{Include}([Include(realpath(dirname(pathof(@__MODULE__))*"/../model_library.sp"))]),parameters=Vector{Parameter}(),sources=Vector{Source}(),components=Vector{Component}(),globals=String[])
    check_instance_parameters(models, components)
    Netlist(title,models,includes,parameter_list(parameters),sources,components,global_names(globals))
end

# netlists made without global nets
Netlist(title,models,includes,parameters,sources,components) = Netlist(title,models,includes,parameters,sources,components,String[])
        
load_netlist(n::Netlist) = load_netlist(string(n))
export load_netlist

Parameter(t::Tuple) = Parameter(string(t[1]),t[2])
Parameter(v::Vector) = [Parameter(t) for t in v]
Parameter(d::AbstractDict) = [Parameter(string(k),v) for (k,v) in d]

Base.convert(::Type{Vector{Parameter}},d::AbstractDict) = Parameter(d)

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



function fixname!(c::Component)
    regx = Regex("^$(c.prefix)\\w+","i")
    if isnothing(match(regx,c.name))
        c.name=string(c.prefix,c.name)
    end
    c
end

Component(;name="",species="",prefix="",nodes=[],model=nothing,value=nothing,parameters=[]) = fixname!(Component(name,species,prefix,nodes,value,model,parameter_list(parameters)))

Resistor(name,nplus,nminus,value) = Component(;name,nodes=string.([nplus,nminus]),value,species="resistor",prefix="R")
Resistor(;name,nplus,nminus,value) = Resistor(name,nplus,nminus,value)
Capacitor(name,nplus,nminus,value) = Component(;name,nodes=string.([nplus,nminus]),value,species="capacitor",prefix="C")
Capacitor(;name,nplus,nminus,value) = Capacitor(name,nplus,nminus,value)
Inductor(name,nplus,nminus,value) = Component(;name,nodes=string.([nplus,nminus]),value,species="inductor",prefix="L")
Inductor(;name,nplus,nminus,value) = Inductor(name,nplus,nminus,value)
Diode(name,nplus,nminus,model) = Component(;name,nodes=string.([nplus,nminus]),model,species="diode",prefix="D")
Diode(;name,nplus,nminus,model) = Diode(name,nplus,nminus,model)
"""
   Subckt(name, nodes, model, parameters=[])
   Subckt(; name, nodes, model, parameters=[])

An instance (`X...`) of the subcircuit `model`, e.g. one defined with
[`Subcircuit`](@ref), connected to `nodes` in the order of its terminals.
`parameters` override the subcircuit's defaults, in any of the forms
[`parameter_list`](@ref) accepts:

```jldoctest
julia> Subckt("X1", [1, 2], "divider", (R=2u"kΩ",))
X1 1 2 divider R=2000
```
"""
Subckt(name,nodes::Vector,model::String,parameters=Vector{Parameter}())=Component(;name,prefix="X",nodes=string.(nodes),model,parameters)
Subckt(;name,nodes::Vector,model::String,parameters=Vector{Parameter}())=Subckt(name,nodes,model,parameters)
Instance(args...;kwargs...) = Subckt(args...;kwargs...)

Opamp(name,nplus,nminus,out,model,parameters=Vector{Parameter}())=Subckt(name,[nplus,nminus,out],model,parameters)
Opamp(;name,nplus,nminus,out,model,parameters=Vector{Parameter}())=Opamp(name,nplus,nminus,out,model,parameters)

Waveform(;wave=:dc,parameters=[])=Waveform(wave,parameters)
Waveform(s::Symbol,args...;kwargs...) = Waveform(Val(s),args...;kwargs...)
Waveform(::Val{:dc},value) = Waveform(wave=:dc,parameters=OrderedDict{String,Any}("value"=>value))
Waveform(::Val{:ac},value=1) = Waveform(wave=:ac,parameters=OrderedDict{String,Any}("value"=>value))
Waveform(::Val{:sin},offset,amplitude,frequency,phase,args...) = Waveform(wave=:sin,parameters=OrderedDict{String,Any}("offset"=>offset,"amplitude"=>amplitude,"frequency"=>frequency,"phase"=>phase))
Waveform(::Val{:sin};offset=0u"V",amplitude=5u"mV",frequency=1u"kHz",phase=0u"°",args...)=Waveform(:sin,offset,amplitude,frequency,phase)
Waveform(::Val{:pwl},points::AbstractVector;args...) = Waveform(wave=:pwl,parameters=Point[p isa Point ? p : Point(p) for p in points];args...)
Waveform(::Val{:pulse},low,high,delay,risetime,falltime,width,period,pulses;args...) = Waveform(wave=:pulse,parameters=OrderedDict{String,Any}("low"=>low,"high"=>high,"delay"=>delay,"risetime"=>risetime,"falltime"=>falltime,"width"=>width,"period"=>period,"pulses"=>pulses);args...)
Waveform(::Val{:pulse};high=5u"V",low=0u"V",risetime=1u"ns",falltime=1u"ns",width=499u"ns",period=1u"ms",delay=0,pulses=0,args...)=Waveform(:pulse,low,high,delay,risetime,falltime,width,period,pulses;args...)

function Source(;species="vsource",prefix="V",name,nplus,nminus,waveforms::Vector{Waveform}=Waveform[],args...)
    if :ac ∈ keys(args) && args[:ac]≠0
        push!(waveforms,Waveform(:ac,args[:ac]))
    end
    if :dc ∈ keys(args)
        push!(waveforms,Waveform(:dc,args[:dc]))
    end
    if :pwl ∈ keys(args)
        push!(waveforms,Waveform(:pwl,args[:pwl]))
    end
    if :pulse ∈ keys(args)
        push!(waveforms,Waveform(:pulse,args[:pulse]...))
    end

    if lowercase(name)[1] != lowercase(prefix)[1]
        name = string(prefix,name)
    end
    Source(name,species,prefix,string.([nplus,nminus]),waveforms)
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


function Spectrum(node::String,fundamental::Quantity;N=20,D=50)
    spectrum = fft(node;frequency=fundamental)
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


"""
   plot(𝒮::Spectrum; nh=10, kwargs...)

Plot the magnitude spectrum in dB. By default, the horizontal scale is
linear. Vertical lines are overlaid to indicate the fundamental and harmonic
frequencies. The `nh` parameter controls how many harmonics are shown.
Additional plot arguments are passed through to `Plots.plot` function. 
"""
function plot(𝒮::Spectrum; nh=10,kwargs...)
    f₀ = ustrip(𝒮.fundamental => u"Hz")
    Plots.plot(ustrip.(𝒮.f),[ustrip.(𝒮.db)];
        xlabel="Frequency [Hz]",
        ylabel="Magnitude [dB]",
        legend=:none,
        xlims=(f₀*0.5,f₀*nh),
        kwargs...
        )    
    vline!(ustrip(𝒮.fundamental=>u"Hz").*collect(1:nh))
end




function alter(s::Source;frequency=nothing,amplitude=nothing,offset=nothing,phase=nothing)
    i = findall(x->x.wave==:sin,s.waveforms)
    if length(i) == 1
        idx = i[1]
        p = s.waveforms[i[1]].parameters 
        if !isnothing(frequency)
            p["frequency"] = frequency
        elseif !isnothing(amplitude)
            p["amplitude"] = amplitude
        elseif !isnothing(offset)
            p["offset"] = offset
        elseif !isnothing(phase)
            p["phase"] = phase
        end
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
    print(io,p.name,"=",qstr(p.value)," ")
    return nothing
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

function Base.print(io::IO,m::Model)
    d = strip(m.definition)
    print(io, startswith(d,".") ? d : ".model $(m.name) $d")
end

function Base.print(io::IO,i::Include)
    print.(io,".include ",i.filename)
    return nothing
end

function Base.print(io::IO,w::Waveform)
    if w.wave == :dc
        print(io, " dc ")
    elseif w.wave == :sin
        print(io," sin (")
    elseif w.wave == :pwl
        print(io, " pwl (")
    elseif w.wave == :pulse
        print(io, " pulse (")
    elseif w.wave == :ac
        print(io, " ac ")
    end
    values = w.parameters isa AbstractVector ?                 # PWL points
             Iterators.flatten((p.time, p.value) for p in w.parameters) :
             (x[2] for x in w.parameters)
    for v in values
        print(io,qstr(v), " ")
    end
    if w.wave ∈ [:sin,:pwl,:pulse]
        print(io,")")
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
        regx = Regex("^$(c.prefix)\\w+","i")
        if !isnothing(match(regx,c.name))
            print(io,c.name," ")
        else
            print(io,c.prefix,c.name," ")
        end
        
        for n in c.nodes
            print(io,n," ")
        end
        
        if !isnothing(c.value)
            print(io,qstr(c.value)," ")
        end
        
        if !isnothing(c.model)
            print(io,c.model," ")
        end

        for p in c.parameters
            print(io,p.name,"=",qstr(p.value)," ")
        end
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



function Base.print(io::IO,c::DependentSource)
    if typeof(c) == CCCS
        print(io,dependent_source(:cccs;c.name,c.nplus,c.nminus,c.control,c.gain))
    elseif typeof(c) == VCVS
        print(io,dependent_source(:vcvs;c.name,c.nplus,c.nminus,c.control,c.gain))
    elseif typeof(c) == VCCS
        print(io,dependent_source(:vccs;c.name,c.nplus,c.nminus,c.control,c.gain))
    elseif typeof(c) == CCVS
        print(io,dependent_source(:ccvs;c.name,c.nplus,c.nminus,c.control,c.gain))
    end
end

function Base.print(io::IO,n::Netlist)
    println(io,"* ", n.title)
    isempty(n.globals) || println(io, global_line(n.globals))
    for field in [:models,:includes,:parameters,:sources,:components]
        v = getfield(n,field)
        for x in v
            println(io, x isa Parameter ? param_line(x.name,x.value) : x)
        end        
    end
    println(io,".end")
end


function Base.print(io::IO,s::Source)
    print(io,s.name,"   ")
    for n in s.nodes
        print(io,n," ")
    end
    for w in s.waveforms
        print(io,w)
    end

end


function Base.show(io::IO,::MIME"text/plain",c::T where T <: Element)
    print(io,c)
end

function Base.show(io::IO,::MIME"text/plain",c::Include)
    println(io,c.filename)
end




function report(io::IO,s::Source)
    println('-'^40)
    print(io,s.species," ",s.name,"   ")
    println(io,"nplus=",s.nodes[1]," nminus=",s.nodes[2])
    println(io,"\nWaveforms:")
    for i in eachindex(s.waveforms)
        println(io,i,": ",s.waveforms[i]," ")
    end
    println('.'^40)
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

                                      
                                    


    
