@testset "Plots and reports" begin
    PlotType = Microelectronics.Plots.Plot

    @testset "Plots" begin
        simulate_circuit(:tran; tstep=10u"μs", tmax=2u"ms",
                         sources=[Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")],
                         components=[Resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,1u"kΩ")])
        p = plot("1","2")
        @test p isa PlotType
        @test length(p.series_list) == 2
        @test plot(1,2) isa PlotType                       # node numbers work too
        @test plot([node"1", node"2"]) isa PlotType
        @test plot("2","v1") isa PlotType                  # voltage and current, twin axes
        @test Microelectronics.simxlabel() == "Time [ms]"

        simulate_circuit(:ac; start=1u"Hz", stop=100u"kHz", steps=10,
                         sources=[Vac("V1",1,0)],
                         components=[Resistor("R1",1,2,1u"kΩ"), Capacitor("C1",2,0,1u"μF")])
        b = bode(2)
        @test b isa PlotType
        @test length(b.subplots) == 2                      # magnitude and phase
        @test bode(1,2) isa PlotType
        @test Microelectronics.simxlabel() == "Frequency [Hz]"

        quietly(() -> build_netlist(; sources=[Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")],
                                    components=[Resistor("RL",1,0,1u"kΩ")]))
        @test plot(quietly(() -> Spectrum("1", 1u"kHz"))) isa PlotType

        # Known bugs: names are matched case-sensitively against ngspice's
        # lowercase vector names, and misuse fails with internal errors.
        simulate_circuit(:ac; start=1u"Hz", stop=1u"kHz", steps=5,
                         sources=[Vac("V1",1,0)], components=[Resistor("R1",1,0,1u"kΩ")])
        @test_broken !throws(Exception, () -> bode("1","V1"))
        @test_broken throws(ArgumentError, () -> plot("no_such_node"))
        simulate_circuit(:op; sources=[Vdc("V1",1,0,1u"V")], components=[Resistor("R1",1,0,1u"kΩ")])
        @test_broken throws(ArgumentError, () -> bode(1))  # not an AC analysis
    end

    @testset "Reports and display" begin
        t = sprint(io -> report(io, @table R=1500u"Ω" C=4.7e-9u"F" note="text"))
        @test startswith(t, "| Parameter  |  Value        | Unit        |")
        @test occursin(r"\|R\s+\|\s+1.5\|\s+kΩ\|", t)          # scaled to kΩ
        @test occursin(r"\|C\s+\|\s+4.7\|\s+nF\|", t)
        @test occursin("text", t)
        @test captured(() -> report(@table a=1)) == sprint(io -> report(io, @table a=1))
        @test captured(() -> report((a=1u"V",))) == sprint(io -> report(io, @table a=1u"V"))

        @test captured(() -> report("hi\nthere")) == "-----\nhi\nthere\n-----\n"

        n = Netlist(title="shown", sources=[Vdc("V1",1,0,1u"V")], components=[Resistor("R1",1,0,1)])
        r = sprint(io -> report(io, n))
        @test occursin("title: shown", r) && occursin("sources:", r) && occursin("1: V1", r)
        @test sprint(io -> show(io, MIME"text/plain"(), n)) == r

        s = sprint(io -> show(io, MIME"text/plain"(), Vsin("V1",1,0)))
        @test occursin("vsource V1", s) && occursin("Waveforms:", s) && occursin("SIN", s)

        c = sprint(io -> report(io, MOSFET("M1",1,2,0,0,"nmos",[Parameter("W",1e-6)])))
        @test occursin("mosfet M1", c) && occursin("params: W=1.0e-6", c)

        sub = Subcircuit(name="d", terminals=["a"], components=[Resistor("R1","a",0,1)])
        @test occursin("SUBCIRCUIT", sprint(io -> report(io, sub)))
        @test occursin("dc waveform", sprint(io -> show(io, MIME"text/plain"(), Waveform(:dc,1))))
        @test sprint(print, Element[Resistor("R1",1,2,1), Capacitor("C1",2,0,1)]) ==
              "R1    1     2     1\nC1    2     0     1\n"
    end
end
