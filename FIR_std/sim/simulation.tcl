# Set the working directory
set work_dir "work"
set src_dir "../src"
set tb_dir "../tb"


# Create the work library if it does not exist
if {[file exists $work_dir]} {
    vdel -lib $work_dir -all
}
vlib $work_dir

# Compile the design files
vmap work $work_dir

# List of RTL files to compile
set rtl_files {
    FFD.vhd
    REG.vhd
    FIR.vhd
}

# Compile each RTL file
foreach file $rtl_files {
    vcom -work work "$src_dir/$file"
}

# Compile the testbench
vcom -work work "$tb_dir/clk_gen.vhd"
vcom -work work "$tb_dir/data_maker_new.vhd"
vcom -work work "$tb_dir/data_sink.vhd"
vlog -work work "$tb_dir/tb_fir.v"

# Load the testbench
vsim -voptargs="+acc" work.tb_fir

#adding wave
add wave -color white sim:/tb_fir/CLK_i
add wave -color white sim:/tb_fir/RST_n_i
add wave -radix decimal -color blue sim:/tb_fir/DIN_i
add wave -color yellow sim:/tb_fir/VIN_i 
add wave -radix decimal -color blue sim:/tb_fir/DOUT_i 
add wave -color white sim:/tb_fir/VOUT_i 
add wave -color red sim:/tb_fir/END_SIM_i 

# Run the simulation
set sim_time 5000ns 
run $sim_time
