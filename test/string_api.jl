@testset "String API" begin

    @testset "Automatic names" begin
        empty!(Microelectronics.counts)
        @test Microelectronics.nextname("R") == "R1"
        @test Microelectronics.nextname("R") == "R2"
        @test Microelectronics.nextname("C") == "C1"
        @test tstr(capacitor(1,0,1u"F")) == "C2 1 0 1"
        @test tstr(resistor(1,0,1u"Ω"))  == "R3 1 0 1"
        @test tstr(inductor(1,0,1u"H"))  == "L1 1 0 1"
        @test tstr(bipole(:C,2,3,1u"nF")) == "C3 2 3 1e-09"
        @test tstr(vdc(nplus=1,nminus=0,dc=1u"V")) == "V1 1 0 DC 1"
    end

    @testset "Passive elements" begin
        @test tstr(capacitor("CA",2,"a",1u"μF")) == "CA 2 a 1e-06"
        @test tstr(capacitor(;name="CA",nplus=2,nminus="a",value=1u"μF")) == "CA 2 a 1e-06"
        @test tstr(resistor("RA",2,"a",1u"MΩ")) == "RA 2 a 1e+06"
        @test tstr(resistor(;name="RA",nplus=2,nminus="a",value=1u"MΩ")) == "RA 2 a 1e+06"
        @test tstr(inductor("LA",2,"a",1u"μH")) == "LA 2 a 1e-06"
        @test tstr(inductor(;name="LA",nplus=2,nminus="a",value=1u"μH")) == "LA 2 a 1e-06"
        @test tstr(diode("D1",2,1,"D1N914")) == "D1 2 1 D1N914"
        @test tstr(bipole(:d,"d1",2,1,"1N4004")) == "d1 2 1 1N4004"
        @test tstr(bipole("R","load",1,2,1u"kΩ")) == "Rload 1 2 1000"
        @test resistor("R1",1,2,1) isa String
    end

    @testset "Independent sources" begin
        @test_throws ArgumentError vdc(1,0,1u"V")           # (name,nplus,nminus,value)
        @test tstr(vdc("VA","n1",0,5u"mV")) == "VA n1 0 DC 0.005"
        @test tstr(vdc("VA","n1",0,5u"mV";frequency=1u"krad/s",ac=1)) ==
              "VA n1 0 DC 0.005 AC 1 SIN (0,0.005,159.155,0)"
        @test tstr(vac("VIN",1,0)) == "VIN 1 0 AC 1"
        @test tstr(vac("VIN",1,0,2)) == "VIN 1 0 AC 2"
        @test tstr(vsin("Vsig",1,2)) == "Vsig 1 2 SIN (0,0.005,1000,0)"
        @test tstr(vsin("Vsig",1,0,1u"V",2u"V",1u"kHz")) == "Vsig 1 0 SIN (1,2,1000,0)"
        @test tstr(vsin(name="V1",nplus=1,nminus=0,phase=90u"°")) == "V1 1 0 SIN (0,0.005,1000,0,0,90)"
        @test tstr(vpulse("V1",1,0;high=1u"V")) == "V1 1 0 PULSE (0 1 1e-08 1e-08 1e-08 4.9e-07 0.001 )"
        @test tstr(vpwl("V1",1,0;points=[(0,0),(1,1)])) == "V1 1 0 PWL ( 0 0 1 1)"
        @test tstr(idc("I1",0,1,1u"mA")) == "I1 0 1 DC 0.001"
        @test tstr(iac("I1",0,1)) == "I1 0 1 AC 1"
        @test tstr(isin("I1",0,1;amplitude=1u"mA")) == "I1 0 1 SIN (0,0.001,1000,0)"
        @test tstr(ipulse("I1",0,1;low=0,high=1u"mA")) == "I1 0 1 PULSE (0 0.001 1e-08 1e-08 1e-08 4.9e-07 0.001 )"
        @test tstr(ipwl("I1",0,1;points=[(0,0),(1u"ms",1u"mA")])) == "I1 0 1 PWL ( 0 0 0.001 0.001)"
        @test tstr(independent_source("V";name="V1",nplus=1,nminus=0,dctype=true)) == "V1 1 0 DC 0"
        @test tstr(independent_source("V";name="V1",nplus=1,nminus=0,value="DISTOF1 0.1")) ==
              "V1 1 0 DISTOF1 0.1"
        @test_throws ArgumentError independent_source("V";name="V1",nplus=1)
    end

    @testset "Controlled sources" begin
        @test tstr(dependent_source(:vcvs;name="E1",nplus=3,nminus=0,control=[1,2],gain=:Av)) == "E1 3 0 1 2 {Av}"
        @test tstr(dependent_source(:vccs;name="1",nplus=3,nminus=0,control=[1,2],gain=1u"mS")) == "G1 3 0 1 2 0.001"
        @test tstr(dependent_source(:cccs;name="1",nplus=3,nminus=0,control="V1",gain=10)) == "F1 3 0 V1 10"
        @test tstr(dependent_source(:ccvs;name="H2",nplus=3,nminus=0,control="V1",gain=1u"kΩ")) == "H2 3 0 V1 1000"
        @test tstr(dependent_source(:vcvs;name="E1",nplus=3,nminus=0,control=[1,2])) == "E1 3 0 1 2 1"
    end

    @testset "Subcircuits and transistors" begin
        @test tstr(opamp(;name="OA1",nplus=0,nminus=1,out=3,model="my_op_amp")) == "XOA1 0 1 3 my_op_amp"
        @test tstr(opamp(;name="OA1",nplus=0,nminus=1,out=3)) == "XOA1 0 1 3 ideal_opamp"
        @test tstr(subckt_instance(;name=1,terminals="2 3 4",model="my_subcircuit")) == "X1 2 3 4 my_subcircuit"
        @test tstr(subckt_instance(;name="U1",terminals=(2,3),model="m")) == "XU1 2 3 m"
        @test tstr(subckt_instance(;name="X5",terminals=[2,3],model="m")) == "X5 2 3 m"
        @test tstr(mosfet("1",3,2,0,0)) == "M1 3 2 0 0 ald1105n"           # sizes from the model
        @test tstr(mosfet("M1",3,2,0,0,"nmos";W=1e-6,L=1e-6)) == "M1 3 2 0 0 nmos W=1.0e-6 L=1.0e-6"
    end

    @testset "String and object APIs agree" begin
        same(a,b) = tstr(a) == tstr(b)
        @test same(resistor("R1",1,2,1u"kΩ"),  Resistor("R1",1,2,1u"kΩ"))
        @test same(resistor(name="R1",nplus=1,nminus=2,value=:R), Resistor(name="R1",nplus=1,nminus=2,value=:R))
        @test same(capacitor("C1",2,0,1u"nF"), Capacitor("C1",2,0,1u"nF"))
        @test same(inductor("L1",2,0,1u"mH"),  Inductor("L1",2,0,1u"mH"))
        @test same(diode("D1",1,2,"D1N914"),   Diode("D1",1,2,"D1N914"))
        @test same(opamp(name="OA1",nplus=0,nminus=1,out=3,model="ideal_opamp"),
                   Opamp(name="OA1",nplus=0,nminus=1,out=3,model="ideal_opamp"))
        @test same(vdc("V1",1,0,5u"V"),        Vdc("V1",1,0,5u"V"))
        @test same(vdc("in",1,0,5u"V"),        Vdc("in",1,0,5u"V"))
        @test same(vac("V1",1,0,1),            Vac("V1",1,0,1))
        @test same(idc("I1",0,1,1u"mA"),       Idc("I1",0,1,1u"mA"))
        @test same(iac("I1",0,1),              Iac("I1",0,1))
        @test same(vsin("V1",1,0),             Vsin("V1",1,0))
        @test same(vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"),
                   Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"))
        @test same(vsin("V1",1,0;amplitude=1u"V",ac=1,dc=2u"V"),
                   Vsin("V1",1,0;amplitude=1u"V",ac=1,dc=2u"V"))
        @test same(isin("I1",0,1;amplitude=1u"mA"), Isin("I1",0,1;amplitude=1u"mA"))
        @test same(vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"),
                   Vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"))
        @test same(vpulse("V1",1,0;pulses=2), Vpulse("V1",1,0;pulses=2))
        @test same(vpwl("V1",1,0;points=[(0u"s",0u"V"),(1u"ms",1u"V")]),
                   Vpwl("V1",1,0,[Point(0u"s",0u"V"),Point(1u"ms",1u"V")]))
        @test same(dependent_source(:vccs;name="G1",nplus=3,nminus=0,control=[1,2],gain=1u"mS"),
                   VCCS(name="G1",nplus="3",nminus="0",control=["1","2"],gain=1u"mS"))
        @test same(dependent_source(:ccvs;name="H1",nplus=3,nminus=0,control="V1",gain=2),
                   CCVS(name="H1",nplus="3",nminus="0",control="V1",gain=2))
        @test same(mosfet("M1",3,2,0,0,"nmos"), MOSFET("M1",3,2,0,0,"nmos"))
        @test same(mosfet("M1",3,2,0,0,"nmos";W=20e-6,L=10e-6),
                   MOSFET("M1",3,2,0,0,"nmos",[Parameter("W",20e-6),Parameter("L",10e-6)]))
    end
end
