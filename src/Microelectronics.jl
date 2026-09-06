module Microelectronics

using LazyModules
using Reexport
@reexport using OrderedCollections,LaTeXStrings,Markdown,Unitful,Printf,Plots

@lazy import NgHerb = "16d751f2-2168-46b0-9d00-9e1470832ba3"

import Base.show
import Base.print
import Plots.plot
import Base.=>
    
include("Objects.jl")

function  parallel(args...)
    uconvert(u"Ω",1.0/sum(1.0./[args...]))
end

function scale_resistor(r::Quantity)
    res = uconvert(u"Ω",r)
    if r >= 1u"MΩ"
        return uconvert(u"MΩ",r)
    elseif r >= 1u"kΩ"
        return uconvert(u"kΩ",r)
    else
        return r
    end
end


function scale_Hz(f::Quantity)
    if f >= 1u"GHz"
        return uconvert(u"GHz", f)
    elseif f >= 1u"MHz"
        return uconvert(u"MHz", f)
    elseif f >= 1u"kHz"
        return uconvert(u"kHz", f)
    elseif f >= 1u"Hz"
        return uconvert(u"Hz", f)
    elseif f >= 1u"mHz"
        return uconvert(u"mHz", f)
    end

    return f
end

function scale_s(s::Quantity)
    if s >= 1u"s"
        return uconvert(u"s", s)
    elseif s >= 1u"ms"
        return uconvert(u"ms", s)
    elseif s >= 1u"μs"
        return uconvert(u"μs", s)
    elseif s >= 1u"ns"
        return uconvert(u"ns", s)
    elseif s >= 1u"ps"
        return uconvert(u"ps", s)
    elseif s >= 1u"fs"
        return uconvert(u"fs", s)
    end

    return s
end

function scale_rad(f::Quantity)
    if f >= 1u"Grad/s"
        return uconvert(u"Grad/s", f)
    elseif f >= 1u"Mrad/s"
        return uconvert(u"Mrad/s", f)
    elseif f >= 1u"krad/s"
        return uconvert(u"krad/s", f)
    elseif f >= 1u"rad/s"
        return uconvert(u"rad/s", f)
    elseif f >= 1u"mrad/s"
        return uconvert(u"mrad/s", f)
    end

    return f
end



function scale_capacitor(c::Quantity)
    if c >= 1u"μF"
        return uconvert(u"μF", c)
    elseif c >= 1u"nF"
        return uconvert(u"nF", c)
    elseif c >= 1u"pF"
        return uconvert(u"pF", c)
    elseif c >= 1u"fF"
        return uconvert(u"fF", c)
    else
        return c
    end
end


function scale_current(i::Quantity)
    if i >= 1u"MA"
        return uconvert(u"MA", i)
    elseif i >= 1u"kA"
        return uconvert(u"kA", i)
    elseif i >= 1u"A"
        return uconvert(u"A", i)
    elseif i >= 1u"mA"
        return uconvert(u"mA", i)
    elseif i >= 1u"μA"
        return uconvert(u"μA", i)
    elseif i >= 1u"nA"
        return uconvert(u"nA", i)
    elseif i >= 1u"pA"
        return uconvert(u"pA", i)
    elseif i >= 1u"fA"
        return uconvert(u"fA", i)
    else
        return i
    end
end

function scale_voltage(v::Quantity)
    if v >= 1u"MV"
        return uconvert(u"MV", v)
    elseif v >= 1u"kV"
        return uconvert(u"kV", v)
    elseif v >= 1u"V"
        return uconvert(u"V", v)
    elseif v >= 1u"mV"
        return uconvert(u"mV", v)
    elseif v >= 1u"μV"
        return uconvert(u"μV", v)
    elseif v >= 1u"nV"
        return uconvert(u"nV", v)
    elseif v >= 1u"pV"
        return uconvert(u"pV", v)
    elseif v >= 1u"fV"
        return uconvert(u"fV", v)
    else
        return v
    end
end


function scale_transconductance(g::Quantity)
    if g >= 1u"A/V"
        return uconvert(u"A/V", g)
    elseif g >= 1u"mA/V"
        return uconvert(u"mA/V", g)
    elseif g >= 1u"μA/V"
        return uconvert(u"μA/V", g)
    elseif g >= 1u"nA/V"
        return uconvert(u"nA/V", g)
    end
    
    return g
end


function scale_quantity(x::Quantity)
    if isradps(x)
        return scale_rad(x)
    elseif isHz(x)
        return scale_Hz(x)
    elseif iss(x)
        return scale_s(x)
    elseif isresistor(x)
        return scale_resistor(x)
    elseif iscapacitor(x)
        return scale_capacitor(x)
    elseif isvoltage(x)
        return scale_voltage(x)
    elseif iscurrent(x)
        return scale_current(x)
    elseif istransconductance(x)
        return scale_transconductance(x)
    end
    return x
end
        

function model_library()
    joinpath(pkgdir(Microelectronics),"model_library.sp")
end
export parallel, scale_radps, scale_quantity, scale_resistor, scale_Hz, scale_capacitor, model_library, scale_s

function be_quiet()
    NgHerb.be_quiet()
end

function dumpbuffer()
    NgHerb.dumpbuffer()
end
export be_quiet,dumpbuffer

function (=>)(x::Quantity,s::Unitful.FreeUnits)
    uconvert(s,x)
end


#================= GLOBAL VARIABLES ==================#
#=
device_species -- dictionary of SPICE devices
- key is the SPICE instance prefix
- value is a Symbol naming the device class
=#

device_species = Dict{String,String}(
        "V"=>"vsource",
        "I"=>"isource",
        "R"=>"resistor",
        "C"=>"capacitor",
        "L"=>"inductor",
        "D"=>"diode",
        "M"=>"mosfet",
        "X"=>"subckt",
        "Q"=>"bjt",
        "J"=>"jfet",
        "F"=>"cccs",
        "H"=>"ccvs",
        "G"=>"vccs",
        "E"=>"vcvs"
        )

device_prefixes = OrderedDict{String,String}(val=>key for (key,val) in device_species)

