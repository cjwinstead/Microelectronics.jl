@testset "Measurements" begin

    @testset "measure (transient)" begin
        simulate_circuit(:tran; tstep=10u"μs", tmax=2u"ms",
                         sources=[Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")],
                         components=[Resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,1u"kΩ")])
        @test measure(:Av; in="1", out="2") ≈ 0.5 rtol=1e-4
        Gm = measure(:Gm; in="1", out="V1")               # i(V1) / v(1), peak to peak
        @test Gm ≈ 0.5u"mS" rtol=1e-4
        @test dimension(Gm) == dimension(u"A/V")
        slew = measure(:slew; node="1")
        @test slew ≈ 2π*1u"kHz"*1u"V" rtol=0.01           # max slope of A·sin(2πft)
        @test unit(slew) == u"V/μs"
    end

    @testset "measure (AC cutoff)" begin
        simulate_circuit(:ac; start=1u"Hz", stop=100u"kHz", steps=20,
                         sources=[Vac("V1",1,0)],
                         components=[Resistor("R1",1,2,1u"kΩ"), Capacitor("C1",2,0,1u"μF")])
        @test measure(:cutoff; name="2") ≈ 159.155u"Hz" rtol=0.01
        @test unit(measure(:cutoff; name="2")) == u"Hz"
    end

    @testset "FFT and distortion" begin
        # a pure sine has (almost) no harmonic distortion
        quietly(() -> build_netlist(; sources=[Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")],
                                    components=[Resistor("RL",1,0,1u"kΩ")]))
        s = quietly(() -> fft("1"; frequency=1u"kHz"))
        @test keys(s) ⊇ (:fundamental, :f, :mag, :phase, :db, :t, :v)
        Δf = s.f[2] - s.f[1]                               # FFT bin spacing
        @test abs(s.f[argmax(s.mag)] - 1000) < Δf          # spectral peak at the fundamental
        d = distortion(s)
        @test length(d.harmonics) == 10
        @test d.thd < 1e-3
        # harmonics are evaluated exactly at k·f₀, independent of the FFT bins
        @test d.harmonics[1][1] ≈ 1 rtol=0.005               # 1 V amplitude
        @test d.harmonics[1][2] ≈ -π/2 atol=0.01             # a sine lags a cosine by 90°
        @test all(h -> h[1] < 1e-3, d.harmonics[2:end])
        @test length(distortion(s; nh=3).harmonics) == 3
        @test length(distortion(s; nh=100).harmonics) == 24  # capped below Nyquist (D=50)

        S = quietly(() -> Spectrum("1", 1u"kHz"))
        @test S isa Spectrum
        @test S.fundamental == 1u"kHz"
        @test unit(S.f[1]) == u"Hz"
        @test unit(S.mag[1]) == u"V"
        @test S.thd < 1e-3
        @test S.harmonics[1][1] ≈ 1u"V" rtol=0.005
        @test length(quietly(() -> Spectrum("1", 1u"kHz"; N=10, D=20)).harmonics) == 9

        # clipping by two anti-parallel diodes adds odd harmonics
        quietly(() -> build_netlist(; sources=[Vsin("V1",1,0;amplitude=2u"V",frequency=1u"kHz")],
                                    components=[Resistor("R1",1,2,1u"kΩ"),
                                                Diode("D1",2,0,"D1N914"), Diode("D2",0,2,"D1N914")]))
        S = quietly(() -> Spectrum("2", 1u"kHz"))
        @test 0.1 < S.thd < 0.5
        h = [abs(ustrip(x[1])) for x in S.harmonics]
        @test h[3] > 10*h[2]                               # symmetric clipping: odd ≫ even
    end
end
