using Microelectronics
using Test

rgx=r"\s+"=>" "
tstr(s) = strip(replace(s,rgx))

@testset "Microelectronics.jl" begin
    # Write your tests here.
    @test dB20(10) == 20
    @test dB20(0) == -Inf
    @test dB20([10,20])  ≈ [20.0,26.0205999]
    @test dB20.([[10,20],[100,1000]]) ≈ [[20,26.0205999],[40,60]]

    @test rad(1u"Ω^-1*F^-1") == 1u"rad*s^-1"
    @test rad(1u"°") ≈ (π/180)*u"rad"
    @test rad(1u"Hz") ≈ 6.283185307179586u"rad*s^-1"
    @test rad(1) == 1u"rad"
    @test rad(1u"rad") == 1u"rad"
    @test rad(1u"MHz") == 2π*u"Mrad/s"

    @test Hz(1u"rad/s") ≈ 0.15915494309189535u"Hz"
    @test Hz(1u"1/s") ≈ 0.15915494309189535u"Hz"
    @test Hz(1u"Hz") == 1u"Hz"
    @test Hz(1u"MHz") == 1u"MHz"
    @test Hz(1u"kHz") === 1000u"Hz"
    
    @test °(1u"rad") ≈ (180/π)*u"°"
    @test °(1u"rad/s") ≈ 0.15915494309189535u"Hz"
    @test °(1/(1u"Ω"*1u"F")) == 1u"Hz"
    @test °(rad(1/(1u"kΩ"*1u"nF"))) ≈ 159154.94309189534u"Hz"
    @test °(1u"Hz") == 1u"Hz"
    @test °(1u"s/s") == 1u"°"
    @test °(1u"s/ms") == 1000u"°"
    @test °(1) == 1u"°"
    @test °(1u"V") == 1u"V"

    @test spice_value(1u"kΩ") == 1000
    @test spice_value(1u"μF") == 1e-6
    @test spice_value(1u"rad/s") ≈ 0.15915494309
    @test spice_value(15u"kHz") == 15e3
    @test spice_value(1/(1u"kΩ"*1u"μF")) ≈ 159.15494309189535
    @test spice_value(rad(1u"MHz")) == 1e6

    @test qstr("this") == "this"
    @test qstr(1u"V") == "1"
    @test qstr(1u"μA") == "1e-06"
    @test qstr(:C) == "{C}"
    @test qstr(123) == "123"
    
    @test Microelectronics.nextname("R") == "R1"
    @test Microelectronics.nextname("R") == "R2"
    @test Microelectronics.nextname("C") == "C1"

    rgx=r"\s+"=>" "
    @test replace(capacitor(1,0,1u"F"),rgx)=="C2 1 0 1"
    @test replace(capacitor("CA",2,"a",1u"μF"),rgx)=="CA 2 a 1e-06"
    @test replace(capacitor(;name="CA",nplus=2,nminus="a",value=1u"μF"),rgx)=="CA 2 a 1e-06"
    @test replace(resistor(1,0,1u"Ω"),rgx)=="R3 1 0 1"
    @test replace(resistor("RA",2,"a",1u"MΩ"),rgx)=="RA 2 a 1e+06"
    @test replace(resistor(;name="RA",nplus=2,nminus="a",value=1u"MΩ"),rgx)=="RA 2 a 1e+06"
    @test replace(inductor(1,0,1u"H"),rgx)=="L1 1 0 1"
    @test replace(inductor("LA",2,"a",1u"μH"),rgx)=="LA 2 a 1e-06"
    @test replace(inductor(;name="LA",nplus=2,nminus="a",value=1u"μH"),rgx)=="LA 2 a 1e-06"

    @test tstr(opamp(;name="OA1",nplus=0,nminus=1,out=3,model="my_op_amp"))=="XOA1 0 1 3 my_op_amp"

    d = @table a=1u"A" b=2 c="123"
    @test haskey(d,"a")
    @test haskey(d,"b")
    @test haskey(d,"c")
    @test typeof(d["c"]) == String
    @test typeof(d["a"]) <: Quantity
    @test typeof(d["b"]) <: Number
    @test Microelectronics.hasall(d,["a","b","c"])
    @test Microelectronics.hasany(d,["x","y","b"])
    @test !Microelectronics.hasall(d,["x","y","b"])
    @test !Microelectronics.hasany(d,["x","y","z"])

    points=pwl"""
           0s   0V
           1μs  0V
           2μs  1V
           10μs 1V
        """
    ref=[(0u"s",0u"V"),(1u"μs",0u"V"),(2u"μs",1u"V"),(10u"μs",1u"V")]
    @test points==ref

    @test tstr(pwl_string(points)) == "PWL ( 0 0 1e-06 0 2e-06 1 1e-05 1)"

    # vdc(name,nplus,nminus,value): a value in a node position is an error
    @test_throws ArgumentError vdc(1,0,1u"V")
    @test tstr(vdc("VA","n1",0,5u"mV"))=="VA n1 0 DC 0.005"
    @test tstr(vdc("VA","n1",0,5u"mV";frequency=1u"krad/s",ac=1))=="VA n1 0 DC 0.005 AC 1 SIN (0,0.005,159.155,0)"
    @test tstr(vac("VIN",1,0))=="VIN 1 0 AC 1"
    @test tstr(vsin("Vsig",1,2))=="Vsig 1 2 SIN (0,0.005,1000,0)"

    @test tstr(pulse_string(;)) == "PULSE (0 5 1e-08 1e-08 1e-08 4.9e-07 0.001 )"
    
    @test tstr(spice_parameters(@table a=1u"μA" bcd=23u"MΩ")) == ".param a=1e-06 .param bcd=2.3e+07"
    @test tstr(dependent_source(:vcvs;name="E1",nplus=3,nminus=0,control=[1,2],gain=:Av)) == "E1 3 0 1 2 {Av}"
    @test tstr(dependent_source(:cccs;name="1",nplus=3,nminus=0,control="V1",gain=10)) == "F1 3 0 V1 10"
    @test tstr(string(VCVS(name="E1",nplus="3",nminus="0",control=["1","2"],gain=:Av))) == "E1 3 0 1 2 {Av}"
    @test tstr(subckt_instance(;name=1,terminals="2 3 4",model="my_subcircuit")) == "X1 2 3 4 my_subcircuit"

    parameters=[spice_parameters(@table fs=1u"krad/s")]
    sources=[vsin(1,1,0;frequency=:fs,ac=1)]
    components=[resistor(1,1,2,1u"kΩ"),
                capacitor(1,2,0,1u"μF")
                ]
    n=build_netlist(;title="test circuit",parameters,
                    sources,components)
    @test tstr(n) == "* test circuit .include $(model_library()) .param fs=159.155 V1 1 0 AC 1 SIN (0,0.005,{fs},0) R1 1 2 1000 C1 2 0 1e-06 .end"

    simulate(:dc;device="v1",start=0,stop=1,step=0.5)
    @test dc_sweep() == [0,0.5,1]u"V"
    @test node"1"==[0,0.5,1]u"V"
    @test i"v1"==[0.0,0.0,0.0]


    simulate(:ac;start=10u"rad/s",stop=1u"Mrad/s",steps=1)
    @test dB"2" ≈ [-0.00043427307917365363, -0.04321376857655787, -3.0103015095212604, -20.043216812838658, -40.000437378220425, -60.000007448701886]

    @test ac_freq() ≈ [1.59155, 15.915500000000003, 159.15500000000006, 1591.5500000000009, 15915.500000000011, 159155.00000000015]
    @test phase"2" ≈ [-0.5729389025321778, -5.710595165907326, -45.00001024345702, -84.28940889090734, -89.42706150716513, -89.94270426007239]

    # String macros must read the simulator when the code runs, not when it
    # is parsed: inside a function and a loop, each call sees the new result.
    vout() = node"2"[1]
    results = map((1u"kΩ", 3u"kΩ")) do R2
        build_netlist(; sources=[vdc("VS",1,0,1u"V")],
                      components=[resistor("RA",1,2,1u"kΩ"), resistor("RB",2,0,R2)])
        simulate(:op)
        vout()
    end
    @test results[1] ≈ 500u"mV"
    @test results[2] ≈ 750u"mV"
