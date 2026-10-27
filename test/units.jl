@testset "Units and conversions" begin

    @testset "dB20" begin
        @test dB20(10) == 20
        @test dB20(1) == 0
        @test dB20(0) == -Inf
        @test dB20(1/sqrt(2)) ≈ -3.0103 atol=1e-4
        @test dB20([10,20]) ≈ [20.0,26.0205999]
        @test dB20.([[10,20],[100,1000]]) ≈ [[20,26.0205999],[40,60]]
    end

    @testset "rad" begin
        @test rad(1u"Ω^-1*F^-1") == 1u"rad*s^-1"
        @test rad(1u"°") ≈ (π/180)*u"rad"
        @test rad(90u"°") ≈ (π/2)*u"rad"
        @test rad(1u"Hz") ≈ 2π*u"rad/s"
        @test rad(1u"MHz") == 2π*u"Mrad/s"
        @test rad(1) == 1u"rad"
        @test rad(1u"rad") == 1u"rad"
    end

    @testset "Hz" begin
        @test Hz(1u"rad/s") ≈ (1/2π)*u"Hz"
        @test Hz(2π*u"rad/s") ≈ 1u"Hz"
        @test Hz(1u"1/s") ≈ (1/2π)*u"Hz"
        @test Hz(1u"Hz") == 1u"Hz"
        @test Hz(1u"MHz") == 1u"MHz"
        @test Hz(1u"kHz") === 1000u"Hz"
        # RC cutoff: 1/(RC) is an angular frequency
        @test Hz(1/(1u"kΩ"*1u"μF")) ≈ 159.15494309189535u"Hz"
    end

    @testset "°" begin
        @test °(1u"rad") ≈ (180/π)*u"°"
        @test °((π/4)u"rad") ≈ 45u"°"
        @test °(1u"rad/s") ≈ (1/2π)*u"Hz"
        @test °(1/(1u"Ω"*1u"F")) == 1u"Hz"
        @test °(rad(1/(1u"kΩ"*1u"nF"))) ≈ 159154.94309189534u"Hz"
        @test °(1u"Hz") == 1u"Hz"
        @test °(1u"s/s") == 1u"°"
        @test °(1u"s/ms") == 1000u"°"
        @test °(1) == 1u"°"
        @test °(1u"V") == 1u"V"
    end

    @testset "spice_value" begin
        @test spice_value(1u"kΩ") == 1000
        @test spice_value(1u"μF") == 1e-6
        @test spice_value(1u"μs") == 1e-6
        @test spice_value(10u"mS") ≈ 0.01
        @test spice_value(15u"kHz") == 15e3
        @test spice_value(rad(1u"MHz")) == 1e6          # rad/s are sent as Hz
        @test spice_value(1u"rad/s") ≈ 1/2π
        @test spice_value(1/(1u"kΩ"*1u"μF")) ≈ 159.15494309189535
        @test spice_value(1u"mV") isa Float64
    end

    @testset "qstr" begin
        @test qstr("this") == "this"
        @test qstr("1k") == "1k"
        @test qstr(1u"V") == "1"
        @test qstr(1u"μA") == "1e-06"
        @test qstr(2.2u"kΩ") == "2200"
        @test qstr(:C) == "{C}"
        @test qstr(123) == "123"
        @test qstr(1.5) == "1.5"
    end

    @testset "parallel" begin
        @test parallel(1u"kΩ",1u"kΩ") ≈ 500u"Ω"
        @test parallel(1u"kΩ",1u"kΩ",1u"kΩ") ≈ (1000/3)u"Ω"
        @test parallel(1u"kΩ",2u"kΩ") ≈ (2000/3)u"Ω"
        @test parallel(10u"kΩ",10u"Ω") < 10u"Ω"
        @test unit(parallel(1u"MΩ",1u"MΩ")) == u"Ω"
    end

    @testset "Automatic SI prefixes" begin
        scaled(x) = (round(ustrip(x), sigdigits=6), unit(x))
        @test scaled(scale_resistor(1500u"Ω"))    == (1.5, u"kΩ")
        @test scaled(scale_resistor(2.2e6u"Ω"))   == (2.2, u"MΩ")
        @test scaled(scale_resistor(47u"Ω"))      == (47, u"Ω")
        @test scaled(scale_capacitor(1e-9u"F"))   == (1, u"nF")
        @test scaled(scale_capacitor(4.7e-6u"F")) == (4.7, u"μF")
        @test scaled(scale_capacitor(5e-12u"F"))  == (5, u"pF")
        @test scaled(scale_Hz(1.5e6u"Hz"))        == (1.5, u"MHz")
        @test scaled(scale_Hz(2.5e3u"Hz"))        == (2.5, u"kHz")
        @test scaled(scale_Hz(0.5u"Hz"))          == (500, u"mHz")
        @test scaled(scale_s(2e-6u"s"))           == (2, u"μs")
        @test scaled(scale_s(3e-3u"s"))           == (3, u"ms")
        @test scaled(scale_s(1e-9u"s"))           == (1, u"ns")
        @test scaled(scale_quantity(0.0047u"A"))  == (4.7, u"mA")
        @test scaled(scale_quantity(3.3e-3u"V"))  == (3.3, u"mV")
        @test scaled(scale_quantity(2e-3u"A/V"))  == (2, u"mA/V")
        @test scaled(scale_quantity(1e4u"rad/s")) == (10, u"krad/s")
        @test scaled(scale_quantity(5e-12u"F"))   == (5, u"pF")
        @test scale_quantity(1u"kg") == 1u"kg"    # no rule: returned unchanged

        # Known bug: negative values are never rescaled (comparisons use x, not |x|)
        @test_broken unit(scale_quantity(-0.0047u"A")) == u"mA"
        @test_broken unit(scale_quantity(-3.3e-3u"V")) == u"mV"
    end

    @testset "Quantity predicates" begin
        @test isHz(1u"kHz")
        @test !isHz(1u"rad/s")
        @test isradps(1u"rad/s")
        @test !isradps(1u"Hz")
        @test israd(1u"rad")
        @test !israd(1u"°")
        @test is°(90u"°")
        @test iss(1u"ms")
        @test isvoltage(1u"mV")
        @test !isvoltage(1u"mA")
        @test iscurrent(1u"mA")
        @test isresistor(1u"kΩ")
        @test iscapacitor(1u"pF")
        @test istransconductance(1u"mS")
        @test istransconductance(1u"mA/V")
        @test !istransconductance(1u"Ω")
    end

    @testset "=> converts quantities" begin
        @test (1u"mV" => u"V") ≈ 0.001u"V"
        @test (1u"ms" => u"μs") ≈ 1000u"μs"
        @test ("a" => 1) isa Pair           # ordinary pairs are unaffected
    end

    @testset "device_prefix" begin
        @test device_prefix("resistor") == "R"
        @test device_prefix("vcvs") == "E"
        @test device_prefix("subckt") == "X"
    end
end
