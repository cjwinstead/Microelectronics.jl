#=
SPICE text and string display. Shared by the main and dev branches.
Microelectronics must not change how ordinary strings are shown: Julia's
precompiler quotes package names with repr(), so a show(::IO, ::String)
method here broke the precompilation of other packages' extensions.
=#
@testset "SPICE text" begin
    q(f) = redirect_stdout(f, devnull)
    shown(x) = sprint(show, MIME"text/plain"(), x)

    @testset "Strings are left alone" begin
        @test repr("abc") == "\"abc\""
        @test repr("a\nb") == "\"a\\nb\""
        @test sprint(show, ["a", "b"]) == "[\"a\", \"b\"]"
        @test string(["a", "b"]) == "[\"a\", \"b\"]"
        @test occursin("\"a\"", shown(["a", "b"]))
        # no show/print methods for String or Vector{String} from this package
        for (f, sig) in ((show, (IO, String)), (show, (IO, MIME"text/plain", Vector{String})),
                         (print, (IO, Vector{String})), (print, (IO, String)))
            @test all(m -> parentmodule(m) !== Microelectronics, methods(f, sig))
        end
    end

    @testset "SpiceText behaves like a string" begin
        r = resistor("R1",1,2,1u"kΩ")
        @test r isa SpiceText && r isa AbstractString
        @test repr(r) == repr(String(r))                   # repr quotes it
        @test r == String(r) && String(r) == r
        @test replace(r, r"\s+" => " ") == "R1 1 2 1000"
        @test split(r)[1] == "R1" && occursin("1000", r) && startswith(r, "R1")
        @test "x $r y" == "x $(String(r)) y" && r * "!" == String(r) * "!"
        @test Dict(String(r) => 1)[r] == 1                 # hashes like the String
        @test length(r) == length(String(r)) && r[1:2] == "R1"
        @test shown(r) == String(r)                        # displayed without quotes
        @test mosfet("M1","d","g",0,0) isa SpiceText
        @test vsin("V1",1,0) isa SpiceText
        @test opamp(; name="A1", nplus=1, nminus=2, out=3) isa SpiceText
        @test dependent_source(:vcvs; name="E1", nplus=1, nminus=0, control=[2,0], gain=2) isa SpiceText
        p = spice_parameters(@table a=1 b=2u"V")
        @test p isa SpiceText
        @test split(shown(p), "\n") == strip.(split(chomp(String(p)), "\n"), Ref(['\n']))   # one line each
    end

    @testset "Netlists display one line per row" begin
        v = [resistor("R1",1,2,1u"kΩ"), capacitor("C1",2,0,1u"μF")]
        @test v isa Vector{SpiceText}
        @test shown(v) == chomp(String(v[1])) * "\n" * chomp(String(v[2]))
        @test "$v" == chomp(String(v[1])) * "\n" * chomp(String(v[2])) * "\n"   # interpolates as lines
        n = q(() -> build_netlist(; title="t", sources=[vdc("V1",1,0,1u"V")], components=v))
        @test n isa SpiceText
        @test startswith(shown(n), "* t\n") && !occursin('"', shown(n))
        @test occursin(r"R1\s+1\s+2\s+1000\s*\nC1", n)                 # vectors: one item per line
        q(() -> simulate(:op))
        @test Microelectronics.NgHerb.getrealvec("2")[1] ≈ 1
        # vectors of plain Strings work too
        n2 = q(() -> build_netlist(; sources=["V1 1 0 DC 1"], components=["R1 1 2 1k", "R2 2 0 1k"]))
        @test occursin("R1 1 2 1k\nR2 2 0 1k", n2)
        q(() -> simulate(:op))
        @test Microelectronics.NgHerb.getrealvec("2")[1] ≈ 0.5
    end
    @testset "Sine phase" begin
        # SPICE's SIN(VO VA FREQ TD THETA PHASE): the phase goes sixth, in degrees
        w(; kw...) = strip(sprint(print, Waveform(:sin; kw...)))
        @test w() == "sin (0 0.005 1000 0 )"                    # no phase: as before
        @test w(phase=90u"°") == "sin (0 0.005 1000 0 0 90 )"
        @test w(phase=π/2*u"rad") == "sin (0 0.005 1000 0 0 90 )"
        @test w(phase=-45) == "sin (0 0.005 1000 0 0 -45 )"
        @test sin_string(0, 1, 50, 0) == " SIN (0,1,50,0) "
        @test sin_string(0, 1, 50, 30u"°") == " SIN (0,1,50,0,0,30) "
        # alter sets every value it is given, not only the first
        s = Vsin("V1", 1, 0; amplitude=1u"V", frequency=1u"kHz")
        alter(s; amplitude=2u"V", phase=45u"°")
        @test s.waveforms[1].parameters["amplitude"] == 2u"V"
        @test s.waveforms[1].parameters["phase"] == 45u"°"
    end
end
