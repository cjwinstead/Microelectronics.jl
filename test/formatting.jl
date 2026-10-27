@testset "SPICE formatting" begin

    @testset "sin_string" begin
        @test tstr(sin_string(0u"V",1u"V",1u"kHz"))              == "SIN (0,1,1000,0)"
        @test tstr(sin_string(2u"V",0.5u"V",1u"kHz"))            == "SIN (2,0.5,1000,0)"
        @test tstr(sin_string(0,1,1000))                         == "SIN (0,1,1000,0)"
        # angular frequency is converted to Hz
        @test tstr(sin_string(0u"V",1u"V",2π*1000u"rad/s"))      == "SIN (0,1,1000,0)"
        @test tstr(sin_string(0u"V",1u"V",:fs))                  == "SIN (0,1,{fs},0)"
        # phase goes in the 6th field (PHASE), in degrees
        @test tstr(sin_string(0u"V",1u"V",1u"kHz",90u"°"))       == "SIN (0,1,1000,0,0,90)"
        @test tstr(sin_string(0u"V",1u"V",1u"kHz",(π/2)u"rad"))  == "SIN (0,1,1000,0,0,90)"
        @test tstr(sin_string(0u"V",1u"V",1u"kHz",45))           == "SIN (0,1,1000,0,0,45)"
        @test tstr(sin_string(0u"V",1u"V",1u"kHz",:ph))          == "SIN (0,1,1000,0,0,{ph})"
        @test tstr(sin_string(0u"V",1u"V",1u"kHz",0u"°"))        == "SIN (0,1,1000,0)"
    end

    @testset "pulse_string" begin
        @test tstr(pulse_string(;)) == "PULSE (0 5 1e-08 1e-08 1e-08 4.9e-07 0.001 )"
        # initial (low) value first, then the pulsed (high) value
        @test startswith(tstr(pulse_string(;low=-1u"V",high=3u"V")), "PULSE (-1 3 ")
        @test tstr(pulse_string(;low=0,high=1,delay=0,risetime=1u"ns",falltime=2u"ns",
                                 width=1u"μs",period=2u"μs",pulses=3)) ==
              "PULSE (0 1 0 1e-09 2e-09 1e-06 2e-06 3 )"
        @test pulse_string(;pulses=nothing) == pulse_string(;)
        @test pulse_string(;name="V1",ac=1) == pulse_string(;)   # unrelated keywords ignored
        @test Microelectronics.PULSE_DEFAULTS.high == 5u"V"
    end

    @testset "pwl_string" begin
        @test tstr(pwl_string([(0,0),(1,1)])) == "PWL ( 0 0 1 1)"
        @test tstr(pwl_string([(0u"s",0u"V"),(1u"ms",2u"mV")])) == "PWL ( 0 0 0.001 0.002)"
        @test tstr(pwl_string([Point(0u"s",0u"V"),Point(1u"μs",1u"V")])) == "PWL ( 0 0 1e-06 1)"
        @test tstr(pwl_string([Point(0,0),(1u"ms",1u"mA")])) == "PWL ( 0 0 0.001 0.001)"
    end

    @testset "spice_parameters" begin
        d = @table a=1u"μA" bcd=23u"MΩ"
        @test tstr(spice_parameters(d)) == ".param a=1e-06 .param bcd=2.3e+07"
        @test tstr(spice_parameters(d,"bcd")) == ".param bcd=2.3e+07"
        @test tstr(spice_parameters([Parameter("R",1u"kΩ"),Parameter("C",:Cval)])) ==
              ".param R=1000 .param C={Cval}"
        @test count(==('\n'), spice_parameters(d)) == 2     # one line per parameter
    end

    @testset "@table" begin
        d = @table a=1u"A" b=2 c="123"
        @test collect(keys(d)) == ["a","b","c"]             # order is preserved
        @test d["a"] isa Quantity
        @test d["b"] isa Number
        @test d["c"] isa String
        @test Microelectronics.hasall(d,["a","b","c"])
        @test Microelectronics.hasany(d,["x","y","b"])
        @test !Microelectronics.hasall(d,["x","y","b"])
        @test !Microelectronics.hasany(d,["x","y","z"])

        R = 1u"kΩ"; C = 1u"μF"
        t = @table R C fc=Hz(1/(R*C))                       # variables and assignments
        @test collect(keys(t)) == ["R","C","fc"]
        @test t["R"] == 1u"kΩ"
        @test t["fc"] ≈ 159.155u"Hz" rtol=1e-5
    end

    @testset "pwl\"\"" begin
        points = pwl"""
               0s   0V
               1μs  0V
               2μs  1V
               10μs 1V
            """
        @test points == [(0u"s",0u"V"),(1u"μs",0u"V"),(2u"μs",1u"V"),(10u"μs",1u"V")]
        @test tstr(pwl_string(points)) == "PWL ( 0 0 1e-06 0 2e-06 1 1e-05 1)"
        mixed = pwl"""
            0   0V
            1ms 2mV
            """
        @test mixed == [(0,0u"V"),(1u"ms",2u"mV")]           # units may differ per point
    end
end