#=
counts -- used for auto-named instances
=#
counts = Dict{String,Int}()



#============== Convenience Functions ==============#

"""
   hasall(args,k)

Return true if `args` has all keys specified by `k`. Usually
`args` is a Dict or NamedTuple and `k` is a Vector.
"""
function hasall(args,k)
    all(map(x->haskey(args,x),k))
end

"""
   hasany(args,k)

Return true if `args` has any of the keys specified by `k`.
Usually `args` is a Dict or NamedTuple and `k` is a Vector.
"""
function hasany(args,k)
    any(map(x->haskey(args,x),k))
end


#=========== Functions Manipulating Units ==============#

"""
   dB20(x)

Convert `x` to decibels using 20*log10(x).
The argument `x` can be a scalar or a collection of
Numbers.

# Examples

```julia-repl
julia> dB20(1000)
60.0

julia> a=[1,10,100];b=[.1,.01,.001];

julia> dB20(a)
3-element Vector{Float64}:
  0.0
 20.0
 40.0

julia> dB20.([a,b])
2-element Vector{Vector{Float64}}:
 [0.0, 20.0, 40.0]
 [-20.0, -40.0, -60.0]
```
"""
function dB20(x)
    20.0.*log10.(x)
end
export dB20


function isradps(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"rad/s") && contains(string(x),"rad")
end

function israd(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"rad") && contains(string(x),"rad")
end

function iss(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"s")
end

function isHz(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"Hz") && contains(string(x),"Hz")
end

function is°(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"°") && contains(string(x),"°")
end


function isresistor(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"Ω") 
end

function iscapacitor(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"F") 
end


function isvoltage(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"V") 
end


function iscurrent(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"A") 
end


function istransconductance(x::Quantity)
    Unitful.dimension(x) == Unitful.dimension(1u"A/V") 
end



"""
   rad(x::Number)

Given an angular Quantity `x`, return the representation of
`x` in radians or radians per second. If `x` is given in
degrees or Hz, then the output is scaled and converted to
radians or radians/sec, respectively. If `x` has no units,
then it is annotated with u"rad" to confirm it is in radians.
If `x` has some other units that reduce to dimension s^-1,
then the units are stripped and replaced with u"rad". 
"""
function rad(x::Quantity)
    if contains(string(x),r".*Hz$")
        return uconvert(u"rad/s",x*2π)
    elseif unit(x) == u"°"
        return uconvert(u"rad",x)
    elseif unit(upreferred(x)) == u"s^-1"
        return uconvert(u"rad/s",x)
    elseif unit(upreferred(x)) == 1
        return uconvert(u"rad",x)
    else
        return x
    end
end
function rad(x::Number)
    x*u"rad"
end
export rad, israd, isradps, isHz, is°, isvoltage, iscurrent, isresistor, iscapacitor, istransconductance, iss


"""
   °(x::Quantity)

Given an angular Quantity `x`, return the representation of
`x` in degrees or Hz. If `x` is given in radians or rad/s,
then it is converted to degrees or Hz, respectively. If `x`
has no units, then it is annotated with u"°" to confirm it
is in degrees. If `x` has some other units that reduce to
dimension s^-1, then the units are stripped and replaced
with u"°".
"""
function °(x::Quantity)
    if unit(x) == u"rad*s^-1"
        return uconvert(u"Hz",x/2π)
    elseif unit(x) == u"rad"
        return uconvert(u"°",x)
    elseif unit(upreferred(x)) == u"s^-1"
        return uconvert(u"Hz",x)
    elseif !(typeof(upreferred(x)) <: Quantity)
        return upreferred(x)*u"°"
    else
        return x
    end
end
function °(x::Number)
    return x*u"°"
end
export °



"""
   Hz(x::Quantity)

Given angular Quantity `x` with units rad/s or
dimension s^-1, scale `x` by `1/2π` and replace
the units with u"Hz". If `x` does not meet one of
these conditions, it is returned unaltered.
"""
function Hz(x::Quantity)
    if contains(string(x),r".*Hz$")
        return uconvert(u"Hz",x)
    elseif unit(x) == u"rad*s^-1"
        return uconvert(u"Hz",x/2π)
    elseif unit(upreferred(x)) == u"s^-1"
        return uconvert(u"Hz",x/2π)
    else
        return x
    end
end
export Hz


#========= Printing and Reporting Functions ===========#


"""
   report(s::String)

Print `s` within horizontal lines for emphasis. The lines
are made using '-' characters, and are auto-sized to match
the width of the text in `s`.

# Example

```julia-repl
julia> report("hello there")
-----------
hello there
-----------

```
"""
function report(s::String)
    maxwidth=0
    for l in eachsplit(s,"\n")
        if length(l) > maxwidth
            maxwidth = length(l)
        end
    end
    println('-'^maxwidth)
    println(s)
    println('-'^maxwidth)
end


"""
   function report(io::IO=stdout,p::OrderedDict)

Print the table `p` in Markdown format on `io`.

# Examples

```julia-repl
julia> report(stdout,OrderedDict("A"=>1u"ms","B"=>1u"V"))
| Parameter  |  Value        | Unit        |
|------------|---------------|-------------|
|A           |              1|           ms|
|B           |              1|            V|


julia> report(@table A=1u"ms" B=1u"V")
| Parameter  |  Value        | Unit        |
|------------|---------------|-------------|
|A           |              1|           ms|
|B           |              1|            V|

```
"""
function report(io::IO,p::OrderedDict)
    print(io,"| Parameter  |  Value        | Unit        |\n")
    print(io,"|------------|---------------|-------------|\n")
    for k in keys(p)
        val=p[k]
        if typeof(val)<:Quantity
            x = scale_quantity(val)
            print(io,@sprintf("|%-12s|%15g|%13s|\n",k,ustrip(x),unit(x)))
        else
            print(io,@sprintf("|%-12s|%15s|%13s|\n",k,p[k]," "))
        end
    end
end


function report(n::NamedTuple)
    d = OrderedDict{String,Any}()
    for k in keys(n)
        d[string(k)] = n[k]
    end
    report(d)
end


