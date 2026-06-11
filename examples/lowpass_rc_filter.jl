using Microelectronics


#============ PARAMETERS ===========================#

R  = 1u"kΩ"
C  = 1u"μF"


fc    = 1/(R*C)   # cutoff frequency
fs    = 1u"kHz"   # signal frequency
Vs    = 5u"mV"    # signal amplitude (zero-to-peak)

Ts    = 1/fs      # signal period
tstep = Ts/20     # transient time step
tmax  = 4*Ts      # transient stop time

# Show parameters in a table:
@table R C fc fs Vs Ts tstep tmax


#============ BUILD NETLIST =======================#

# Pass these parameters to the SPICE netlist:
circuit_parameters  = spice_parameters(@table R  C  fs)

# Define a voltage signal source:
voltage_source     = vsin(;
                          nplus     = 1,
                          nminus    = 0,
                          frequency = fs,
                          offset    = 0,
                          amplitude = Vs
                          )

# Define an array of passive components:
components         = [
    resistor(;
             name   = "R1",
             nplus  = 1,
             nminus = 2,
             value  = R),
    capacitor(;
              name   = "C1",
              nplus  = 2,
              nminus = 0,
              value  = C)
]

# Generate the netlist using variable interpolation
netlist="""
* RC Low-Pass Filter

$circuit_parameters
$voltage_source
$components

.end
"""

show(netlist)

load_netlist(netlist)


#========== PRINT SUMMARY TO CONSOLE ==================#
# println("Device Parameters:")
# parameter_table(circuit_parameters)

# println("Simulation Parameters:")
# parameter_table(simulation_parameters)

# println("Netlist:")
# println(netlist)


#=========== RUN TRANSIENT SIMULATION ================#
transient(;tstep,tmax)


#=========== PLOT RESULT =============================#
# display voltage traces node"1" and node"2" vs time

plot(tran_time(),[node"1",node"2"])
