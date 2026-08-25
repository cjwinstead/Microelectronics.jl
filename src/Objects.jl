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


mutable struct Parameter
    name::String
    value::Number
end

mutable struct Waveform
    wave::Symbol
    parameters::Union{Vector{Point},OrderedDict{String,Any}}
end


abstract type Element end
abstract type DependentSource <: Element end

@kwdef struct CCCS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::String
    gain::Float64
end

@kwdef struct VCCS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::Vector{String}
    gain::Float64
end

@kwdef struct CCVS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::String
    gain::Float64
end

@kwdef struct VCVS <: DependentSource
    name::String
    nplus::String
    nminus::String
    control::Vector{String}
    gain::Float64
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




@kwdef struct Subcircuit
    name::String
    terminals::Vector{String}
    parameters::Vector{Parameter}=[]
    components::Vector{Element}
end
    


struct Netlist 
    title::String
    models::Vector{Union{Model,Subcircuit}}
    includes::Vector{Include}
    parameters::Vector{Parameter}
    sources::Vector{Source}
    components::Vector{Element}
end


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

Netlist(;title="cicuit",models=Vector{Model}(),includes=Vector{Include}([Include(realpath(dirname(pathof(@__MODULE__))*"/../model_library.sp"))]),parameters=Vector{Parameter}(),sources=Vector{Source}(),components=Vector{Component}())=Netlist(title,models,includes,parameters,sources,components)
        
load_netlist(n::Netlist) = load_netlist(string(n))
export load_netlist

Parameter(t::Tuple) = Parameter(string(t[1]),t[2])
Parameter(v::Vector) = [Parameter(t) for t in v]
Parameter(d::OrderedDict{String,T}) where T<:Number = [Parameter(k,d[k]) for k in keys(d)]

Base.convert(::Type{Vector{Parameter}},d::OrderedDict) = Parameter(d)


function fixname!(c::Component)
    regx = Regex("^$(c.prefix)\\w+","i")
    if isnothing(match(regx,c.name))
        c.name=string(c.prefix,c.name)
    end
    c
end

Component(;name="",species="",prefix="",nodes=[],model=nothing,value=nothing,parameters=[]) = fixname!(Component(name,species,prefix,nodes,value,model,parameters))

Resistor(name,nplus,nminus,value) = Component(;name,nodes=string.([nplus,nminus]),value,species="resistor",prefix="R")
Resistor(;name,nplus,nminus,value) = Resistor(name,nplus,nminus,value)
Capacitor(name,nplus,nminus,value) = Component(;name,nodes=string.([nplus,nminus]),value,species="capacitor",prefix="C")
Capacitor(;name,nplus,nminus,value) = Capacitor(name,nplus,nminus,value)
Inductor(name,nplus,nminus,value) = Component(;name,nodes=string.([nplus,nminus]),value,species="inductor",prefix="L")
Inductor(;name,nplus,nminus,value) = Inductor(name,nplus,nminus,value)
Diode(name,nplus,nminus,model) = Component(;name,nodes=string.([nplus,nminus]),model,species="diode",prefix="D")
Diode(;name,nplus,nminus,model) = Diode(name,nplus,nminus,model)
Subckt(name,nodes::Vector,model::String,parameters=Vector{Parameter}())=Component(;name,prefix="X",nodes=string.(nodes),model,parameters)
Subckt(;name,nodes::Vector,model::String,parameters=Vector{Parameter}())=Subckt(name,nodes,model,parameters)
Instance(args...;kwargs...) = Subckt(args...;kwargs...)

Opamp(name,nplus,nminus,out,model,parameters=Vector{Parameter}())=Subckt(name,[nplus,nminus,out],model,parameters)
Opamp(;name,nplus,nminus,out,model,parameters=Vector{Parameter}())=Opamp(name,nplus,nminus,out,model,parameters)
MOSFET(name,drain,gate,source,substrate,model,parameters=[]) = Component(;name,nodes=string.([drain,gate,source,substrate]),model,parameters,species="mosfet",prefix="M")

Waveform(;wave=:dc,parameters=[])=Waveform(wave,parameters)
Waveform(s::Symbol,args...;kwargs...) = Waveform(Val(s),args...;kwargs...)
Waveform(::Val{:dc},value) = Waveform(wave=:dc,parameters=OrderedDict{String,Any}("value"=>value))
Waveform(::Val{:ac},value=1) = Waveform(wave=:ac,parameters=OrderedDict{String,Any}("value"=>value))
Waveform(::Val{:sin},offset,amplitude,frequency,phase,args...) = Waveform(wave=:sin,parameters=OrderedDict{String,Any}("offset"=>offset,"amplitude"=>amplitude,"frequency"=>frequency,"phase"=>phase))
Waveform(::Val{:sin};offset=0u"V",amplitude=5u"mV",frequency=1u"kHz",phase=0u"°",args...)=Waveform(:sin,offset,amplitude,frequency,phase)
Waveform(::Val{:pwl},points::Vector{Point};args...) = Waveform(wave=:pwl,parameters=points;args...)
Waveform(::Val{:pulse},low,high,delay,risetime,falltime,width,period,pulses;args...) = Waveform(wave=:pulse,parameters=OrderedDict{String,Any}("high"=>high,"low"=>low,"delay"=>delay,"risetime"=>risetime,"falltime"=>falltime,"width"=>width,"period"=>period,"pulses"=>pulses);args...)
Waveform(::Val{:pulse};high=5u"V",low=0u"V",risetime=1u"ns",falltime=1u"ns",width=499u"ns",period=1u"ms",delay=0,pulses=0,args...)=Waveform(:pulse,low,high,delay,risetime,falltime,width,period,pulses;args...)

function Source(;species="vsource",prefix="V",name,nplus,nminus,waveforms::Vector{Waveform},args...)
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
    for x in w.parameters
        print(io,qstr(x[2]), " ")
    end
    if w.wave ∈ [:sin,:pwl,:pulse]
        print(io,")")
    end
    return nothing
end

function report(io::IO,w::Waveform)
    print(io,string(w.wave," waveform with parameters: \n",w.parameters))
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
    for field in [:models,:includes,:parameters,:sources,:components]
        v = getfield(n,field)
        for x in v
            println(io,x)
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


function Base.getindex(instance::Component,name::String)
    string(name[1],".",instance.name,".",name)
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
    if length(c.parameters)>0 print(io," params: "); print.(io,parameters," "); end
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
    for field in (:title, :models, :includes, :parameters, :sources, :components)
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



export Component, Waveform, Source, Resistor, Capacitor, Netlist, Inductor, Diode, Parameter, Model, Include, Subckt, Instance, Opamp, Point, MOSFET

                                      
                                    


    
