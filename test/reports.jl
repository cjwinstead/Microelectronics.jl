#=
Parameter tables from report(). Shared by the main and dev branches.
=#
@testset "Report tables" begin
    table(d) = sprint(io -> report(io, d))
    rows(d) = split(chomp(table(d)), "\n")[3:end]
    cells(row) = strip.(split(row, "|")[2:4])           # name, value, unit

    R = 1u"kΩ"; C = 1u"μF"
    t = @table R fc=Hz(1/(R*C)) ωc=1/(R*C) gm=2*1.3628e-3u"A"/2.3u"V" Id=-4.7e-6u"A" Vov=2.3u"V"/3 ratio=2/3 N=123456 big=1.5e7 note="text" flag=true Rp=parallel(1u"kΩ",2.2u"kΩ",4.7u"kΩ") H=(0.5-0.5im) Rint=1500u"Ω" tiny=-3.3e-14u"V"
    c = Dict(cells(r)[1] => (cells(r)[2], cells(r)[3]) for r in rows(t))

    # every line has the same width: values fit their columns
    @test length(unique(textwidth.(split(chomp(table(t)), "\n")))) == 1

    # at most four significant digits, with a readable prefix
    @test c["R"] == ("1", "kΩ")
    @test c["fc"] == ("159.2", "Hz")
    @test c["gm"] == ("1.185", "mA V^-1")
    @test c["Vov"] == ("766.7", "mV")
    @test c["Rp"] == ("599.8", "Ω")
    @test c["Rint"] == ("1.5", "kΩ")                      # integer ohms, 3//2 kΩ before
    @test c["Id"] == ("-4.7", "μA")                       # negative values get a prefix too
    @test c["tiny"] == ("-33", "fV")
    @test c["ωc"] == ("1000", "s^-1")                     # 1/(kΩ μF) reduced to SI units

    # plain numbers are rounded the same way
    @test c["ratio"] == ("0.6667", "")
    @test c["N"] == ("1.235e+05", "")
    @test c["big"] == ("1.5e+07", "")
    @test c["H"] == ("0.5 - 0.5im", "")
    @test c["flag"] == ("true", "")
    @test c["note"] == ("text", "")

    @test Microelectronics.report_number(1/3) == "0.3333"
    @test Microelectronics.report_number(2.0) == "2"
    @test Microelectronics.report_number(-1e-20) == "-1e-20"

    # report(NamedTuple) and report(OrderedDict) print the same table
    out = mktemp() do path, io
        redirect_stdout(() -> report((a=2/3, b=1500u"Ω")), io); close(io); read(path, String)
    end
    @test out == table(@table a=2/3 b=1500u"Ω")
    @test table((a=2/3, b=1500u"Ω")) == out               # report(io, ::NamedTuple)

    # scale_quantity chooses the prefix from the magnitude
    @test unit(scale_quantity(-0.0047u"A")) == u"mA"
    @test unit(scale_quantity(-3.3e-3u"V")) == u"mV"
    @test unit(scale_quantity(-2.2e6u"Ω")) == u"MΩ"
end
