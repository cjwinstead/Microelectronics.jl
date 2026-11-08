#=
Object API fixes on main (found while documenting): pulse levels in the
right order, PWL sources from tuples, sources without a waveform, models
in a netlist, and the default title.
=#
@testset "Object API fixes" begin
    flat(x) = strip(replace(string(x), r"\s+" => " "))
    @test occursin("pulse (0 3.3 ", flat(Vpulse("clk", "clk", 0; high=3.3u"V")))     # low first
    @test flat(Vpwl("r", "in", 0, [(0, 0), (1u"ms", 1u"V")])) == "Vr in 0 pwl (0 0 0.001 1 )"
    @test occursin("0.001 1", flat(Vpwl("r", "in", 0, [Point(0, 0), Point(1u"ms", 1u"V")])))
    @test flat(Vsource("sense", "a", "b")) == "Vsense a b"
    @test string(Model("dx", "D(IS=1e-14)")) == ".model dx D(IS=1e-14)"
    @test string(Model("dx", ".model dx D(IS=1e-14)")) == ".model dx D(IS=1e-14)"
    n = Netlist(includes=Include[], models=[Model("dx", "D(IS=1e-14)")])
    @test split(strip(string(n)), "\n") == ["* circuit", ".model dx D(IS=1e-14)", ".end"]
end
