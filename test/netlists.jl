@testset "Netlists" begin
    lines(x) = split(strip(string(x)), "\n")
    lib = ".include $(model_library())"

    @testset "Netlist structure" begin
        @test lines(Netlist()) == ["* circuit", lib, ".end"]
        @test lines(Netlist(title="Divider", includes=[])) == ["* Divider", ".end"]
        n = Netlist(title="order", models=[Model("dx","D(IS=1e-14)")],
                    parameters=[Parameter("R",1u"kΩ")],
                    sources=[Vdc("V1",1,0,1u"V")], components=[Resistor("R1",1,0,:R)])
        @test tstr.(lines(n)) == ["* order", lib, ".model dx D(IS=1e-14)",
                                  ".param R=1000", "V1 1 0 DC 1", "R1 1 0 {R}", ".end"]
    end

    @testset "Includes and models" begin
        @test lines(Netlist(includes="my.sp"))[2] == ".include my.sp"
        @test lines(Netlist(includes=["a.sp", Include("b.sp")]))[2:3] == [".include a.sp", ".include b.sp"]
        @test isfile(model_library())
        @test string(Model("dx","D(IS=1e-14)")) == ".model dx D(IS=1e-14)"
        @test string(Model("dx",".model dx D(IS=1e-14)")) == ".model dx D(IS=1e-14)"
        @test ".include extra.sp" in lines(Netlist(models=".include extra.sp"))
    end

    @testset "Parameters in any form" begin
        params(p) = filter(l -> startswith(l, ".param"), tstr.(lines(Netlist(parameters=p))))
        @test params([Parameter("a",1)]) == [".param a=1"]
        @test params(@table a=1 b=2u"mV") == [".param a=1", ".param b=0.002"]
        @test params([("a",1), "b"=>2]) == [".param a=1", ".param b=2"]
        @test params(spice_parameters(@table a=1)) == [".param a=1"]
        @test params([spice_parameters(@table a=1), Parameter("b",2)]) == [".param a=1", ".param b=2"]
    end

    @testset "Mixing styles" begin
        n = Netlist(title="mixed", parameters=[Parameter("R",1u"kΩ")],
                    sources=[Vdc("V1",1,0,1u"V")],
                    components=[Resistor("R1",1,2,:R), resistor("R2",2,0,1u"kΩ")])
        @test tstr(n) == "* mixed $lib .param R=1000 V1 1 0 DC 1 R1 1 2 {R} R2 2 0 1000 .end"
        # nested vectors, empty strings and `nothing` are flattened away
        n2 = Netlist(components=[[resistor("R1",1,0,1)], "", nothing, [Capacitor("C1",1,0,1)]])
        @test tstr.(lines(n2))[3:4] == ["R1 1 0 1", "C1 1 0 1"]
        @test all(x -> x isa Element, n2.components)
        @test n2.components[1] isa SpiceLine
    end

    @testset "Subcircuit definitions" begin
        sub = Subcircuit(name="divider", terminals=["in","out"],
                         components=[Resistor("R1","in","out",1u"kΩ"), Resistor("R2","out",0,1u"kΩ")])
        @test tstr(sub) == ".subckt divider in out R1 in out 1000 R2 out 0 1000 .ends"
        subp = Subcircuit(name="d2", terminals=["a"], parameters=[Parameter("R",1u"kΩ")],
                          components=[Resistor("R1","a",0,:R)])
        @test occursin("+params: R=1000", string(subp))

        # define it in a netlist, instantiate it, and simulate
        n = Netlist(title="sub", models=[sub], sources=[Vdc("V1",1,0,1u"V")],
                    components=[Subckt("X1",[1,2],"divider")])
        quietly(() -> (load_netlist(n); simulate(:op)))
        @test volts("2")[1] ≈ 0.5
    end

    @testset "build_netlist" begin
        parameters = [spice_parameters(@table fs=1u"krad/s")]
        sources = [vsin(1,1,0;frequency=:fs,ac=1)]
        components = [resistor(1,1,2,1u"kΩ"), capacitor(1,2,0,1u"μF")]
        n = quietly(() -> build_netlist(;title="test circuit",parameters,sources,components))
        @test tstr(n) == "* test circuit $lib .param fs=159.155 V1 1 0 AC 1 SIN (0,0.005,{fs},0) R1 1 2 1000 C1 2 0 1e-06 .end"

        txt = quietly(() -> build_netlist("My title"; sources=[vdc("V1",1,0,1u"V")]))
        @test startswith(txt, "* My title\n")
        @test startswith(quietly(() -> build_netlist(; title="kw")), "* kw\n")
        @test startswith(quietly(() -> build_netlist()), "* circuit\n")

        txt = quietly(() -> build_netlist(; sources=[vdc("V1",1,0,1u"V")],
                                          components=[resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,3u"kΩ")]))
        @test !occursin("Any[", txt)
        quietly(() -> simulate(:op))
        @test volts("2")[1] ≈ 0.75
    end

    @testset "Parameterized circuits" begin
        # the same netlist evaluated with two parameter values
        for (R2, expected) in ((1u"kΩ", 0.5), (3u"kΩ", 0.75))
            simulate_circuit(:op; parameters=spice_parameters(@table R2),
                             sources=[Vdc("V1",1,0,1u"V")],
                             components=[Resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,:R2)])
            @test volts("2")[1] ≈ expected
        end
    end
end
