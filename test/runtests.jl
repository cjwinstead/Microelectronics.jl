ENV["GKSwstype"] = "100"        # headless plotting with GR (needed on CI)

using Microelectronics
using Test

be_quiet()                      # keep ngspice's own messages out of the test log

#================ Helpers shared by the test files ================#

"Collapse runs of whitespace, so tests don't depend on column alignment."
tstr(s) = strip(replace(string(s), r"\s+" => " "))

"Run `f()` with stdout discarded; ngspice prints a lot."
quietly(f) = redirect_stdout(f, devnull)

"Run `f()` and return everything it printed to stdout."
function captured(f)
    mktemp() do path, io
        redirect_stdout(f, io)
        close(io)
        read(path, String)
    end
end

"Build a netlist from `sources` and `components`, load it, and run an analysis."
function simulate_circuit(analysis; sources, components, parameters="", kw...)
    quietly() do
        build_netlist(; sources, components, parameters)
        simulate(analysis; kw...)
    end
end

"Voltage at `node` from the latest simulation, in volts (unitless Floats)."
volts(node) = ustrip.(u"V", node_voltage(node))

"Voltage at `node` at time `t` in the latest transient simulation, in volts."
function volts_at(node, t)
    ts = ustrip.(u"s", tran_time())
    volts(node)[argmin(abs.(ts .- ustrip(u"s", t)))]
end

"True if `f()` throws an exception of type `T`."
throws(T, f) = try f(); false catch e; e isa T end

#================ Tests ================#

@testset "Microelectronics.jl" begin
    include("units.jl")
    include("formatting.jl")
    include("elements.jl")
    include("string_api.jl")
    include("netlists.jl")
    include("analyses.jl")
    include("measurements.jl")
    include("plots_and_reports.jl")
end
