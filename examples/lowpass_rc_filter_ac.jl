using Microelectronics


#============ PARAMETERS ===========================#

R  = 1u"kΩ"
C  = 1u"μF"

ωc    = rad(1/(R*C))  # cutoff frequency (rad/sec)
fc    = Hz(ωc)        # cutoff frequency (Hz)

start = fc/1000    # start (low) frequency
stop  = fc*1000    # stop (high) frequency
steps = 10         # frequency steps per decade

# Show parameters in a table:
print(@table R C fc start stop steps)


#============ BUILD NETLIST =======================#

# Pass these parameters to the SPICE netlist:
circuit_parameters  = spice_parameters(@table R  C)

# Define a voltage signal source:
voltage_source     = vac(;name      = "Vin",
                          nplus     = 1,
                          nminus    = 0,
                          ac        = 1
                          )

# Define an array of passive components:
components         = [
    resistor(;
             name   = "R1",
             nplus  = 1,
             nminus = 2,
             value  = :R), 
    capacitor(;
              name   = "C1",
              nplus  = 2,
              nminus = 0,
              value  = :C)
]

# Generate the netlist using variable interpolation
netlist="""
* RC Low-Pass Filter

$circuit_parameters
$voltage_source
$components

.end
"""

println(netlist)

load_netlist(netlist)



#=========== RUN TRANSIENT SIMULATION ================#
simulate(:ac;start,stop,steps)


#=========== PLOT RESULT =================================#
# display Bode Plot dB"2", phase"2" vs frequency

p=plot(plot(ac_freq(),[dB"2"]; title="Magnitude [dB]"),
       plot(ac_freq(),[phase"2"]; title="Phase [°]"),    
       xscale=:log10,
       layout=(2,1)
       )

vline!(p[1],[ustrip(fc)];labels=:none)
vline!(p[2],[ustrip(fc)];labels=:none)
hline!(p[2],[-45];labels=:none)