report(p::OrderedDict)=report(stdout,p)
export report

"""
   Base.show(io::IO,v::Vector{String)}

Print `v` as line-by-line text, one line for each element.

# Example

```julia-repl
julia> v = ["hi","there"]
hi
there
```
"""
function Base.show(io::IO,::MIME"text/plain",v::Vector{String})
    for s in v
        println(io,s)
    end
end

"""
   Base.show(io::IO,d::OrderedDict}

Print the elements of `d` line-by-line, one line for
each element.

# Example

```julia-repl
julia> d=OrderedDict(:a=>"foo",:b=>"bar")
:a => foo
:b => bar

```
"""
function Base.show(io::IO,::MIME"text/plain",d::OrderedDict)
    report(io,d)
end

function Base.show(io::IO,s::String)
    for line in eachsplit(s,"\n")
        println(io,line)        
    end
end

export show

function Base.print(io::IO,v::Vector{String})
    for s in v
        println(io,s)
    end
end


function Base.print(io::IO,d::OrderedDict)
    report(io,d)
end

function Base.print(d::OrderedDict)
    report(stdout,d)
end

export print




#=========== SPICE String Conversions ================#

#=
"""
   device_species(d)

Returns a Symbol indicating the device species that corresponds to
SPICE prefix `d`. The prefix can be a String, Char, Symbol, or
other type that can be converted to a single-character String.

# Examples
```julia-repl
julia> device_species("R")
:resistor
```

```julia-repl
julia> device_species(:C)
:capacitor
```
"""
function device_species(d)
    device_species[String(d)]
end
export device_species
=#

function device_prefix(d)
    device_prefixes[String(d)]
end
export device_prefix


"""
   spice_value(q::Quantity)

Convert a `Unitful` quantity to a stripped numerical value
in preferred units. Useful to print values in SPICE netlists.
"""
function spice_value(q::Quantity)
    Float64(ustrip(upreferred(Hz(q))))     
end
export spice_value


"""
   qstr(q)

Convert quantity `q` to a String to use in SPICE. If `q` is
already a String, it's returned unaltered. If `q` is a Unitful
quantity, then the stripped version `spice_value(q)` is returned.
If `q` is a Symbol, then the NgSpice parameter string `{q}` is
returned.  If `q` is any other type, its string representation is
returned.

# Examples

```julia-repl
julia> qstr(:Rval)
"{Rval}"

julia> qstr("1k")
"1k"

julia> qstr(1u"nF")
"1e-9"
```
"""
function qstr(q)
    if typeof(q)<:String
        new_str=q
    elseif typeof(q)<:Quantity
        new_str=@sprintf("%g",spice_value(q))
    elseif typeof(q)<:Symbol
        new_str=@sprintf("{%s}",string(q))
    else
        new_str=string(q)
    end
    return new_str
end
export qstr


"""
   sin_string(offset,amplitude,frequency,phase=0)

Return a SPICE string representing a sinusoidal source. Can be
appended to voltage or current sources.
"""
function sin_string(offset,amplitude,frequency,phase=0)
    return @sprintf(" SIN (%s,%s,%s,%s) ",qstr.((offset,amplitude,frequency,phase))...)
end
export sin_string


"""
   pwl_string(points::Vector{Tuple{Number,Number}})

Returns a SPICE-formatted string for a Piecewise Linear independent
source using data provided in `points`. Each element of `points` is
a Tuple indicating (time,value). The time and value can be Unitful
Quantities or unitless numbers, in which case they are assumed to be
(s,V) or (s,A) depending on the source species. Generally speaking, the
`points` should be ascending in time. It is not necessary to use the
same units for each point.

# Examples

```julia-repl
julia> points=Vector{Tuple{Number,Number}}()
julia> push!(points,(0,0))
julia> push!(points,(1u"ms",2u"mV"))
julia> pwl_string(points)
"PWL ( 0 0 0.001 0.02)"
```
"""
function pwl_string(points::Vector)
    s=IOBuffer()
    print(s,"PWL (")
    for p in points
        print(s," ")
        print(s,qstr(p[1]))
        print(s," ")
        print(s,qstr(p[2]))
    end
    print(s,")")
    return String(take!(s))
end
export pwl_string


"""
   pulse_string(;high=5u"V",low=0u"V",period=1u"ms",width=490u"ns",risetime=10u"ns",falltime=10u"ns",delay=10u"ns",pulses="")

Returns a SPICE-formatted string for a PULSE independent source. The
`low` parameter is the initial value, and `high` is the "pulsed" value.

"""
function pulse_string(;high=5u"V",low=0u"V",period=1u"ms",width=490u"ns",risetime=10u"ns",falltime=10u"ns",delay=10u"ns",pulses="",args...)
    @sprintf(" PULSE (%s %s %s %s %s %s %s %s )",
             qstr.(
                 (low,high,delay,risetime,falltime,
                  width,period,pulses)
                      )...
             )
end
export pulse_string


"""
   next_name(d::String)

Increments the counter for instance of device species `d`, and
returns a SPICE device name.

# Examples
```julia-repl
julia> next_name("R")
"R1"
julia> next_name("R")
"R2"
```
"""
function nextname(s)
    if !haskey(counts,s)
        counts[s] = 1
    end
    name=@sprintf("%s%d",s,counts[s])
    counts[s] += 1
    return name
end


"""
spice_parameters(p::OrderedDict,[keys...])

Return a String of SPICE parameter declarations using entries
in dictionary `p`. If additional arguments are specified,
then lines are output only for the specified keys.

# Examples

```julia-repl
julia> d = @table a=1u"V"  b=4u"ms";

julia> spice_parameters(d)
.param     a=1.0000e+00
.param     b=4.0000e-03



julia> spice_parameters(d,"a")
.param     a=1.0000e+00

```
"""
function spice_parameters(p::OrderedDict,vars...)
    ostr = ""
    for var in vars
        val = p[var]            
        ostr *= @sprintf(".param %5s=%s\n",var,qstr(val))
    end
    return ostr
end

spice_parameters(p::OrderedDict) = spice_parameters(p,Tuple(keys(p))...)
export spice_parameters



