# make         compile (synthesis, fit, assemble, sta)
# make prog    program the board over jtag
# make sim     simulate the testbench (verilator for .sv, ghdl for .vhd)
# make clean   remove build artifacts

PROJ   ?= gcd
TB     ?= tb
# set empty if a quartus tool rejects the flag
QFLAGS ?= --64bit
# e.g. make prog CABLE=1 (see jtagconfig); empty = auto-detect
CABLE  ?=
# jtag chain position, only needed if the fpga isn't the first device
POS    ?=

SOF := output_files/$(PROJ).sof
SV  := $(filter-out $(TB).sv,$(wildcard *.sv))
VHD := $(filter-out $(TB).vhd,$(wildcard *.vhd))

.PHONY: all compile prog sim sim-sv sim-vhdl clean

all: compile
compile: $(SOF)

# quartus compiles the files listed in $(PROJ).qsf; the wildcards here
# only drive rebuild detection
$(SOF): $(SV) $(VHD) $(PROJ).qsf $(wildcard *.sdc *.tcl)
	quartus_sh $(QFLAGS) --flow compile $(PROJ)

prog: $(SOF)
	quartus_pgm $(QFLAGS) -m jtag $(if $(CABLE),-c "$(CABLE)") -o "p;$(SOF)$(if $(POS),@$(POS))"

sim: $(if $(wildcard $(TB).sv),sim-sv,sim-vhdl)

# needs verilator 5+
sim-sv:
	verilator --binary --timing --trace -Wall -Wno-fatal --top-module $(TB) \
	    -Mdir build_sim $(TB).sv $(SV)
	./build_sim/V$(TB)

# -i/-m resolves analysis order, so file order doesn't matter
sim-vhdl:
	mkdir -p build_sim
	cd build_sim && ghdl -i --std=08 $(addprefix ../,$(VHD) $(TB).vhd) \
	    && ghdl -m --std=08 $(TB) \
	    && ghdl -r --std=08 $(TB) --vcd=wave.vcd

clean:
	rm -rf output_files db incremental_db qdb build_sim
	rm -f *_pin_model_dump.txt
