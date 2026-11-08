#=
@table returns a ParameterTable. It is displayed as a report table, while
OrderedDicts (and other dictionaries) keep their usual display, so that
loading Microelectronics changes nothing for other packages.
Shared by the main and dev branches.
=#
const OrderedDict = Microelectronics.OrderedDict

@testset "ParameterTable" begin
    plain(x) = sprint(show, MIME"text/plain"(), x)

    @testset "Other dictionaries are left alone" begin
        for f in (show, print)
            @test !any(m -> m.module === Microelectronics,
                       methods(f, (IO, MIME"text/plain", OrderedDict)))
        end
        @test !any(m -> m.module === Microelectronics, methods(print, (IO, OrderedDict)))
        @test !any(m -> m.module === Microelectronics, methods(print, (OrderedDict,)))
        d = OrderedDict("a" => 1)
        @test repr(d) == "OrderedDict(\"a\" => 1)" || repr(d) == "OrderedDict{String, Int64}(\"a\" => 1)"
        @test startswith(plain(d), "OrderedDict")
        @test string(d) == repr(d)
    end

    @testset "Dictionary behavior" begin
        R = 1u"kΩ"; C = 1u"μF"
        t = @table R C fc=Hz(1/(R*C)) note="text"
        @test t isa ParameterTable
        @test t isa AbstractDict{String,Any}
        @test collect(keys(t)) == ["R", "C", "fc", "note"]          # order is kept
        @test collect(values(t))[1] == R
        @test t["R"] == R && haskey(t, "C") && !haskey(t, "x")
        @test get(t, "x", 0) == 0
        @test length(t) == 4
        @test first(t) == ("R" => R)
        t["Vs"] = 1u"V"                                             # add a value of any type
        @test last(collect(keys(t))) == "Vs"
        delete!(t, "note")
        @test !haskey(t, "note")
        @test copy(t) == t && copy(t) isa ParameterTable
        @test t == OrderedDict{String,Any}(k => v for (k, v) in t)
        @test (@table a=1 b=2) == ParameterTable("a" => 1, "b" => 2)
        @test ParameterTable(:a => 1)["a"] == 1                     # names become strings
        @test isempty(ParameterTable())
    end

    @testset "Displayed as a report table" begin
        t = @table a=1u"ms" b=2
        tbl = sprint(io -> report(io, t))
        @test startswith(tbl, "| Parameter")
        @test plain(t) == tbl
        @test sprint(print, t) == tbl
        @test string(t) == tbl
        @test "$t" == tbl
        @test startswith(repr(t), "ParameterTable(")
        # report works the same for any dictionary
        @test sprint(io -> report(io, OrderedDict("a" => 1u"ms", "b" => 2))) == tbl
    end

    @testset "Used for netlist parameters" begin
        t = @table R=1u"kΩ" n=2
        @test [p.name for p in Parameter(t)] == ["R", "n"]
        @test convert(Vector{Parameter}, t) isa Vector{Parameter}
        @test strip(String(spice_parameters(t, "n"))) == ".param     n=2"
        @test count(==('\n'), spice_parameters(t)) == 2
        @test occursin("=1000", string(Netlist(parameters=t)))
        @test count(==('\n'), spice_parameters(OrderedDict("a" => 1))) == 1
    end
end