#============= Instantiate Bipole Devices ===============#

"""
   bipole(species,nplus,nminus,value)

Return a String declaring a SPICE instance of a two-terminal bipole
device of the specified `species`, connected between nodes
`nplus` and `nminus`, with an automatically assigned device name.
The `species` is usually a Symbol or String equalling one of R, C,
L, D, V, or I, but no checking is done. The nodes `nplus` and `nminus`
are String or Int, and the `value` is a Float, Unitful Quantity, String,
or model name.

# Examples

```julia-repl
julia> bipole(:d, 2, 1, "D1N4004")
"D1    2    1   1N4004"

julia> bipole(:C, 2, 3, 1u"nF")
"C1    2    3   1e-9" 
```
"""
function bipole(species,nplus,nminus,value)
    @sprintf("%-5s %-5s %-5s %s",
        nextname(uppercase(string(species))),nplus,nminus,qstr(value))
end
export bipole


"""
   bipole(species,name,nplus,nminus,value)

Return a String declaring a SPICE instance of a two-terminal bipole
device of the specified `species`, connected between nodes
`nplus` and `nminus`, with the given instance name. The `species`
is usually one of R, C, L, or D, but no checking is done. Usually the
`species` is a String or Symbol, the nodes `nplus` and `nminus` are
String or Int, and the `value` is a Float, Unitful Quantity, String,
or model name. If the `name` does not have the expected SPICE prefix,
it is inserted.

# Examples

```julia-repl
julia> bipole(:d, "d1", 2, 1, "1N4004")
"D1    2    1   1N4004"

julia> bipole(:C, 1, 2, 3, 1u"nF")
"C1    2    3   1e-9" 
```
"""
function bipole(species,name,nplus,nminus,value)
    dt = uppercase(string(species))
    nm = string(name)
    
    if uppercase(string(name[1])) == dt
        nm = name
    else
        nm = dt*nm
    end
    @sprintf("%-5s %-5s %-5s %s",
        nm,nplus,nminus,qstr(value))
end


function subckt_instance(;name,terminals,model)
    if typeof(terminals)==String
        s = @sprintf("X%-5s %-5s %-5s %-5s %s\n",name,terminals,model)
    elseif typeof(terminals)<:Union{AbstractArray,Tuple}
        s = @sprintf("X%-5s",name)
        for t in terminals
            s = @sprintf("%s %-5s",s,t)
        end
        s = @sprintf("%s %s\n",s,model)
    end
    return s
end
export subckt_instance


function mosfet(name,drain,gate,source,substrate,model=ald1105n;
                L=10e-6,W=20e-6,AS=0.603e-8,PS=0.478e-6,
                AD=0.161e-8,PD=0.478e-6,NRD=0.3,NRS=1
                )
    s = @sprintf("M%-5s %-5s %-5s %-5s %-5s %s W=%s L=%s AD=%s AS=%s PD=%s PS=%s NRD=%s NRS=%s",name,drain,gate,source,substrate,model,qstr.((W,L,AD,AS,PD,PS,NRD,NRS))...)
    return s
end
export mosfet

#=
searchfile(path,key)=filter(x->occursin(key,x),readdir(path))
    
function add_model!(models::Vector{String},device::String)

    modelstr   = Regex(device,"i")
    modelfiles = Vector{String}
    
    for pathstr in [ realpath(pwd()),
                     realpath(pwd()*"/models"),
                     realpath(dirname(pathof(@__MODULE__))*"../models")
                     ]
        push!(modelfiles,searchfile(pathstr,modelstr))
    end

    push!(models,".include $(modelfiles[1])")    
end


function verify_device_model(models::Union{String,Vector{String}},device::String)
    rx = Regex(device,"i")
    if typeof(models) == String
        mvec = split(models,"\n")
    else
        mvec = models
    end
    for m in mvec
        if occursin(basename(m),rx)
            return true
        end
    end
    return false
end
=#

#====== Build and Load Netlists ===========#

"""
   build_netlist(s="";title="circuit",parameters="",models="",includes="",sources="",components="")

Constructs and loads a SPICE netlist with this format:

```
* <title>
<models>
<parameters>
<sources>
<components>
<s>
.end
```

The positional argument `s` can be any SPICE-compatible text. The kwargs
can be String or Vector{String} types, usually generated by
other functions in the Microelectronics package. All args and
kwargs are optional; if none are given, then an empty netlist
is loaded.

# Example

```julia-repl
julia> title="Example Circuit";
julia> sources=[vdc("V1",1,0,1u"V")];
julia> components=[resistor("R1",1,0,1u"kΩ")];
julia> build_netlist(;title,sources,components)
Note: No compatibility mode selected!
Circuit: * example circuit
* Example Circuit

V1    1     0      DC 1

R1    1     0     1000

.end
```
"""
function build_netlist(s="";title="circuit",parameters="",models="",sources="",components="")
    io = IOBuffer()
    println(io,"* ",title)
    mp=realpath(dirname(pathof(@__MODULE__))*"/..")
    println(io,".include $mp/model_library.sp")
    for x in [parameters,models,sources,components]
        println(io,x)
    end
    println(io,".end")
    netlist=String(take!(seekstart(io)))
    load_netlist(netlist)
    netlist
end

export build_netlist



"""
   load_netlist(n::AbstractString)

Calls the NgHerb `load_netlist` function.
"""
function load_netlist(n::AbstractString)
    NgHerb.load_netlist(n)
end
export load_netlist




#=========== Standard Electrical Elements ==============#

"""
   opamp(;name,nplus,nminus,out,model="ideal_opamp",params="")

Instantiate a three-terminal op amp subcircuit. There are
no positional arguments. Mandataory keyword arguments are:

- `name` -- 'X' is prefixed
- `nplus` -- non-inverting input terminal
- `nminus` -- inverting input terminal
- `out`    -- output terminal

Optional keyword arguments:
- `model`  -- name of subcircuit model (`ideal_opamp` is default)
- `params` -- a string with additional subcircuit parameters

The `model` must be the name of a three-terminal op amp
subcircuit that has been defined or included in the netlist.
Any `params` are specific to the model, but may include things
like the power rails, slew rate, current limit, etc.

# Example

```julia-repl
julia> opamp(;name="OA1", nplus=0, nminus=2, out=3, model="my_opamp")
XOA1   0     2     3     my_opamp
```
"""
function opamp(;name,nplus,nminus,out,model="ideal_opamp")
    subckt_instance(;name,terminals=(nplus,nminus,out),model)
