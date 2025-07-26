vlib work
vlog Top_Module.v Top_Module_tb.v 
vsim -voptargs=+acc work.Top_Module_tb
add wave *
run -all
#quit -sim