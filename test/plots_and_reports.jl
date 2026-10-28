@testset "Plots and reports" begin
    PlotType = Plots.Plot

    @testset "Plotting signals" begin
        simulate_circuit(:tran; tstep=10u"μs", tmax=2u"ms",
                         sources=[Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")],
                         components=[Resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,1u"kΩ")])
        p = plot(signals("1","2"))
        @test p isa PlotType
        @test length(p.series_list) == 2
        @test length(p.subplots) == 1                      # voltages only: one panel
        @test p.subplots[1][:xaxis][:guide] == "Time [ms]"
        @test occursin("Voltage", p.subplots[1][:yaxis][:guide])
        @test plot(signals(1,2)) isa PlotType              # node numbers work too
        r = plot(signals("1","2"); labels=["vin" "vout"])  # user attributes win
        @test [s[:label] for s in r.series_list] == ["vin", "vout"]
        @test [s[:label] for s in p.series_list] == ["V(1)", "V(2)"]

        q = plot(signals("2","V1"))                        # a voltage and a current
        @test length(q.subplots) == 2                      # separate panels
        @test occursin("Current", q.subplots[2][:yaxis][:guide])

        simulate_circuit(:dc; device="V1", start=0, stop=2, step=1,
                         sources=[Vdc("V1",1,0,0)], components=[Resistor("R1",1,0,1u"kΩ")])
        @test plot(signals("1")).subplots[1][:xaxis][:guide] == "Sweep [V]"
    end

    @testset "Bode plots" begin
        simulate_circuit(:ac; start=1u"Hz", stop=100u"kHz", steps=10,
                         sources=[Vac("V1",1,0)],
                         components=[Resistor("R1",1,2,1u"kΩ"), Capacitor("C1",2,0,1u"μF")])
        b = bode(2)
        @test b isa PlotType
        @test length(b.subplots) == 2                      # magnitude and phase
        @test all(sp -> sp[:xaxis][:scale] == :log10, b.subplots)
        @test bode(1,2) isa PlotType
        @test bode("2","V1") isa PlotType                  # voltage and current
        d = Microelectronics.BodeData("2")
        i = argmin(abs.(d.f .- 159.155))
        @test d.dB[1][i] ≈ -3 atol=0.2                     # cutoff (nearest point)
        @test d.labels == ["V(2)"]
        @test_throws ArgumentError plot(signals("2"))      # AC results: use bode
    end

    @testset "Spectrum plots" begin
        quietly(() -> build_netlist(; sources=[Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")],
                                    components=[Resistor("RL",1,0,1u"kΩ")]))
        S = quietly(() -> Spectrum("1", 1u"kHz"))
        @test plot(S) isa PlotType
        @test xlims(plot(S; nh=5)) == (500.0, 5000.0)       # nh sets the x range
    end

    @testset "Clear errors" begin
        simulate_circuit(:ac; start=1u"Hz", stop=1u"kHz", steps=5,
                         sources=[Vac("V1",1,0)], components=[Resistor("R1",1,0,1u"kΩ")])
        @test analysis_kind() == :ac
        @test_throws ArgumentError signals("no_such_node")
        @test_throws ArgumentError bode("no_such_node")
        simulate_circuit(:op; sources=[Vdc("V1",1,0,1u"V")], components=[Resistor("R1",1,0,1u"kΩ")])
        @test analysis_kind() == :op
        @test_throws ArgumentError bode(1)                 # not an AC analysis
        @test_throws ArgumentError plot(signals(1))        # nothing to plot against
        @test_throws ArgumentError measure(:Av; in="1", out="1")
        @test_throws ArgumentError measure(:cutoff; name="1")
        msg = sprint(showerror, try bode(1) catch e; e end)
        @test occursin(":ac", msg) && occursin(":op", msg) # says what's needed and what ran
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