end
export opamp

             



"""
   independent_source(species;args...)

Instantiate an independent Voltage or Current source.
`species` is "V" or "I".

# Keyword arguments

All instances must have the positive and negative
terminals assigned via `nplus` and `nminus`.

Optionally, a `name` can be given.

Remaining keyword arguments are specific to the desired source
species.

  - DC source:
    - `dc` specifies the desired voltage or current
  - AC source:
    - `ac` specifies the AC magnitude (usually 1)
  - SIN source:
    - `offset`    
    - `amplitude` 
    - `frequency` 
    - `phase`     
  - PWL source:
    - `points`
  - PULSE source
    - `high`
    - `low`
    - `width`
    - `period`

If no keyword arguments are given, a zero-value source is instantiated.
"""
function independent_source(species;args...)

    io = IOBuffer()
    
    if hasany(args,[:dc,:dctype])
        if haskey(args,:dc)
            print(io," DC $(qstr(args[:dc]))")
        else
            print(io," DC 0")
        end
    end
    if haskey(args,:ac)
        print(io," AC $(args[:ac])")
    end
    if hasany(args,[:sintype,:offset,:frequency,:amplitude,:phase])
        sinargs=(;)
        for k in [(:offset,0),(:amplitude,.005),(:frequency,1000),(:phase,0)]
            if haskey(args,k[1])                
                sinargs=merge(sinargs,[k[1]=>args[k[1]]])
            else
                sinargs=merge(sinargs,[k[1]=>k[2]])
            end
        end
        print(io,sin_string(sinargs...))
    elseif haskey(args,:points)
        print(io,pwl_string(args[:points]))
    elseif hasany(args,[:high,:low,:period,:width,:risetime,:falltime])
        print(io,pulse_string(;args...))
    end
    if haskey(args,:value)
        print(io,args[:value])
    end
    val = String(take!(seekstart(io)))
    if hasall(args,[:nplus,:nminus])
        if haskey(args,:name)
            return bipole(species,args[:name],args[:nplus],args[:nminus],val)
        else
            return bipole(species,args[:nplus],args[:nminus],val)
        end
    end    
end
export independent_source


function dependent_source(s::Symbol;name,nplus,nminus,control,gain=1)
    dependent_source(Val(s);name,nplus,nminus,control,gain)
end


function dependent_source(::Val{:cccs};name,nplus,nminus,control,gain)
    "F$name $nplus $nminus $control $(qstr(gain))\n"
end
function dependent_source(::Val{:ccvs};name,nplus,nminus,control,gain)
    "H$name $nplus $nminus $control $(qstr(gain))\n"
end

function dependent_source(::Val{:vccs};name,nplus,nminus,control,gain)
    "G$name $nplus $nminus $(control[1]) $(control[2]) $(qstr(gain))\n"
end

function dependent_source(::Val{:vcvs};name,nplus,nminus,control,gain)
    "E$name $nplus $nminus $(control[1]) $(control[2]) $(qstr(gain))\n"
end
export dependent_source


#============== Aliases for Independent Source ============#
for u in ("v","i")
    s="""
$(u)sin(;amplitude=5u"mV",offset=0u"V",frequency=1u"kHz",phase=0u"°",args...) = independent_source("$u";amplitude,offset,frequency,phase,args...)         
$(u)dc(;dc=0,args...) = independent_source("$u";dc,args...)
$(u)ac(;ac=1,args...) = independent_source("$u";ac,args...)
$(u)pulse(;period=1u"ms",args...) = independent_source("$u";period,args...)
$(u)pwl(;points=[(0,0),(1,1)],args...)=independent_source("$u";points,args...)
"""
    eval.(Meta.parse.(eachsplit(s,"\n")))

    # Positional formats
    for w in ("dc","ac","sin","pulse","pwl")
        s="""
          $u$w(name;args...) = $u$w(;name,args...)
          $u$w(name,nplus,nminus;args...) = $u$w(name;nplus,nminus,args...)
          export $u$w
    """
        eval.(Meta.parse.(eachsplit(s,"\n")))
    end

    # Special formats
    s="""
      $(u)sin(name,nplus,nminus,offset,amplitude,frequency;args...) = $(u)sin(name,nplus,nminus;offset,amplitude,frequency,args...)    
      $(u)dc(name,nplus,nminus,dc;args...) = $(u)dc(name,nplus,nminus;dc,args...)    
      $(u)ac(name,nplus,nminus,ac;args...) = $(u)ac(name,nplus,nminus;ac,args...)    
    """
    eval.(Meta.parse.(eachsplit(s,"\n")))
end


#======== Aliases for Passive Bipoles =============#
for c in ("R","L","C","D")
    eval(quote
            function $(Symbol(device_species[c]))(nplus,nminus,value) 
                bipole($c,nplus,nminus,value)
            end
            function $(Symbol(device_species[c]))(name,nplus,nminus,value)
                bipole($c,name,nplus,nminus,value)
            end
            function $(Symbol(device_species[c]))(;name,nplus,nminus,value)
                bipole($c,name,nplus,nminus,value)
            end
            export $(Symbol(device_species[c]))
        end)
end




#============= Simulation Interface =============#

"""
simulate(analysis::Symbol; args...)

Request the indicated `ngspice` analysis. Keyword arguments
must be provided, depending on the analysis type.

Analysis   Keyword Argument   Description
--------   -----------------  ------------------
`:tran`    `tmax`             Time to end the simulation
           `tstep`            Maximum time-step
`:dc`      `device`           Device or parameter to sweep
           `start`            Initial value
           `stop`             Final value
           `step`             Increment between values
`:ac`      `start`            Low frequency
           `stop`             High frequency
           `mode`             :lin, :dec, :oct
           `steps`            Points per interval

# Examples

```julia-repl
julia> simulate(:ac; start=10u"kHz",stop=1u"MHz",steps=10)
```
"""
function simulate(s::Symbol;args...)
    simulate(Val(s);args...)
    #NgHerb.dumpbuffer()
