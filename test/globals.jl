#=
Global nets (.global). Shared by the main and dev branches: self-contained,
and without the string macros.
=#
@testset "Global nets" begin
    q(f) = redirect_stdout(f, devnull)
    volt(n) = Microelectronics.NgHerb.getrealvec(n)[1]
    lines(x) = strip.(split(strip(string(x)), "\n"))

    @testset "Netlist and build_netlist write .global" begin
        @test lines(Netlist(title="t", includes=[], globals=["vdd"])) == ["* t", ".global vdd", ".end"]
        @test lines(Netlist(title="t", includes=[], globals=["vdd", :vss]))[2] == ".global vdd vss"
        @test lines(Netlist(title="t", includes=[], globals="vdd"))[2] == ".global vdd"   # a single name
        @test lines(Netlist(title="t", includes=[], globals=["vdd", 0, "vdd"]))[2] == ".global vdd"  # ground, duplicates dropped
        @test lines(Netlist(title="t", includes=[])) == ["* t", ".end"]                # none: no line
        @test Netlist(title="t", globals=[:vdd, 5]).globals == ["vdd", "5"]
        @test_throws ArgumentError Netlist(globals=[5u"V"])
        # the global line comes before subcircuit definitions
        inv = Subcircuit(name="inv", terminals=["in","out"], components=[NMOS("MN","out","in",0)])
        l = lines(Netlist(title="t", includes=[], models=[inv], globals=["vdd"]))
        @test findfirst(==(".global vdd"), l) < findfirst(startswith(".subckt"), l)
        @test occursin("globals", sprint(io -> report(io, Netlist(globals=["vdd"]))))

        txt = q(() -> build_netlist(; title="g", globals=["vdd","vss"]))
        @test lines(txt)[2] == ".global vdd vss"
        @test !occursin(".global", q(() -> build_netlist(; title="g")))
    end

    @testset "Subcircuits reach global nets" begin
        # a CMOS inverter whose supply is the global net vdd, not a terminal
        inv = Subcircuit(name="inv", terminals=["in","out"],
                         components=[NMOS("MN","out","in",0), PMOS("MP","out","in","vdd")])
        circuit(globals, vin) = Netlist(title="two inverters", models=[inv], globals=globals,
                                        sources=[Vdc("VDD","vdd",0,5u"V"), Vdc("VIN","a",0,vin*u"V")],
                                        components=[Subckt("X1",["a","b"],"inv"), Subckt("X2",["b","c"],"inv")])
        q(() -> (load_netlist(circuit(["vdd"], 0)); simulate(:op)))
        @test volt("b") ≈ 5 atol=1e-3                      # 0 V in: first output high
        @test volt("c") ≈ 0 atol=1e-3                      # second inverts it back
        q(() -> (load_netlist(circuit(["vdd"], 5)); simulate(:op)))
        @test volt("b") ≈ 0 atol=1e-3
        @test volt("c") ≈ 5 atol=1e-3

        # without .global, vdd inside the subcircuit is a separate, unpowered net
        q(() -> (load_netlist(circuit(String[], 0)); simulate(:op)))
        @test volt("b") < 1

        # string API
        q(() -> build_netlist(; globals="vdd", models=string(inv),
                              sources=[vdc("VDD","vdd",0,5u"V"), vdc("VIN","a",0,5u"V")],
                              components=[subckt_instance(name="1", terminals=["a","b"], model="inv")]))
        q(() -> simulate(:op))
        @test volt("b") ≈ 0 atol=1e-3
    end
end
