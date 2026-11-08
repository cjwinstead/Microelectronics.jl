#=
Parameter lists for Netlist, Subcircuit and element constructors: every
constructor takes the same forms, names must be unique (ignoring case), and
subcircuit instances may only set parameters their subcircuit declares.
Shared by the main and dev branches.
=#
@testset "Parameter lists" begin
    flat(x) = strip(replace(string(x), r"\s+" => " "))
    params(n) = filter(l -> startswith(l, ".param"), flat.(split(string(n), "\n")))
    names(ps) = [p.name for p in ps]
    run_op(n) = redirect_stdout(devnull) do
        load_netlist(n); simulate(:op)
    end
    v2() = ustrip(u"V", node"2"[1])

    @testset "Accepted forms" begin
        forms = Any[[Parameter("R",1u"kΩ"), Parameter("n",2)],
                    (@table R=1u"kΩ" n=2),
                    (R=1u"kΩ", n=2),
                    ["R"=>1u"kΩ", "n"=>2],
                    ("R"=>1u"kΩ", "n"=>2),
                    [("R",1u"kΩ"), ("n",2)],
                    (("R",1u"kΩ"), ("n",2)),
                    [Parameter("R",1u"kΩ"), [(n=2,)]],          # nested
                    [Parameter(:R,1u"kΩ"), :n=>2]]              # symbol names
        for f in forms
            ps = parameter_list(f)
            @test ps isa Vector{Parameter}
            @test names(ps) == ["R", "n"]
            @test [p.value for p in ps] == [1u"kΩ", 2]
        end
        @test names(parameter_list(Parameter("R",1))) == ["R"]
        @test names(parameter_list("R"=>1)) == ["R"]
        @test names(parameter_list(("R",1))) == ["R"]          # one (name, value) tuple
        @test names(parameter_list(("g","{2*R}"))) == ["g"]
        @test isempty(parameter_list(nothing))
        @test isempty(parameter_list(()))
        @test isempty(parameter_list(Parameter[]))
    end

    @testset "Errors" begin
        @test_throws ArgumentError parameter_list([Parameter("R",1), Parameter("R",2)])
        @test_throws ArgumentError parameter_list((R=1, r=2))           # SPICE ignores case
        e = try parameter_list((R=1, r=2)) catch e; e end
        @test occursin("not case sensitive", e.msg)
        @test_throws ArgumentError parameter_list(42)
        @test_throws ArgumentError parameter_list(["R=1"])
        e = try parameter_list(42) catch e; e end
        @test occursin("give parameters as", e.msg)
    end

    @testset "Netlist parameters become .param lines" begin
        for f in (Parameter("R",1u"kΩ"), [Parameter("R",1u"kΩ")], (@table R=1u"kΩ"),
                  (R=1u"kΩ",), "R"=>1u"kΩ", [("R",1u"kΩ")])
            @test params(Netlist(title="t", includes=[], parameters=f)) == [".param R=1000"]
        end
        @test params(Netlist(title="t", includes=[], parameters=(a=1, b=:a))) ==
              [".param a=1", ".param b={a}"]
        @test_throws ArgumentError Netlist(parameters=(R=1, r=2))

        n = Netlist(title="p", parameters=(R2=3u"kΩ",), sources=[Vdc("V1",1,0,1u"V")],
                    components=[Resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,:R2)])
        run_op(n)
        @test v2() ≈ 0.75
    end

    @testset "Subcircuit parameters" begin
        cs = [Resistor("R1","a","b",1u"kΩ"), Resistor("R2","b",0,:Rb)]
        for f in ([Parameter("Rb",1u"kΩ")], (@table Rb=1u"kΩ"), (Rb=1u"kΩ",), "Rb"=>1u"kΩ", [("Rb",1u"kΩ")])
            s = Subcircuit(name="half", terminals=["a","b"], parameters=f, components=cs)
            @test names(s.parameters) == ["Rb"]
            @test occursin("+params: Rb=1000", string(s))
        end
        @test Subcircuit(name="s", terminals=[1,2], components=cs).terminals == ["1","2"]
        @test Subcircuit(name="s", terminals="a", components=cs).terminals == ["a"]
        @test Subcircuit("s", ["a","b"], (Rb=1,), cs).parameters[1].name == "Rb"
        @test isempty(Subcircuit(name="s", terminals=["a","b"], components=cs).parameters)
        @test_throws ArgumentError Subcircuit(name="s", terminals=["a"], parameters=(R=1, r=2), components=cs)

        # defaults, and an override from the instance
        sub = Subcircuit(name="half", terminals=["a","b"], parameters=(Rb=1u"kΩ",), components=cs)
        for (inst, expected) in ((Subckt("X1",[1,2],"half"), 0.5),
                                 (Subckt("X1",[1,2],"half",(Rb=3u"kΩ",)), 0.75),
                                 (Subckt("X1",[1,2],"half",["rb"=>3u"kΩ"]), 0.75))   # any case
            run_op(Netlist(title="sub", models=[sub], sources=[Vdc("V1",1,0,1u"V")], components=[inst]))
            @test v2() ≈ expected
        end
    end

    @testset "Instances only set declared parameters" begin
        cs = [Resistor("R1","a","b",1u"kΩ"), Resistor("R2","b",0,:Rb)]
        sub = Subcircuit(name="half", terminals=["a","b"], parameters=(Rb=1u"kΩ",), components=cs)
        plain = Subcircuit(name="plain", terminals=["a","b"], components=cs)
        @test_throws ArgumentError Netlist(models=[sub], components=[Subckt("X1",[1,2],"half",(Rx=1,))])
        e = try Netlist(models=[sub], components=[Subckt("X1",[1,2],"half",(Rx=1,))]) catch e; e end
        @test occursin("X1 sets parameter Rx", e.msg) && occursin("only has Rb", e.msg)
        @test_throws ArgumentError Netlist(models=[plain], components=[Subckt("X1",[1,2],"plain",(Rb=1,))])
        # instances inside another subcircuit are checked too
        outer = Subcircuit(name="outer", terminals=["p","q"],
                           components=[Subckt("X9",["p","q"],"half",(Rq=1,))])
        @test_throws ArgumentError Netlist(models=[sub, outer], components=[Subckt("X1",[1,2],"outer")])
        # subcircuits from include files are not known, so not checked
        @test Netlist(components=[Subckt("X1",[1,2],"elsewhere",(Rx=1,))]) isa Netlist
    end

    @testset "Element parameters" begin
        @test flat(Subckt("X2",[1,2],"foo",(Av=1000,))) == "X2 1 2 foo Av=1000"
        @test flat(Subckt("X2",[1,2],"foo","Av"=>1000)) == "X2 1 2 foo Av=1000"
        @test_throws ArgumentError Subckt("X2",[1,2],"foo",(Av=1, av=2))
        m = MOSFET(name="M1",drain=1,gate=2,source=0,substrate=0,model="nm",parameters=(W=2e-6,L=1e-6))
        @test names(m.parameters) == ["W", "L"]
        @test_throws ArgumentError MOSFET("M1",1,2,0,0,"nm",[Parameter("W",1e-6)]; W=2e-6)
        # report shows instance parameters
        @test occursin("Av=1000", sprint(io -> report(io, Subckt("X2",[1,2],"foo",(Av=1000,)))))
    end
end