end


function simulate(::Val{:tran};tstep,tmax)
    transient(;tstep,tmax)
end

function simulate(::Val{:dc};device,start,stop,step)
    dc(;device,start,stop,step)
end

function simulate(::Val{:ac};start,stop,mode=:dec,steps=10)
    ac(;start,stop,mode,steps)
end

function simulate(::Val{:op})
    NgHerb.cmd("op")
end

export simulate


function transient(;tstep,tmax)
    s="tran $(qstr(tstep)) $(qstr(tmax))"
    NgHerb.cmd(s)
end
export transient


function dc(;device,start,stop,step)
    s="dc $device $(qstr(start)) $(qstr(stop)) $(qstr(step))"
    NgHerb.cmd(s)
end
export dc


"""
   ac(;start,stop,mode,points)

Run an AC simulation with parameters:

  * `start` = initial (low) frequency
  * `stop`  = final (high) frequency
  * `mode` =
    - `lin` for linear
    - `dec` for logarithmic across decades
    - `oct` for logarithmic across octaves
  * `steps` = number of frequency steps per interval
"""
function ac(;start,stop,mode,steps)
    s="ac $(string(mode)) $(qstr(steps)) $(qstr(start)) $(qstr(stop)) "
    NgHerb.cmd(s)
end
export ac


"""
   tran_time()

Returns the `time` vector from NGSpice.
"""
function tran_time()
    t=NgHerb.getrealvec("time").*u"s"
    tmax=maximum(t)
    for u in (u"s",u"ms",u"μs",u"ns",u"ps")
        if tmax > 1*u
            return uconvert.(u,t)
        end
    end    
end
export tran_time

"""
   dc_sweep()

Returns a vector of sweep values used in a DC simulation.

# Example

```julia-repl
julia> build_netlist(;sources=[vdc("v1",1,0,0)])
Circuit: * circuit
Parse: 12.5%
* circuit


v1    1     0      DC 0


.end

julia> simulate(:dc;device="v1",start=0,stop=1,step=0.5)
Parse
Doing analysis at TEMP = 27.000000 and TNOM = 27.000000
Using SPARSE 1.3 as Direct Linear Solver
 Reference value :  0.00000e+00
--ready--
--ready--
No. of Data Rows : 3
0

julia> dc_sweep()
3-element Vector{Float64}:
 0.0
 0.5
 1.0

```
"""
function dc_sweep()
    pl=NgHerb.curplot()
    vecs=NgHerb.listallvecs(pl)
    for v in vecs[pl]
        if occursin("-sweep",v)
            data = NgHerb.getvec(v)
            if data[2]=="voltage"
                return data[3].*1u"V"
            elseif data[2]=="current"
                return data[3].*1u"A"
            else
                return data[3]
            end
        end
    end    
end
export dc_sweep


"""
   ac_freq()

Return a vector of frequency values used in an AC
simulation.

# Example

```julia-repl
julia> build_netlist(;sources=[vac("v1",1,0,1)])
Source Deck
Circuit: * circuit
* circuit

v1    1     0      AC 1

.end

julia> simulate(:ac;start=10,stop=50)
Parse
Doing analysis at TEMP = 27.000000 and TNOM = 27.000000
Using SPARSE 1.3 as Direct Linear Solver
Note: v1: has no value, DC 0 assumed
 Reference value :  1.00000e+01
No. of Data Rows : 7
0

julia> ac_freq()
7-element Vector{Float64}:
 10.0
 12.589254117941673
 15.848931924611136
 19.952623149688797
 25.118864315095806
 31.6227766016838
 39.810717055349734

```
"""
function ac_freq()
    NgHerb.getrealvec("frequency")
end
export ac_freq


"""
   nodes(args...)

Return a Vector of Vectors corresponding to the given
node names. Each sub-vector contains voltages at the
indicated node, corresponding to the most recent
simulation.

# Example

```julia-repl
julia> build_netlist(components=[vdc("v1",1,0,1u"V"),resistor("R1",1,2,1u"kΩ"),resistor("R2",2,0,1u"kΩ")]);
Note: No compatibility mode selected!
Circuit: * circuit

julia> simulate(:dc;device="v1",start=0,stop=1,step=0.5);
Parse
Doing analysis at TEMP = 27.000000 and TNOM = 27.000000
Using SPARSE 1.3 as Direct Linear Solver
 Reference value :  0.00000e+00
--ready--
--ready--
No. of Data Rows : 3

julia> nodes(1,2)
2-element Vector{Vector{Float64}}:
 [0.0, 0.5, 1.0]
 [0.0, 0.25, 0.5]

```
"""
function nodes(args...)
    [ NgHerb.getrealvec(string(i)) for i in args ]
end
export nodes



function find_vec(s::String)
    vecs = NgHerb.listcurvecs()
    for x in (string(s),string("V(",s,")"),string(s,"#branch"))
        if x ∈ vecs
            return x
        end
    end
end


function find_vecs(args...)
    [find_vec(string(s)) for s in args]
end

function isvoltage(name::String)
    v = NgHerb.getvec(name)
    if v[2] == voltage
        return true
    else
        return false
    end    
end

function iscurrent(name::String)
    v = NgHerb.getvec(name)
    if v[2] == voltage
        return true
    else
        return false
    end
end


