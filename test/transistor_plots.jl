# Plots of MOSFET results (main branch: plot() with Plots.jl)
@testset "Transistor plots" begin
    q(f) = redirect_stdout(f, devnull)
    PlotType = Microelectronics.Plots.Plot
    labels(p) = [s[:label] for s in p.series_list]

    q(() -> (build_netlist(; sources=[Vdc("VDS","d",0,0u"V"), Vdc("VGS","g",0,0u"V")],
                             components=[NMOS("M1","d","g",0)]);
             simulate(:dc; device="VDS", start=0, stop=5, step=0.5, sweep2=("VGS", 1u"V", 3u"V", 1u"V"))))
    p = plot("M1")                                      # a family of ID-VDS curves
    @test p isa PlotType
    @test labels(p) == ["ID(m1), VGS = 1 V", "ID(m1), VGS = 2 V", "ID(m1), VGS = 3 V"]
    @test length(p.series_list[1][:x]) == 11
    @test p.series_list[3][:y][end] ≈ ustrip(u"A", device_values("M1").id[end])
    @test labels(plot("M1"; labels=["drain current"]))[3] == "drain current, VGS = 3 V"
    @test length(plot("M1", "d").subplots) == 2        # current and voltage: twin axes
    g = plot(Vector[device_values("M1").gm]; labels=["gm"])
    @test labels(g) == ["gm, VGS = 1 V", "gm, VGS = 2 V", "gm, VGS = 3 V"]
    @test g.subplots[1][:yaxis][:guide] == "[S]"

    q(() -> simulate(:dc; device="VGS", start=0, stop=3, step=0.5))
    @test length(plot("M1").series_list) == 1          # a plain sweep: one curve
    @test plot(Vector[device_values("M1").gm]) isa PlotType
    @test plot("M1").subplots[1][:xaxis][:guide] == "Sweep [V]"
end
