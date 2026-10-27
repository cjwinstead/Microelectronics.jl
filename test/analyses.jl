@testset "Simulations" begin
    divider = (sources=[Vdc("V1",1,0,1u"V")],
               components=[Resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,1u"kΩ")])
    rc_lowpass = (sources=[Vdc("V1",1,0,0u"V";ac=1)],
                  components=[Resistor("R1",1,2,1u"kΩ"), Capacitor("C1",2,0,1u"μF")])
    fc = 1/(2π*1e3*1e-6)                  # 159.15 Hz

    @testset "Operating point" begin
        simulate_circuit(:op; divider...)
        @test volts("1") ≈ [1.0]
        @test volts("2") ≈ [0.5]
        @test node"2" ≈ [500u"mV"]
        @test unit(node"2"[1]) == u"mV"                   # scaled for readability
        @test i"V1" ≈ [-0.5e-3]                           # SPICE: current into the + terminal
        @test nodes(1,2) ≈ [[1.0],[0.5]]

        # a current source drives 1 mA into node 1 (from n+ through the source to n-)
        simulate_circuit(:op; sources=[Idc("I1",0,1,1u"mA")], components=[Resistor("R1",1,0,1u"kΩ")])
        @test volts("1") ≈ [1.0]
    end

    @testset "DC sweep" begin
        simulate_circuit(:dc; device="v1", start=0, stop=1, step=0.5,
                         sources=[vsin("V1",1,0;dc=0,ac=1)],
                         components=[resistor("R1",1,2,1u"kΩ"), capacitor("C1",2,0,1u"μF")])
        @test dc_sweep() == [0,0.5,1]u"V"
        @test node"1" == [0,0.5,1]u"V"
        @test i"v1" == [0.0,0.0,0.0]                      # capacitor: no DC current

        simulate_circuit(:dc; device="v1", start=0, stop=2, step=1, divider...)
        @test volts("2") ≈ [0.0, 0.5, 1.0]
        @test i"v1" ≈ [0.0, -0.5e-3, -1e-3]

        simulate_circuit(:dc; device="i1", start=0, stop=2e-3, step=1e-3,
                         sources=[Idc("I1",0,1,0)], components=[Resistor("R1",1,0,1u"kΩ")])
        @test dc_sweep() ≈ [0.0, 1e-3, 2e-3]u"A"          # sweeping a current source
        @test volts("1") ≈ [0.0, 1.0, 2.0]

        # the swept device can be named as in the netlist, in any case
        simulate_circuit(:op; divider...)
        simulate_circuit(:dc; device="V1", start=0, stop=2, step=1, divider...)
        @test dc_sweep() == [0,1,2]u"V"
        simulate_circuit(:dc; device="R2", start=1e3, stop=3e3, step=2e3, divider...)
        @test volts("2") ≈ [0.5, 0.75]                    # sweeping a resistor
    end

    @testset "Failed analyses are reported" begin
        simulate_circuit(:op; divider...)
        # no device VX: ngspice runs nothing, and simulate must not return quietly
        @test_throws ErrorException simulate_circuit(:dc; device="VX", start=0, stop=1, step=1, divider...)
        @test analysis_kind() == :op                       # the old results are still there
        @test_throws ErrorException quietly(() -> simulate(:tran; tstep=1u"ms", tmax=-1u"ms"))
    end

    @testset "AC analysis of an RC low-pass filter" begin
        simulate_circuit(:ac; start=1u"Hz", stop=100u"kHz", steps=10, rc_lowpass...)
        f = ac_freq()
        @test f[1] ≈ 1 && f[end] ≈ 1e5
        @test length(f) == 51                             # 10 points per decade, 5 decades
        @test magnitudes(2)[1][1] ≈ 1 atol=1e-4           # passband
        @test magnitude"2" ≈ magnitudes(2)[1]
        @test ustrip.(dB"2") ≈ dB20.(magnitudes(2)[1])
        @test ustrip.(phase"2") ≈ phases(2)[1]
        # roll-off: -20 dB/decade well above cutoff (10 kHz and 100 kHz)
        H(fx) = dB20(magnitudes(2)[1][argmin(abs.(f .- fx))])
        @test H(1e5) - H(1e4) ≈ -20 atol=0.1

        # exactly at the cutoff frequency
        simulate_circuit(:ac; start=fc*u"Hz", stop=fc*u"Hz", steps=1, mode=:lin, rc_lowpass...)
        @test magnitude"2"[1] ≈ 1/sqrt(2) rtol=1e-4
        @test ustrip(dB"2"[1]) ≈ -3.0103 atol=1e-3
        @test ustrip(phase"2"[1]) ≈ -45 atol=0.01
        @test real"2"[1] ≈ 0.5 rtol=1e-4                  # H = 1/(1+j) = (1-j)/2
        @test imag"2"[1] ≈ -0.5 rtol=1e-4

        # same sweep with frequencies given in rad/s
        simulate_circuit(:ac; start=10u"rad/s", stop=1u"Mrad/s", steps=1, rc_lowpass...)
        @test ac_freq() ≈ [1.59155, 15.9155, 159.155, 1591.55, 15915.5, 159155] rtol=1e-5
        @test ustrip.(dB"2") ≈ [-0.000434, -0.04321, -3.0103, -20.0432, -40.0004, -60.0000] atol=1e-3
        @test ustrip.(phase"2") ≈ [-0.5729, -5.7106, -45.0000, -84.2894, -89.4271, -89.9427] atol=1e-3
    end

    @testset "AC sweep modes" begin
        simulate_circuit(:ac; start=1u"kHz", stop=2u"kHz", steps=3, mode=:lin, rc_lowpass...)
        @test ac_freq() ≈ [1000, 1500, 2000]
        simulate_circuit(:ac; start=1u"kHz", stop=4u"kHz", steps=1, mode=:oct, rc_lowpass...)
        @test ac_freq() ≈ [1000, 2000, 4000]
    end

    @testset "RC high-pass leads by 45° at cutoff" begin
        simulate_circuit(:ac; start=fc*u"Hz", stop=fc*u"Hz", steps=1, mode=:lin,
                         sources=[Vac("V1",1,0)],
                         components=[Capacitor("C1",1,2,1u"μF"), Resistor("R1",2,0,1u"kΩ")])
        @test ustrip(phase"2"[1]) ≈ 45 atol=0.01
        @test magnitude"2"[1] ≈ 1/sqrt(2) rtol=1e-4
    end

    @testset "Transient response of an RC circuit" begin
        τ = 1e-3                                          # 1 kΩ × 1 μF
        step = Vpwl("V1",1,0,[(0u"s",0u"V"),(1u"ns",1u"V"),(10u"ms",1u"V")])
        simulate_circuit(:tran; tstep=10u"μs", tmax=5u"ms", sources=[step],
                         components=[Resistor("R1",1,2,1u"kΩ"), Capacitor("C1",2,0,1u"μF")])
        t = tran_time()
        @test unit(t[1]) == u"ms"
        @test t[end] ≈ 5u"ms"
        @test volts_at("2", 1u"ms") ≈ 1 - exp(-1) rtol=0.01     # 63.2 % after one τ
        @test volts_at("2", 5u"ms") > 0.99
        @test issorted(volts("2"))                         # monotonic charging
    end

    @testset "Transient sources" begin
        sine = Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")
        simulate_circuit(:tran; tstep=1u"μs", tmax=2u"ms", sources=[sine],
                         components=[Resistor("RL",1,0,1u"kΩ")])
        @test volts_at("1", 0.25u"ms") ≈ 1 atol=0.01
        @test volts_at("1", 0.75u"ms") ≈ -1 atol=0.01
        @test maximum(volts("1")) ≈ 1 atol=0.01

        for src in (vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"),
                    Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"))
            simulate_circuit(:tran; tstep=1u"μs", tmax=1u"ms", sources=[src],
                             components=[resistor("RL",1,0,1u"kΩ")])
            @test volts_at("1", 0u"s")    ≈ 1.0 atol=0.01  # 90° phase: starts at the peak
            @test volts_at("1", 0.5u"ms") ≈ -1.0 atol=0.01
        end
        for src in (vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"),
                    Vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"))
            simulate_circuit(:tran; tstep=1u"μs", tmax=1u"ms", sources=[src],
                             components=[resistor("RL",1,0,1u"kΩ")])
            @test volts_at("1", 0.25u"ms") ≈ 5.0 atol=0.01 # high during the pulse
            @test volts_at("1", 0.75u"ms") ≈ 0.0 atol=0.01 # low afterwards
        end
        simulate_circuit(:tran; tstep=10u"μs", tmax=2u"ms",
                         sources=[Vpwl("V1",1,0,[(0u"s",0u"V"),(1u"ms",1u"V")])],
                         components=[Resistor("RL",1,0,1u"kΩ")])
        @test volts_at("1", 0.25u"ms") ≈ 0.25 atol=0.01   # ramp
        @test volts_at("1", 1.5u"ms") ≈ 1.0 atol=0.01     # holds the last value
    end

    @testset "Op-amp circuits (ideal_opamp model)" begin
        simulate_circuit(:op; sources=[Vdc("V1",1,0,1u"V")],
                         components=[Resistor("RI",1,2,1u"kΩ"), Resistor("RF",2,3,2u"kΩ"),
                                     Opamp("OA1",0,2,3,"ideal_opamp")])
        @test volts("3")[1] ≈ -2 rtol=1e-3                 # inverting: -RF/RI
        @test abs(volts("2")[1]) < 1e-3                    # virtual ground

        simulate_circuit(:op; sources=[Vdc("V1",1,0,1u"V")],
                         components=[Opamp("OA1",1,2,3,"ideal_opamp"),
                                     Resistor("RF",3,2,3u"kΩ"), Resistor("RI",2,0,1u"kΩ")])
        @test volts("3")[1] ≈ 4 rtol=1e-3                  # non-inverting: 1 + RF/RI

        simulate_circuit(:op; sources=[vdc("V1",1,0,1u"V")],
                         components=[opamp(name="OA1",nplus=1,nminus=2,out=2)])
        @test volts("2")[1] ≈ 1 rtol=1e-3                  # follower, string API
    end

    @testset "Controlled sources" begin
        sense = Vdc("V1",1,0,1u"V")
        simulate_circuit(:op; sources=[sense],
                         components=[Resistor("R1",1,0,1u"kΩ"), Resistor("R2",2,0,1u"kΩ"),
                                     VCVS(name="E1",nplus="2",nminus="0",control=["1","0"],gain=10)])
        @test volts("2")[1] ≈ 10

        # VCCS: current gm·v(1) flows from n+ through the source to n-, out of node 2
        simulate_circuit(:op; sources=[sense],
                         components=[Resistor("R1",1,0,1u"kΩ"), Resistor("R2",2,0,1u"kΩ"),
                                     VCCS(name="G1",nplus="2",nminus="0",control=["1","0"],gain=1u"mS")])
        @test volts("2")[1] ≈ -1

        # current-controlled sources sense the current in VS (i(VS) = -1 mA here)
        loop = [Vdc("V1",1,3,1u"V"), Vdc("VS",3,0,0u"V")]
        simulate_circuit(:op; sources=loop,
                         components=[Resistor("R1",1,0,1u"kΩ"), Resistor("R2",2,0,1u"kΩ"),
                                     CCCS(name="F1",nplus="0",nminus="2",control="VS",gain=10)])
        @test i"vs" ≈ [-1e-3]
        @test volts("2")[1] ≈ -10
        simulate_circuit(:op; sources=loop,
                         components=[Resistor("R1",1,0,1u"kΩ"), Resistor("R2",2,0,1u"kΩ"),
                                     CCVS(name="H1",nplus="2",nminus="0",control="VS",gain=1u"kΩ")])
        @test volts("2")[1] ≈ -1
    end

    @testset "Diode circuits" begin
        simulate_circuit(:op; sources=[Vdc("V1",1,0,5u"V")],
                         components=[Resistor("R1",1,2,1u"kΩ"), Diode("D1",2,0,"D1N914")])
        vd = volts("2")[1]
        @test 0.5 < vd < 1.0                               # forward biased: conducts
        @test i"V1"[1] ≈ -(5 - vd)/1e3 rtol=1e-6           # KVL around the loop

        simulate_circuit(:op; sources=[Vdc("V1",1,0,5u"V")],
                         components=[Resistor("R1",1,2,1u"kΩ"), Diode("D1",0,2,"D1N914")])
        @test volts("2")[1] ≈ 5 atol=1e-3                  # reverse biased: blocks

        # half-wave rectifier never goes (meaningfully) negative
        simulate_circuit(:tran; tstep=10u"μs", tmax=2u"ms",
                         sources=[Vsin("V1",1,0;amplitude=5u"V",frequency=1u"kHz")],
                         components=[Diode("D1",1,2,"D1N914"), Resistor("RL",2,0,1u"kΩ")])
        @test minimum(volts("2")) > -0.01
        @test maximum(volts("2")) > 3.5
    end

    @testset "Names are not case sensitive" begin
        sources = [Vsin("VIN","IN",0;amplitude=1u"V",frequency=1u"kHz",dc=1u"V",ac=1),
                   Vdc("Vsense","MID",0,0u"V")]
        components = [Resistor("R1","IN","OUT",1u"kΩ"), Resistor("R2","OUT","MID",1u"kΩ"),
                      Capacitor("C1","OUT",0,1u"μF"),
                      CCCS(name="F1",nplus="0",nminus="FOUT",control="VSENSE",gain=10),
                      Resistor("RF","FOUT",0,1u"kΩ")]
        simulate_circuit(:op; sources, components)
        for n in ("OUT","out","Out")
            @test volts(n) ≈ [0.5]
            @test Microelectronics.find_vec(n) == "out"
        end
        @test i"VIN" ≈ i"vin" ≈ [-0.5e-3]
        @test Microelectronics.find_vec("VIN") == "vin#branch"
        @test volts("FOUT") ≈ [5.0]                        # CCCS control "VSENSE" finds Vsense
        @test isvoltage("OUT") && !iscurrent("OUT")
        @test iscurrent("VIN") && !isvoltage("VIN")
        @test_throws ArgumentError Microelectronics.find_vec("nowhere")
        msg = sprint(showerror, try Microelectronics.find_vec("nowhere") catch e; e end)
        @test occursin("out", msg) && occursin("vin#branch", msg)   # lists what exists

        simulate_circuit(:dc; device="VIN", start=0, stop=2, step=1, sources, components)
        @test dc_sweep() == [0,1,2]u"V"
        @test volts("OUT") ≈ [0, 0.5, 1]

        simulate_circuit(:ac; start=10u"Hz", stop=10u"kHz", steps=5, sources, components)
        @test measure(:cutoff; name="OUT") ≈ measure(:cutoff; name="out")
        @test magnitudes("OUT") ≈ magnitudes("out")

        simulate_circuit(:tran; tstep=10u"μs", tmax=2u"ms", sources, components)
        @test measure(:Av; in="IN", out="OUT") ≈ measure(:Av; in="in", out="out")
        @test measure(:Gm; in="IN", out="VIN") ≈ measure(:Gm; in="in", out="vin")
        @test measure(:slew; node="IN") ≈ measure(:slew; node="in")
    end

    @testset "String macros read fresh results" begin
        # they expand to calls, so inside a function or loop each call sees the
        # latest simulation rather than a value captured when the code was parsed
        vout() = node"2"[1]
        results = map((1u"kΩ", 3u"kΩ")) do R2
            simulate_circuit(:op; sources=[vdc("VS",1,0,1u"V")],
                             components=[resistor("RA",1,2,1u"kΩ"), resistor("RB",2,0,R2)])
            vout()
        end
        @test results[1] ≈ 500u"mV"
        @test results[2] ≈ 750u"mV"

        quietly(() -> ng"op")                              # ng"" sends a command
        @test node"2"[1] ≈ 750u"mV"
        @test vec"2"[3] ≈ [0.75]
        @test_throws Exception node"no_such_node"
    end

    @testset "alter, then simulate again" begin
        src = Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")
        peak_slope() = maximum(abs.(diff(volts("1")) ./ diff(ustrip.(u"s", tran_time()))))
        simulate_circuit(:tran; tstep=1u"μs", tmax=2u"ms", sources=[src], components=[Resistor("RL",1,0,1u"kΩ")])
        s1 = peak_slope()
        alter(src; frequency=2u"kHz")
        simulate_circuit(:tran; tstep=1u"μs", tmax=2u"ms", sources=[src], components=[Resistor("RL",1,0,1u"kΩ")])
        @test peak_slope() / s1 ≈ 2 rtol=0.01             # slope ∝ frequency
    end
end