"""
   magnitudes(args...)

Return a Vector of magnitude Vectors corresponding to
the given node names. Each sub-vector contains voltage
magnitudes at the indicated node, corresponding to the
most recent AC simulation.

# Example

```julia-repl
julia> build_netlist(components=[vac("v1",1,0,1),resistor("R1",1,2,1u"kΩ"),capacitor("C1",2,0,1u"nF")]);
Source Deck
Note: No compatibility mode selected!
Circuit: * circuit

julia> simulate(:ac;start=10u"kHz",stop=10u"MHz",steps=1)

Doing analysis at TEMP = 27.000000 and TNOM = 27.000000
Using SPARSE 1.3 as Direct Linear Solver
Note: v1: has no value, DC 0 assumed
 Reference value :  1.00000e+04
--ready--
No. of Data Rows : 4
0

julia> magnitudes(1,2)
2-element Vector{Vector{Float64}}:
 [1.0, 1.0, 1.0, 1.0]
 [0.998031904503645, 0.8467330159648305, 0.1571767254775899, 0.015913478971147702]

```
"""
function magnitudes(args...)
    [ NgHerb.getmagnitudevec(string(i)) for i in args ]
end


function magnitudes(v::Vector)
    [ NgHerb.getmagnitudevec(string(i)) for i in v ]
end
export magnitudes
    

"""
   phases(args...)

Return a Vector of Phase Vectors corresponding to the given
node names. Each sub-vector contains voltages at the
indicated node, corresponding to the most recent AC
simulation.

# Example

```julia-repl
julia> build_netlist(components=[vac("v1",1,0,1),resistor("R1",1,2,1u"kΩ"),capacitor("C1",2,0,1u"nF")]);
Source Deck
Note: No compatibility mode selected!
Circuit: * circuit

julia> simulate(:ac;start=10u"kHz",stop=10u"MHz",steps=1)

Doing analysis at TEMP = 27.000000 and TNOM = 27.000000
Using SPARSE 1.3 as Direct Linear Solver
Note: v1: has no value, DC 0 assumed
 Reference value :  1.00000e+04
--ready--
No. of Data Rows : 4
0

julia> phases(1,2)
2-element Vector{Vector{Float64}}:
 [0.0, 0.0, 0.0, 0.0]
 [-3.5952737798681755, -32.14190763534206, -80.95693892096232, -89.08818633038616]


```
"""
function phases(args...)
    (180/π).*[ NgHerb.getphasevec(string(i)) for i in args ]
end
export phases


function simx()
    pl=NgHerb.curplot()
    if occursin("tran",pl)
        return tran_time()
    elseif occursin("dc",pl)
        return dc_sweep()
    elseif occursin("ac",pl)
        return ac_freq()
    end
end

function simxlabel()
    pl=NgHerb.curplot()
    if occursin("tran",pl)
        return "Time [$(unit(tran_time()[1]))]"
    elseif occursin("dc",pl)
        return "Sweep [$(unit(dc_sweep())[1])]"
    elseif occursin("ac",pl)
        return "Frequency [Hz]"
    end
end


"""
    plot(v::Vector{Vector};args...)

Plot a Vector of Vectors where the horizontal axis is
determined by the latest SPICE simulation.

Simulation Type      X Axis
----------------    ------------
:tran (transient)    tran_time()
:dc   (dc sweep)     dc_sweep()
:ac   (ac sweep)     ac_freq()


# Examples

```julia-repl
julia> v1=vsin("v1",1,0;ac=1,dc=1,frequency=1u"kHz",amplitude=1u"V")
v1    1     0      DC 1 AC 1 SIN (0,1,1000,0) 

julia> build_netlist(sources=[v1],components=[resistor("R1",1,2,1u"kΩ"),capacitor("C1",2,0,1u"nF")]);
...

julia> simulate(:dc;device="v1",start=0,stop=2,step=0.1);
...

julia> plot([node"1",node"2"];labels=["v1" "v2"])

julia> simulate(:ac;start=10u"kHz",stop=10u"MHz",steps=10)
...

julia> plot([dB"1",dB"2"];xscale=:log10,labels=["v1" "v2"])

```
        """
function plot(names::Union{String,Number}...;args...)
    vecs = find_vecs(names...)
    if !isnothing(vecs)
        labels=replace.(vecs,r"(.*)#branch"=>s"I(\1)")
        labels=reshape(labels,(1,length(labels)))

        data = NgHerb.getvec.(vecs)
        vsigs = [y[3] for y in data if y[2]=="voltage"]
        isigs = [y[3] for y in data if y[2]=="current"]
        vlabels = [y[1] for y in data if y[2]=="voltage"]
        ilabels = [replace(y[1],r"(.*)#branch"=>s"I(\1)") for y in data if y[2]=="current"]
        vlabels=reshape(vlabels,(1,length(vlabels)))
        ilabels=reshape(ilabels,(1,length(ilabels)))
        
        if length(vsigs)>0 && length(isigs)>0
            p=plot(simx(),vsigs; labels=vlabels,ylabel="V",args...)
            
            tw = twinx(p)
            plot!(tw,simx(),isigs; labels=ilabels,ylabel="A",linestyle=:dash,args...)
        elseif length(vsigs)>0
            p=plot(simx(),vsigs; labels=vlabels,ylabel="V",args...)
        elseif length(isigs)>0
            p=plot(simx(),isigs; labels=ilabels,ylabel="A",args...)
        else
            return nothing
        end
        return p
    else
        return nothing
    end
    
end

function plot(v::Vector{Vector};args...)
    pl=NgHerb.curplot()
    if occursin("tran",pl)
        t=tran_time()
        Plots.plot(t,v;xlabel="Time [$(unit(t[1]))]",args...)
    elseif occursin("dc",pl)
        Plots.plot(dc_sweep(),v;args...)
    elseif occursin("ac",pl)
        Plots.plot(ac_freq(),v;args...)
    end
end
export plot


