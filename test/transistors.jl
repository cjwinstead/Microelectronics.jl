#=
MOSFET tests. Shared by the main and dev branches: self-contained, and
without the ng""/node"" string macros (which differ between branches).
=#
@testset "Transistors" begin
    q(f) = redirect_stdout(f, devnull)
    flat(x) = strip(replace(string(x), r"\s+" => " "))
    run(analysis; sources, components, kw...) =
        q(() -> (build_netlist(; sources, components); simulate(analysis; kw...)))
    volt(n) = Microelectronics.NgHerb.getrealvec(lowercase(n))
    # square law with channel-length modulation
    square_law(kp, WL, vov, λ, vds) = kp/2*WL*vov^2*(1 + λ*vds)

    @testset "Constructors" begin
        empty!(Microelectronics.counts)
        @test flat(NMOS("M1","d","g",0)) == "M1 d g 0 0 ald1105n"              # body = source
        @test flat(NMOS("M1","d","g","s",0)) == "M1 d g s 0 ald1105n"          # body given
        @test flat(PMOS("M2","d","g","vdd")) == "M2 d g vdd vdd ald1105p"
        @test flat(NMOS(name="M3",drain=1,gate=2,source=3)) == "M3 1 2 3 3 ald1105n"
        @test flat(PMOS(drain=1,gate=2,source=3,body=4)) == "M1 1 2 3 4 ald1105p"   # automatic name
        @test flat(NMOS("1","d","g",0)) == "M1 d g 0 0 ald1105n"               # prefix added once
        @test flat(NMOS("M5","d","g",0; model="CD4007N")) == "M5 d g 0 0 CD4007N"
        @test flat(NMOS("M1","d","g",0; W=60u"μm", L=10u"μm", M=2)) ==
              "M1 d g 0 0 ald1105n W=6e-05 L=1e-05 M=2"
        @test flat(NMOS("M1","d","g",0; w=1e-6)) == "M1 d g 0 0 ald1105n W=1.0e-6"   # any case
        @test flat(NMOS("M1","d","g",0; W=:Wn)) == "M1 d g 0 0 ald1105n W={Wn}"      # a parameter
        @test_throws ArgumentError NMOS("M1","d","g",0; width=1e-6)                  # typo
        @test_throws ArgumentError NMOS("M1","d",3u"V",0)                            # value as a node
        @test NMOS("M1","d","g",0).species == "nmos"
        @test PMOS("M1","d","g",0).species == "pmos"

        @test flat(MOSFET("M1","d","g","s","b","ald1105n")) == "M1 d g s b ald1105n"
        @test flat(MOSFET("M1","d","g","s","b","ald1105n",[Parameter("W",20u"μm")])) ==
              "M1 d g s b ald1105n W=2e-05"
        @test flat(MOSFET("M1","d","g","s","b","ald1105n"; L=10u"μm")) == "M1 d g s b ald1105n L=1e-05"
        @test flat(MOSFET(name="M1",drain="d",gate="g",source="s",substrate="b",model="m")) == "M1 d g s b m"
        @test flat(MOSFET(name="M1",drain="d",gate="g",source="s",body="b",model="m")) == "M1 d g s b m"
        @test_throws ArgumentError MOSFET(name="M1",drain="d",gate="g",source="s",model="m")  # no body

        # the string form writes sizes only when given
        @test flat(mosfet("M1","d","g",0,0)) == "M1 d g 0 0 ald1105n"
        @test flat(mosfet("1","d","g",0,0,"CD4007N")) == "M1 d g 0 0 CD4007N"
        @test flat(mosfet("M1","d","g",0,0,"CD4007N"; W=60e-6, L=10e-6)) == "M1 d g 0 0 CD4007N W=6.0e-5 L=1.0e-5"
        @test mosfet("M1","d","g",0,0) isa String

        @test NMOS("M1","d","g",0)["gm"] == "@m1[gm]"
        @test Resistor("R1",1,2,1)["i"] == "@r1[i]"
    end

    @testset "Square-law currents" begin
        # NMOS in saturation: VGS = 3 V, VDS = 5 V, Kp = 225 μA/V², W/L = 2, λ = 0.029
        run(:op; sources=[Vdc("VDS","d",0,5u"V"), Vdc("VGS","g",0,3u"V")],
                 components=[NMOS("M1","d","g",0)])
        v = device_values("M1")
        @test v.id ≈ square_law(225e-6, 2, 2.3, 0.029, 5)*u"A" rtol=1e-4
        @test v.gm ≈ 225e-6*2*2.3*(1 + 0.029*5)*u"S" rtol=1e-4         # Kp·(W/L)·Vov·(1+λVDS)
        @test v.gds ≈ 225e-6/2*2*2.3^2*0.029*u"S" rtol=1e-3             # λ·ID0
        @test (v.vgs, v.vds, v.vbs) == (3.0u"V", 5.0u"V", 0.0u"V")
        @test v.vth ≈ 0.7u"V" rtol=1e-6
        @test v.vdsat ≈ 2.3u"V" rtol=1e-6
        @test v.region == :saturation
        @test unit(v.id) == u"A" && unit(v.gm) == u"S"

        # the model's own size applies when none is given: CD4007N is W/L = 30/10
        run(:op; sources=[Vdc("VDS","d",0,5u"V"), Vdc("VGS","g",0,5u"V")],
                 components=[NMOS("M1","d","g",0; model="CD4007N")])
        @test device_values("M1").id ≈ square_law(111e-6, 3, 3.0, 0.01, 5)*u"A" rtol=1e-4
        run(:op; sources=[Vdc("VDS","d",0,5u"V"), Vdc("VGS","g",0,5u"V")],
                 components=[mosfet("M1","d","g",0,0,"CD4007N")])
        @test device_values("M1").id ≈ square_law(111e-6, 3, 3.0, 0.01, 5)*u"A" rtol=1e-4
        run(:op; sources=[Vdc("VDS","d",0,5u"V"), Vdc("VGS","g",0,5u"V")],
                 components=[NMOS("M1","d","g",0; model="CD4007N", W=60u"μm", M=2)])
        @test device_values("M1").id ≈ square_law(111e-6, 12, 3.0, 0.01, 5)*u"A" rtol=1e-4
    end

    @testset "PMOS signs follow the circuit" begin
        # source and body at 5 V, gate at 2 V, drain at 1 V: VGS = -3 V, VDS = -4 V
        run(:op; sources=[Vdc("VDD","s",0,5u"V"), Vdc("VG","g",0,2u"V"), Vdc("VD","d",0,1u"V")],
                 components=[PMOS("M1","d","g","s")])
        v = device_values("M1")
        @test (v.vgs, v.vds, v.vbs) == (-3.0u"V", -4.0u"V", 0.0u"V")
        @test v.vth ≈ -0.7u"V" rtol=1e-6
        @test v.vdsat ≈ -2.3u"V" rtol=1e-6                              # vgs - vth
        @test v.id ≈ -square_law(100e-6, 2, 2.3, 0.0304, 4)*u"A" rtol=1e-4   # current leaves the drain
        @test v.gm > 0u"S" && v.gds > 0u"S"
        @test v.region == :saturation
        # the drain current read as a signal has the same sign
        d = Microelectronics.signal_data(Microelectronics.find_vec("M1"))
        @test d[1] == "current" && d[2][1] ≈ ustrip(u"A", v.id)
    end

    @testset "Regions and body effect" begin
        circuit(vg, vd; body=0) = run(:op; sources=[Vdc("VD","d",0,vd*u"V"), Vdc("VG","g",0,vg*u"V"), Vdc("VB","b",0,body*u"V")],
                                           components=[NMOS("M1","d","g",0,"b")])
        circuit(0.5, 5);  @test device_values("M1").region == :cutoff
        circuit(3, 0.5);  @test device_values("M1").region == :triode
        circuit(3, 5);    @test device_values("M1").region == :saturation
        circuit(3, 5; body=-2)
        v = device_values("M1")
        @test v.vbs == -2.0u"V"
        @test v.vth > 0.9u"V"                                           # body effect raises vth
        @test v.gmbs > 0u"S"
    end

    @testset "Drain current as a signal" begin
        run(:op; sources=[Vdc("VDS","d",0,5u"V"), Vdc("VGS","g",0,3u"V")],
                 components=[NMOS("M1","d","g",0)])
        @test Microelectronics.find_vec("M1") == "@m1[id]"
        @test Microelectronics.find_vec("m1") == "@m1[id]"
        @test iscurrent("M1") && !isvoltage("M1")
        @test Microelectronics.signal_label("@m1[id]") == "ID(m1)"
        @test_throws ArgumentError Microelectronics.find_vec("M1"; branch=false)
        msg = sprint(showerror, try Microelectronics.find_vec("M9") catch e; e end)
        @test occursin("m1", msg)                                       # lists the MOSFETs
        @test_throws ArgumentError device_values("M9")
    end

    @testset "DC sweeps" begin
        # source names as written in the netlist (ngspice needs lowercase)
        run(:dc; device="VGS", start=0, stop=3, step=0.5,
                 sources=[Vdc("VDS","d",0,5u"V"), Vdc("VGS","g",0,0u"V")],
                 components=[NMOS("M1","d","g",0)])
        v = device_values("M1")
        @test length(v.id) == 7
        @test v.region[1:2] == [:cutoff, :cutoff]                        # VGS = 0, 0.5 V
        @test v.region[end] == :saturation
        @test v.id[end] ≈ square_law(225e-6, 2, 2.3, 0.029, 5)*u"A" rtol=1e-4
        @test sweep_curves(7) == [(1:7, "")]                             # a single curve

        # nested sweep: one ID-VDS curve per VGS
        run(:dc; device="VDS", start=0, stop=5, step=0.5, sweep2=("VGS", 1u"V", 3u"V", 1u"V"),
                 sources=[Vdc("VDS","d",0,0u"V"), Vdc("VGS","g",0,0u"V")],
                 components=[NMOS("M1","d","g",0)])
        curves = sweep_curves(33)
        @test length(curves) == 3
        @test [c[1] for c in curves] == [1:11, 12:22, 23:33]
        @test [c[2] for c in curves] == ["VGS = 1 V", "VGS = 2 V", "VGS = 3 V"]
        id = device_values("M1").id
        for (vgs, (idx, _)) in zip(1:3, curves)
            @test id[idx][end] ≈ square_law(225e-6, 2, vgs - 0.7, 0.029, 5)*u"A" rtol=1e-4
        end
        @test sweep_curves(5) == [(1:5, "")]                             # wrong length: no split
        run(:dc; device="VDS", start=0, stop=5, step=0.5, sweep2=(device="vgs", start=1, stop=2, step=1),
                 sources=[Vdc("VDS","d",0,0u"V"), Vdc("VGS","g",0,0u"V")],
                 components=[NMOS("M1","d","g",0)])
        @test [c[2] for c in sweep_curves(22)] == ["vgs = 1 V", "vgs = 2 V"]
        xs, ys, ls = Microelectronics.curve_series(1:22, [collect(1:22)], ["ID"])
        @test ls == ["ID, vgs = 1 V", "ID, vgs = 2 V"] && ys[2] == 12:22
        @test_throws ArgumentError simulate(:dc; device="VDS", start=0, stop=1, step=1, sweep2=("VGS", 1))

        # a plain sweep afterwards is a single curve again
        run(:dc; device="VDS", start=0, stop=5, step=1,
                 sources=[Vdc("VDS","d",0,0u"V"), Vdc("VGS","g",0,3u"V")],
                 components=[NMOS("M1","d","g",0)])
        @test length(sweep_curves(6)) == 1
    end

    @testset "Transient and subcircuits" begin
        # CMOS inverter driven by a slow ramp: the output swings rail to rail
        run(:tran; tstep=10u"μs", tmax=1u"ms",
                 sources=[vdc("VDD","vdd",0,5u"V"), vpwl("VIN","in",0;points=[(0u"s",0u"V"),(1u"ms",5u"V")])],   # strings: main can't mix styles in one vector
                 components=[NMOS("MN","out","in",0), PMOS("MP","out","in","vdd")])
        out = volt("out")
        @test out[1] ≈ 5 atol=0.01
        @test out[end] ≈ 0 atol=0.01
        n, p = device_values("MN"), device_values("MP")
        @test length(n.id) == length(out)
        # the same current flows through both, apart from the small capacitive
        # currents while the output switches
        @test maximum(abs.(n.id .+ p.id)) < 0.01*maximum(abs.(n.id))
        @test maximum(abs.(n.id)) > 10u"μA"                             # crossover current

        # MOSFETs inside a subcircuit definition aren't top-level devices
        empty!(Microelectronics.LOADED_MOSFETS)
        Microelectronics.register_mosfets("""
            * title line starting with an m: mosfet test
            .subckt inv in out vdd
            MN out in 0 0 ald1105n
            .ends
            M7 d g 0 0 ald1105n W=1u
            """)
        @test collect(keys(Microelectronics.LOADED_MOSFETS)) == ["m7"]
        @test Microelectronics.LOADED_MOSFETS["m7"] == ("d", "g", "0", "0")
    end
end
