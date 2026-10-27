@testset "Element objects" begin

    @testset "Names and prefixes" begin
        empty!(Microelectronics.counts)
        @test tstr(Resistor("R1",1,2,1u"kΩ"))   == "R1 1 2 1000"
        @test tstr(Resistor("load",1,2,1u"kΩ")) == "Rload 1 2 1000"   # prefix added
        @test tstr(Resistor("rload",1,2,1u"kΩ"))== "rload 1 2 1000"   # any case is fine
        @test tstr(Resistor(1,1,2,1u"kΩ"))      == "R1 1 2 1000"      # numeric names
        # no name: R1, R2, ... (counted per prefix)
        @test tstr(Resistor(nplus=1,nminus=2,value=1u"kΩ"))  == "R1 1 2 1000"
        @test tstr(Resistor(nplus=1,nminus=2,value=1u"kΩ"))  == "R2 1 2 1000"
        @test tstr(Capacitor(nplus=1,nminus=0,value=1u"nF")) == "C1 1 0 1e-09"
        @test Resistor("R9",1,2,1).name == "R9"
    end

    @testset "Nodes" begin
        @test Resistor("R1",1,2,1).nodes == ["1","2"]
        @test Resistor("R1",:in,:out,1).nodes == ["in","out"]
        @test Resistor("R1","vdd",0,1).nodes == ["vdd","0"]
        # a value where a node belongs is an argument-order mistake
        @test_throws ArgumentError Resistor("R1",1,1u"kΩ",2)
        @test_throws ArgumentError Vdc(1,0,5u"V")
        @test_throws ArgumentError Isin("I1",1u"mA",0)
        @test_throws ArgumentError MOSFET("M1",1,2,3u"V",0,"nmos")
    end

    @testset "Values" begin
        @test tstr(Resistor("R1",1,2,2.2u"kΩ")) == "R1 1 2 2200"
        @test tstr(Resistor("R1",1,2,:Rload))   == "R1 1 2 {Rload}"
        @test tstr(Resistor("R1",1,2,"4.7k"))   == "R1 1 2 4.7k"
        @test tstr(Resistor("R1",1,2,100))      == "R1 1 2 100"
        @test tstr(Capacitor(name="C1",nplus=1,nminus=0,value=10u"pF")) == "C1 1 0 1e-11"
        @test tstr(Inductor("L1",1,0,1u"μH")) == "L1 1 0 1e-06"
        @test tstr(Inductor(name="L2",nplus=1,nminus=0,value=1u"mH")) == "L2 1 0 0.001"
    end

    @testset "Component fields" begin
        r = Resistor("R1",1,2,1u"kΩ")
        @test r isa Component && r isa Element
        @test (r.species, r.prefix, r.value, r.model) == ("resistor", "R", 1u"kΩ", nothing)
        d = Diode("D1",1,0,"D1N914")
        @test (d.species, d.prefix, d.model) == ("diode", "D", "D1N914")
    end

    @testset "Diodes, MOSFETs and subcircuit instances" begin
        @test tstr(Diode("D1",1,0,"D1N914")) == "D1 1 0 D1N914"
        @test tstr(Diode(name="D2",nplus=2,nminus=1,model="D1N4004")) == "D2 2 1 D1N4004"
        @test tstr(MOSFET("M1",3,2,0,0,"ald1105n")) == "M1 3 2 0 0 ald1105n"
        @test tstr(MOSFET(name="M2",drain=3,gate=2,source=0,substrate=0,model="ald1105n",
                          parameters=[Parameter("W",20e-6),Parameter("L",10e-6)])) ==
              "M2 3 2 0 0 ald1105n W=2.0e-5 L=1.0e-5"
        @test tstr(Subckt("A1",[1,2,3],"saturating_opamp")) == "XA1 1 2 3 saturating_opamp"
        @test tstr(Subckt("X1",[1,2],"foo")) == "X1 1 2 foo"                 # X not doubled
        @test tstr(Subckt("X2",[1,2],"foo",[Parameter("Av",1000)])) == "X2 1 2 foo Av=1000"
        @test tstr(Instance("U1",[1,2],"foo")) == "XU1 1 2 foo"
        @test tstr(Opamp("OA1",0,1,3,"ideal_opamp")) == "XOA1 0 1 3 ideal_opamp"
        @test tstr(Opamp(name="OA2",nplus=0,nminus=1,out=3,model="ideal_opamp")) ==
              "XOA2 0 1 3 ideal_opamp"
    end

    @testset "Controlled sources" begin
        @test tstr(VCVS(name="E1",nplus="3",nminus="0",control=["1","2"],gain=100)) == "E1 3 0 1 2 100"
        @test tstr(VCVS(name="1",nplus="3",nminus="0",control=["1","2"],gain=:Av)) == "E1 3 0 1 2 {Av}"
        @test tstr(VCCS(name="G1",nplus="2",nminus="0",control=["1","0"],gain=1u"mS")) == "G1 2 0 1 0 0.001"
        @test tstr(CCCS(name="F1",nplus="2",nminus="0",control="Vsense",gain=50)) == "F1 2 0 Vsense 50"
        @test tstr(CCVS(name="H1",nplus="2",nminus="0",control="Vsense",gain=1u"kΩ")) == "H1 2 0 Vsense 1000"
        @test tstr(CCVS(name="out",nplus="2",nminus="0",control="Vs",gain=1)) == "Hout 2 0 Vs 1"
        @test VCVS(name="E1",nplus="3",nminus="0",control=["1","2"],gain=1) isa Microelectronics.DependentSource
    end

    @testset "Independent sources" begin
        @test tstr(Vdc("V1",1,0,5u"V"))     == "V1 1 0 DC 5"
        @test tstr(Vdc("in",1,0,5u"V"))     == "Vin 1 0 DC 5"
        @test tstr(Idc("I1",0,1,1u"mA"))    == "I1 0 1 DC 0.001"
        @test tstr(Vac("V1",1,0))           == "V1 1 0 AC 1"
        @test tstr(Iac("I1",0,1,2))         == "I1 0 1 AC 2"
        @test tstr(Vsin("V1",1,0))          == "V1 1 0 SIN (0,0.005,1000,0)"
        @test tstr(Isin("I1",0,1;amplitude=1u"mA",frequency=1u"kHz")) == "I1 0 1 SIN (0,0.001,1000,0)"
        @test tstr(Vsin("V1",1,0;offset=1u"V",amplitude=2u"V",frequency=10u"kHz",phase=30u"°")) ==
              "V1 1 0 SIN (1,2,10000,0,0,30)"
        @test tstr(Vpulse("V1",1,0;low=0u"V",high=5u"V")) == "V1 1 0 PULSE (0 5 1e-08 1e-08 1e-08 4.9e-07 0.001 )"
        @test tstr(Vpulse("V1",1,0;pulses=3)) == "V1 1 0 PULSE (0 5 1e-08 1e-08 1e-08 4.9e-07 0.001 3 )"
        @test tstr(Ipulse("I1",0,1;low=0u"A",high=1u"mA")) == "I1 0 1 PULSE (0 0.001 1e-08 1e-08 1e-08 4.9e-07 0.001 )"
        @test tstr(Vpwl("V1",1,0,[(0,0),(1u"ms",1u"V")])) == "V1 1 0 PWL ( 0 0 0.001 1)"
        @test tstr(Ipwl("I1",0,1,[Point(0,0),Point(1u"ms",1u"mA")])) == "I1 0 1 PWL ( 0 0 0.001 0.001)"
        @test tstr(Vsource("V1",1,0)) == "V1 1 0"
        @test Vdc("V1",1,0,1).species == "vsource"
        @test Idc("I1",1,0,1).species == "isource"
    end

    @testset "Sources with several waveforms" begin
        # DC and AC always come first, whatever order they were given in
        @test tstr(Vsin("V1",1,0;amplitude=1u"V",ac=1,dc=2u"V")) == "V1 1 0 DC 2 AC 1 SIN (0,1,1000,0)"
        @test tstr(Vdc("V1",1,0,1u"V";ac=1)) == "V1 1 0 DC 1 AC 1"
        @test tstr(Vsin("V1",1,0;ac=0)) == "V1 1 0 SIN (0,0.005,1000,0)"   # ac=0 is omitted
        @test tstr(Vsource("V1",1,0;dc=1,pwl=[(0,0),(1,1)])) == "V1 1 0 DC 1 PWL ( 0 0 1 1)"
        # the caller's waveform vector is not modified
        w = [Waveform(:dc,1)]
        s = Source(;name="V1",nplus=1,nminus=0,waveforms=w,ac=1)
        @test length(w) == 1 && length(s.waveforms) == 2
    end

    @testset "Waveform objects" begin
        @test tstr(Waveform(:dc,1u"V"))  == "DC 1"
        @test tstr(Waveform(:ac))        == "AC 1"
        @test tstr(Waveform(:sin;amplitude=1u"V")) == "SIN (0,1,1000,0)"
        @test tstr(Waveform(:sin,1u"V",2u"V",1u"kHz")) == "SIN (1,2,1000,0)"
        @test tstr(Waveform(:pulse,0u"V",1u"V",0u"s",1u"ns",1u"ns",1u"μs",2u"μs")) ==
              "PULSE (0 1 0 1e-09 1e-09 1e-06 2e-06 )"
        @test tstr(Waveform(:pwl,[(0,0),(1,1)])) == "PWL ( 0 0 1 1)"
        @test tstr(Waveform(:raw,"DISTOF1 0.1")) == "DISTOF1 0.1"
        @test Waveform(:pulse;high=3u"V").parameters["high"] == 3u"V"
        @test Waveform(:pulse;high=3u"V").parameters["low"] == Microelectronics.PULSE_DEFAULTS.low
    end

    @testset "alter" begin
        s = Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz")
        alter(s; frequency=2u"kHz", amplitude=2u"V", offset=1u"V", phase=90u"°")
        @test tstr(s) == "V1 1 0 SIN (1,2,2000,0,0,90)"
        # only sources with exactly one sinusoid can be altered; others are left alone
        d = Vdc("V1",1,0,1u"V")
        quietly(() -> alter(d; frequency=1u"kHz"))
        @test tstr(d) == "V1 1 0 DC 1"
    end

    @testset "Parameters" begin
        @test string(Parameter("R",1u"kΩ")) == "R=1000"
        @test string(Parameter("tag","abc")) == "tag=abc"
        @test Parameter("a"=>1).name == "a"
        @test Parameter(("a",1)).value == 1
        @test [p.name for p in Parameter(@table a=1 b=2u"V")] == ["a","b"]
        @test [p.name for p in Parameter([("a",1),"b"=>2])] == ["a","b"]
    end

    @testset "SpiceLine" begin
        @test string(SpiceLine("R1 1 0 1k\n")) == "R1 1 0 1k"     # trailing newline dropped
        @test string(SpiceLine(".param a=1\n.param b=2")) == ".param a=1\n.param b=2"
        @test SpiceLine("x") isa Element
    end
end