"""
   bode(vectors...;args...)

Create a Bode plot (with magnitude and phase subplots)
for the indicated `vectors`. The vectors are a comma-separated
list of node names (for voltage signals) or source names (for
current signals). Voltage and current can be mixed on the same
plot. Magnitude units are dBV and dBA for voltage and current, resp. 

Additional keyword arguments `args` are passed through to `Plots.plot`.

# Examples

```julia-repl

julia> build_netlist(sources=[vac("V1",1,0)],components=[resistor("R1",1,2,1u"kΩ"),capacitor("C1",2,0,1u"μF")])
Note: No compatibility mode selected!
Circuit: * circuit
* circuit

V1    1     0      AC 1
R1    1     2     1000
C1    2     0     1e-06
.end

julia> ac(start=10u"Hz",stop=1u"MHz",steps=10,mode=:dec)
Doing analysis at TEMP = 27.000000 and TNOM = 27.000000
Using SPARSE 1.3 as Direct Linear Solver
stderr Note: v1: has no value, DC 0 assumed
 Reference value :  1.00000e+01
No. of Data Rows : 51

julia> bode(2,"v1")

``` 
"""
function bode(nets...;args...)
    vecs = find_vecs(nets...)
    labels=replace.(vecs,r"(.*)#branch"=>s"I(\1)")
    labels=reshape(labels,(1,length(labels)))
    if occursin("ac",NgHerb.curplot())
        p=Plots.plot(Plots.plot(ac_freq(),dB20.(magnitudes(vecs));
                    xscale=:log10,
                    ylabel="Magnitude [dB]",
                    labels,
                    args...),
               Plots.plot(ac_freq(),phases(vecs...);
                    xscale=:log10,
                    ylabel="Phase [°]",
                    xlabel="Frequency [Hz]",
                    labels,
                    args...);
               layout=(2,1)
             )
    end
    return p
end
export bode


"""
   measure(s::Symbol;args...)

Perform one of several SPICE measurements after
running a simulation.

Measurement        Function Format      Comment
------------      --------------------  -----------------------
Voltage Gain       measure(:Av;in,out)  `in`,`out` are nodes
Transconductance   measure(:Gm;in,out)  `out` is a voltage source
Slew Rate          measure(:slew;node)

"""
function measure(s::Symbol;args...)
    measure(Val(s);args...)
end



function measure(::Val{:Gm};in,out)
    if occursin("tran",NgHerb.curplot())
        NgHerb.cmd("meas tran iopp pp i($out)")
        NgHerb.cmd("meas tran vipp pp v($in)")
        iopp=NgHerb.getrealvec("iopp")[1]
        vipp=NgHerb.getrealvec("vipp")[1]
        return iopp/vipp        
    end
end


function measure(::Val{:Av};in,out)
    if occursin("tran",NgHerb.curplot())
        NgHerb.cmd("meas tran vopp pp v($out)")
        NgHerb.cmd("meas tran vipp pp v($in)")
        vopp=NgHerb.getrealvec("vopp")[1]
        vipp=NgHerb.getrealvec("vipp")[1]
        return vopp/vipp
    end
end


function measure(::Val{:slew};node)
    if occursin("tran",NgHerb.curplot())
        #NgHerb.cmd("meas tran slew deriv v($node)")
        NgHerb.cmd("let slew=maximum(deriv(v($node)))")
        deriv=NgHerb.getrealvec("slew")*1e-6u"V/μs"
        return deriv[1]
    end
end

function measure(::Val{:cutoff};name)
    if occursin("ac",NgHerb.curplot())
        vname = find_vec(name)
        mag = dB20.(magnitudes(vname)[1])
        cutoff_mag = maximum(mag) - 3.0
        NgHerb.cmd("meas ac fc when vdb($vname)=$cutoff_mag")
        return NgHerb.getrealvec("fc")[1]
    end
end


export measure


#============= Table of Parameters =========================#
"""
   @table(p1, p2, ...)

   @table p1 p2 ...

   @table(p1=val1, p2=val2, ...)  

 Define a dictionary (i.e. table) of parameter names and values.
"""
macro table(vars...)
    expr = Expr(:call, :OrderedDict)
    for var in vars
        q=eval(:($(QuoteNode(var))))
        t=typeof(q)
        if t == Symbol
            n=String(q)
            push!(expr.args,:($(n) => $(esc(q))))
        elseif t == Expr
            if q.head == :(=)
                n=String(q.args[1])
                push!(expr.args,:($(n) => $(esc(q.args[2]))))
            end
        else
            println("Possible error: strange parameter format")
        end
                
    end
    return expr
end


# pwl"" parses a list of PWL points in tabular format
macro pwl_str(s)
    points = Vector{Tuple{Number,Number}}()
    for line in eachsplit(s,"\n")
        p = split(line)
        if length(p) == 2
            push!(points,(uparse(p[1]),uparse(p[2])))
        end
    end
    points
end


#================ Special Strings =====================#
# ng"" sends the quoted command to the simulator
macro ng_str(s)
    NgHerb.cmd(s)    
end

# real"" retrieves the real-valued part of the indicated vector
macro real_str(s)
    NgHerb.getrealvec(s)
end

# imag"" retrieves the imaginary-valued part of the indicated vector
macro imag_str(s)
    NgHerb.getimagvec(s)
end

# i"" retrieves the current in the indicated voltage source
macro i_str(s)
    i=NgHerb.getrealvec(s*"#branch").*u"A"
    imax=abs(maximum(i))
    for u in (u"A",u"mA",u"μA",u"nA",u"pA")
        if imax >= 1*u
            return uconvert.(u,i)
        end
    end
    return i
end

# node"" retrieves voltage at the indicated node, relative to ground
macro node_str(s)
    v=NgHerb.getrealvec(s).*u"V"
    vmax=abs(maximum(v))
    for u in (u"kV",u"V",u"mV",u"μV",u"nV",u"pV")
        if vmax >= 1*u
            return uconvert.(u,v)
        end
    end
    return v
end


# magnitude"" retrieves the complex magnitude of the indicated vector
macro magnitude_str(s)
    NgHerb.getmagnitudevec(s)
end

# dB"" retrieves a magnitude vector and converts to dB20
macro dB_str(s)
    20.0 .* log10.(NgHerb.getmagnitudevec(s)).*u"dB"
end

# phase"" retrieves a phase vector and converts to degrees
macro phase_str(s)
    (180/π).*NgHerb.getphasevec(s).*u"°"
end

# vec"" returns a vector, possibly complex 
macro vec_str(s)
    NgHerb.getvec(s)
end




export @ng_str, @real_str, @imag_str, @node_str, @i_str, @magnitude_str, @dB_str, @phase_str, @vec_str


export @table
export @pwl_str




end