end

@testset "String and object APIs agree" begin
    same(a,b) = tstr(string(a)) == tstr(string(b))

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
    @test same(vsin("V1",1,0),             Vsin("V1",1,0))
    @test same(vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"),
               Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"))
    @test same(vsin("V1",1,0;amplitude=1u"V",ac=1,dc=2u"V"),
               Vsin("V1",1,0;amplitude=1u"V",ac=1,dc=2u"V"))
    @test same(vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"),
               Vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"))
    @test same(vpwl("V1",1,0;points=[(0u"s",0u"V"),(1u"ms",1u"V")]),
               Vpwl("V1",1,0,[Point(0u"s",0u"V"),Point(1u"ms",1u"V")]))
    @test same(dependent_source(:vccs;name="G1",nplus=3,nminus=0,control=[1,2],gain=1u"mS"),
               VCCS(name="G1",nplus="3",nminus="0",control=["1","2"],gain=1u"mS"))
    @test same(mosfet("M1",3,2,0,0,"nmos"),
               MOSFET("M1",3,2,0,0,"nmos",[Parameter(k,v) for (k,v) in
                   ("W"=>20e-6,"L"=>10e-6,"AD"=>0.161e-8,"AS"=>0.603e-8,
                    "PD"=>0.478e-6,"PS"=>0.478e-6,"NRD"=>0.3,"NRS"=>1)]))
end

@testset "Waveform formatting" begin
    @test tstr(sin_string(0u"V",1u"V",1u"kHz",90u"°"))       == "SIN (0,1,1000,0,0,90)"
    @test tstr(sin_string(0u"V",1u"V",1u"kHz",(π/2)u"rad"))  == "SIN (0,1,1000,0,0,90)"
    @test tstr(sin_string(0u"V",1u"V",1u"kHz",:ph))          == "SIN (0,1,1000,0,0,{ph})"
    @test startswith(tstr(string(Vpulse("V1",1,0;low=0u"V",high=5u"V"))), "V1 1 0 PULSE (0 5")
    @test occursin("PWL ( 0 0 0.001 0.002)", string(Vpwl("V1",1,0,[(0,0),(1u"ms",2u"mV")])))
    @test tstr(string(Waveform(:dc,1u"V"))) == "DC 1"
end

@testset "Netlists mix both styles" begin
    n = Netlist(title="mixed", parameters=[Parameter("R",1u"kΩ")],
                sources=[Vdc("V1",1,0,1u"V")],
                components=[Resistor("R1",1,2,:R), resistor("R2",2,0,1u"kΩ")])
    @test tstr(string(n)) == "* mixed .include $(model_library()) .param R=1000 V1 1 0 DC 1 R1 1 2 {R} R2 2 0 1000 .end"
    load_netlist(n); simulate(:op)
    @test node"2"[1] ≈ 500u"mV"

    txt = build_netlist(; sources=[vdc("V1",1,0,1u"V")],
                        components=[resistor("R1",1,2,1u"kΩ"), Resistor("R2",2,0,3u"kΩ")])
    @test !occursin("Any[", txt)
    simulate(:op)
    @test node"2"[1] ≈ 750u"mV"
end

@testset "Sources simulate as specified" begin
    sample(t) = (ts = ustrip.(u"s",tran_time()); v = real"1"; v[argmin(abs.(ts .- t))])
    for src in (vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"),
                Vsin("V1",1,0;amplitude=1u"V",frequency=1u"kHz",phase=90u"°"))
        build_netlist(; sources=[src], components=[resistor("RL",1,0,1u"kΩ")])
        simulate(:tran; tstep=1u"μs", tmax=1u"ms")
        @test sample(0.0)    ≈ 1.0 atol=0.01     # 90° phase: starts at the peak
        @test sample(0.5e-3) ≈ -1.0 atol=0.01
    end
    for src in (vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"),
                Vpulse("V1",1,0;low=0u"V",high=5u"V",width=0.5u"ms"))
        build_netlist(; sources=[src], components=[resistor("RL",1,0,1u"kΩ")])
        simulate(:tran; tstep=1u"μs", tmax=1u"ms")
        @test sample(0.25e-3) ≈ 5.0 atol=0.01   # high during the pulse
        @test sample(0.75e-3) ≈ 0.0 atol=0.01   # low afterwards
    end
end
