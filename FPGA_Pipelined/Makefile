# Run from this project directory after sourcing the lab's Cadence setup.
# Plain `make` prints help; simulation and synthesis require explicit targets.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
# Keep preparation and run logging sequential, even when invoked with -j.
.NOTPARALLEL:
.DEFAULT_GOAL := help

PYTHON ?= python3
XRUN ?= xrun
XRUN_FLAGS ?= -access +rwc
BUILD_DIR ?= build/sim
SEED ?= 42
SIM_TIMEOUT ?= 240
VCD ?= 0
SRAM_MODEL ?= functional
SRAM_ROOT ?=
TCLSH ?= tclsh
DC_SHELL ?= dc_shell
SYNTH_BUILD_DIR ?= build/synth
SYNTH_RUN_DIR ?= $(SYNTH_BUILD_DIR)/latest
# Defaults live in synth/config.tcl; supplied Make variables override them.
SYNTH_SETTINGS := SYNTH_LAB_ROOT SYNTH_TOP SYNTH_PREDICT SYNTH_PREFETCH SYNTH_PERIOD_NS \
                  SYNTH_STD_DB SYNTH_STD_LIB SYNTH_STD_OPCOND SYNTH_SRAM_DB SYNTH_SRAM_LIB \
                  SYNTH_COMPILE_MODE SYNTH_MAX_CORES SYNTH_SETUP_UNCERTAINTY_NS \
                  SYNTH_HOLD_UNCERTAINTY_NS SYNTH_CLOCK_TRANSITION_NS \
                  SYNTH_INPUT_DELAY_MAX_NS SYNTH_INPUT_DELAY_MIN_NS \
                  SYNTH_OUTPUT_DELAY_MAX_NS SYNTH_OUTPUT_DELAY_MIN_NS \
                  SYNTH_DRIVING_CELL SYNTH_OUTPUT_LOAD_PF
# One ID per make invocation. Refuse an existing ID so old results stay intact.
ifeq ($(origin RUN_ID),undefined)
RUN_ID := $(shell date -u +%Y%m%dT%H%M%SZ)-$(shell echo $$$$)
endif
# Quote configuration values when embedding them in a shell recipe.
# Indirection keeps metadata recording from making this a recursive make recipe.
MAKE_PROGRAM := $(MAKE)
shquote = '$(subst ','"'"',$(1))'

UNIT_TOPS := ALU_tb be_decoder_tb branch_predictor_tb control_tb \
             hazard_detection_tb reader_tb registers_tb signextender_tb
PROGRAMS := instr_mem_test directed random
MEMORY_MODES := fast sync delayed
PREFETCH_MODES := 0 1
UNIT_TESTS := $(addprefix unit-,$(UNIT_TOPS))
CPU_TESTS := $(foreach pf,$(PREFETCH_MODES),$(foreach p,$(PROGRAMS),$(foreach m,$(MEMORY_MODES),cpu-$(p)-$(m)-pf$(pf))))
SRAM_TESTS := sram-port sram-system
TESTS := $(UNIT_TESTS) $(CPU_TESTS) $(SRAM_TESTS)

MEM_fast := +imem_delay=0 +dmem_delay=0 +backpressure=0
MEM_sync := +imem_delay=1 +dmem_delay=1 +backpressure=0
MEM_delayed := +imem_delay=7 +dmem_delay=19 +backpressure=1

.PHONY: help prepare check-tools session all test units cpu sram $(TESTS)
help:
	@printf '%s\n' \
	  'make prepare  Generate workloads and source manifests; no simulator runs.' \
	  'make units    Run the $(words $(UNIT_TOPS)) active module benches.' \
	  'make cpu      Run 18 CPU cases: 3 programs x 3 memory modes x prefetch off/on.' \
	  'make sram     Run the SRAM adapter and system benches.' \
	  'make all      Run all suites, stopping at the first failure.' \
	  'make cpu-directed-delayed-pf1 VCD=1  Run one case with waveforms.' \
	  'make sram SRAM_MODEL=vendor SRAM_ROOT=/path/to/CF_SRAM_1024x32' \
	  'make -n cpu   Preview commands without running them.' \
	  'make synth-check    Validate synthesis configuration/paths without DC.' \
	  'make synth-prepare  Snapshot inputs and record a DC command; no DC runs.' \
	  'make synth          Prepare a fresh run and run Design Compiler.' \
	  'make synth-run      Run the latest prepared snapshot (load Synopsys setup.csh first).' \
	  'make synth-summary  Recover summary from existing reports; no DC runs.' \
	  'make synth SYNTH_PERIOD_NS=10 RUN_ID=tt-10ns  Run a new clock experiment.' \
	  'Synthesis defaults: cpu_sram_system, TT, 20 ns, PREDICT=1, PREFETCH=0.' \
	  'Synthesis run layout and assumptions: synth/README.md.' \
	  '' \
	  'First enter tcsh and source /tools/software/cadence/setup.csh.' \
	  'Options: BUILD_DIR, RUN_ID, PYTHON, XRUN, XRUN_FLAGS, SEED, SIM_TIMEOUT (seconds), VCD=1.' \
	  'Shared workloads/manifests: BUILD_DIR/inputs/{programs,manifests}/.' \
	  'Each simulation invocation: BUILD_DIR/runs/<UTC timestamp>-<PID>/ (or RUN_ID=your-label).' \
	  'Each run saves invocation.txt, commands.sh, results.tsv, and input snapshots.' \
	  'Each test has command.sh and separate logs/, waves/, and work/ directories.' \
	  'BUILD_DIR/latest points to the newest run; earlier runs are preserved.' \
	  'The functional SRAM model has no physical timing checks.'

# Preparation is independent of the simulator and handles spaces in this repo's path.
prepare:
	@root="$$(pwd -P)"
	mkdir -p -- "$(BUILD_DIR)/inputs/programs" "$(BUILD_DIR)/inputs/manifests" "$(BUILD_DIR)/runs"
	out="$$(cd -- "$(BUILD_DIR)" && pwd -P)"
	programs="$$out/inputs/programs"
	manifests="$$out/inputs/manifests"
	# Remove obsolete shared inputs from earlier layouts; saved runs stay untouched.
	rm -f -- "$$manifests/PipeRegister_tb.f" "$$manifests/forwarding_unit_tb.f" \
	  "$$manifests/memory_tb.f" "$$programs/data_mem_test.hex"
	# Keep a preparation record even when no simulation is requested.
	{
	    printf '# Prepared at %s (UTC)\n' "$$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	    printf '%q ' "$(PYTHON)" "$$root/sim/programs.py" "$$programs"; printf '\n'
	    printf '%q ' cp -- "$$root"/sim/fixtures/*.hex "$$programs/"; printf '\n'
	} > "$$out/inputs/prepare.log"
	"$(PYTHON)" "$$root/sim/programs.py" "$$programs"
	cp -- "$$root"/sim/fixtures/*.hex "$$programs/"
	manifest() {
	    local dest="$$1" source
	    shift
	    while IFS= read -r source || [[ -n "$$source" ]]; do
	        [[ -z "$$source" || "$$source" == \#* ]] && continue
	        [[ -f "$$root/$$source" ]] || { echo "Missing RTL source: $$source" >&2; return 1; }
	        printf '"%s/%s"\n' "$$root" "$$source"
	    done < "$$root/rtl/files.f" > "$$dest"
	    for source in "$$@"; do printf '"%s"\n' "$$source"; done >> "$$dest"
	}
	manifest "$$manifests/core.f" "$$root/sim/support/latency_memory.sv" "$$root/sim/tb/cpu_tb.sv"
	for top in $(UNIT_TOPS); do
	    manifest "$$manifests/$$top.f" "$$root/sim/tb/$$top.sv"
	done
	manifest "$$manifests/sram.f"
	while IFS= read -r source || [[ -n "$$source" ]]; do
	    [[ -z "$$source" || "$$source" == \#* ]] && continue
	    printf '"%s/%s"\n' "$$root" "$$source"
	done < "$$root/rtl/system.f" >> "$$manifests/sram.f"
	case "$(SRAM_MODEL)" in
	    functional) printf '"%s/sim/support/cf_sram_model.sv"\n' "$$root" >> "$$manifests/sram.f" ;;
	    vendor)
	        [[ -n "$(SRAM_ROOT)" ]] || { echo 'Set SRAM_ROOT for vendor simulation.' >&2; exit 1; }
	        base="$$(cd -- "$(SRAM_ROOT)" && pwd -P)"
	        for source in "$$base/hdl/CF_SRAM_1024x32.v" "$$base/hdl/beh_models/CF_SRAM_1024x32.tt_180V_25C.v"; do
	            [[ -f "$$source" ]] || { echo "Missing vendor view: $$source" >&2; exit 1; }
	            printf '"%s"\n' "$$source" >> "$$manifests/sram.f"
	        done ;;
	    *) echo 'SRAM_MODEL must be functional or vendor.' >&2; exit 1 ;;
	esac
	printf '"%s/sim/tb/sram_port_tb.sv"\n"%s/sim/tb/cpu_sram_system_tb.sv"\n' "$$root" "$$root" >> "$$manifests/sram.f"
	printf 'Prepared workloads and manifests in %s; no simulator invoked.\n' "$$out"

check-tools:
	@command -v "$(XRUN)" >/dev/null || { echo 'Load /tools/software/cadence/setup.csh in tcsh first.' >&2; exit 1; }
	command -v timeout >/dev/null

# Create a fresh run directory after shared inputs and tools are ready.
# Manifests reference live RTL; hashes identify that source state, not a source snapshot.
session: prepare check-tools
	@root="$$(pwd -P)"
	out="$$(cd -- "$(BUILD_DIR)" && pwd -P)"
	run_id=$(call shquote,$(RUN_ID))
	[[ "$$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$$ ]] || { echo 'RUN_ID must contain only letters, digits, dots, underscores or hyphens, starting with a letter/digit.' >&2; exit 1; }
	run="$$out/runs/$$run_id"
	mkdir -- "$$run" || { echo "Run already exists; choose a new RUN_ID: $$run_id" >&2; exit 1; }
	mkdir -- "$$run/tests"
	cp -a -- "$$out/inputs" "$$run/inputs"
	cp -- "$$root/Makefile" "$$run/Makefile.snapshot"
	{
	    printf 'Started (UTC): %s\nProject: %s\n' "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$root"
	    printf 'Make goals: %s\nMake flags: %s\n' $(call shquote,$(MAKECMDGOALS)) $(call shquote,$(MAKEFLAGS))
	    printf 'Effective invocation (run from project directory):\n'
	    printf '%q ' $(call shquote,$(MAKE_PROGRAM)) $(foreach goal,$(MAKECMDGOALS),$(call shquote,$(goal))) \
	      $(foreach v,BUILD_DIR RUN_ID PYTHON XRUN XRUN_FLAGS SEED SIM_TIMEOUT VCD SRAM_MODEL SRAM_ROOT,$(call shquote,$(v)=$($(v))))
	    printf '\nGit HEAD: '; git rev-parse HEAD 2>/dev/null || printf 'unavailable\n'
	    printf 'RTL and bench contents are identified by sources.sha256; they are not copied.\n'
	    printf 'Load the same lab environment before replaying commands.sh.\n'
	} > "$$run/invocation.txt"
	# Include generator and manifest-listed HDL in the source fingerprint.
	{
	    printf '%s\n' "$$root/sim/programs.py"
	    cat "$$run/inputs/manifests/"*.f | sed 's/^"//; s/"$$//'
	} | sort -u | while IFS= read -r source; do sha256sum -- "$$source"; done > "$$run/sources.sha256"
	printf '#!/usr/bin/env bash\nset -euo pipefail\n# Source the lab environment before replaying these commands.\n' > "$$run/commands.sh"
	printf 'status\ttest\texit_code\telapsed_seconds\n' > "$$run/results.tsv"
	ln -sfnT -- "runs/$$run_id" "$$out/latest"
	printf 'Run directory: %s\n' "$$run"

all test: units cpu sram
units: $(UNIT_TESTS)
cpu: $(CPU_TESTS)
sram: $(SRAM_TESTS)

# Target-specific settings select a top and manifest for the common recipe below.
$(foreach top,$(UNIT_TOPS),$(eval unit-$(top): TOP := $(top)))
$(foreach top,$(UNIT_TOPS),$(eval unit-$(top): MANIFEST := $(top).f))
define cpu_case
cpu-$(1)-$(2)-pf$(3): TOP := cpu_tb
cpu-$(1)-$(2)-pf$(3): MANIFEST := core.f
cpu-$(1)-$(2)-pf$(3): PLUSARGS := +program=$(1).hex $(MEM_$(2)) $(if $(filter 1,$(3)),+define+TEST_PREFETCH) $(if $(and $(filter delayed,$(2)),$(filter-out instr_mem_test,$(1))),+coverage)
endef
$(foreach pf,$(PREFETCH_MODES),$(foreach p,$(PROGRAMS),$(foreach m,$(MEMORY_MODES),$(eval $(call cpu_case,$(p),$(m),$(pf))))))
sram-port: TOP := sram_port_tb
sram-system: TOP := cpu_sram_system_tb
$(SRAM_TESTS): MANIFEST := sram.f

# A simulator exit error, logged assertion/timing error, or missing $finish fails make.
# Vendor timing checks and modeled delays are never disabled by this recipe.
$(TESTS): session
	@root="$$(pwd -P)"
	out="$$(cd -- "$(BUILD_DIR)" && pwd -P)"
	run="$$out/runs/$(RUN_ID)"
	name="$@"
	case_dir="$$run/tests/$$name"
	mkdir -p -- "$$case_dir/logs" "$$case_dir/work" "$$case_dir/waves"
	cp -- "$$run/inputs/programs/"*.hex "$$case_dir/work/"
	simulator="$$(command -v "$(XRUN)")"
	[[ "$$simulator" == /* ]] || simulator="$$root/$$simulator"
	command=(timeout --kill-after=10s "$(SIM_TIMEOUT)" "$$simulator" -64bit -sv \
	  -f "$$run/inputs/manifests/$(MANIFEST)" -top "$(TOP)" -seed "$(SEED)" \
	  -l "$$case_dir/logs/xrun.log" $(XRUN_FLAGS) $(PLUSARGS) $(if $(filter 1,$(VCD)),+vcd))
	# Record resolved argv and cwd before execution, including commands that fail.
	{
	    printf '#!/usr/bin/env bash\nset -euo pipefail\n(\n  cd -- %q\n  ' "$$case_dir/work"
	    printf '%q ' "$${command[@]}"
	    printf '> %q 2>&1\n)\n' "$$case_dir/logs/console.log"
	} > "$$case_dir/command.sh"
	printf '\n# %s\n' "$$name" >> "$$run/commands.sh"
	tail -n +3 "$$case_dir/command.sh" >> "$$run/commands.sh"
	printf 'RUNNING\n' > "$$case_dir/status.txt"
	cd -- "$$case_dir/work"
	status=0
	started=$$SECONDS
	"$${command[@]}" > "$$case_dir/logs/console.log" 2>&1 || status=$$?
	elapsed=$$((SECONDS - started))
	# The bench writes VCD in its cwd; preserve it for this case even on failure.
	if [[ -f cpu.vcd ]]; then mv -- cpu.vcd "$$case_dir/waves/"; fi
	if [[ "$$status" != 0 ]] \
	  || grep -Eiq '\*[EF],|\*W,(TCHK|TIMING)|Assertion.*failed|\bERROR\b|\bFATAL\b|timing violation' "$$case_dir/logs/console.log" \
	  || ! grep -Fq 'Simulation complete via $$finish' "$$case_dir/logs/console.log"; then
	    printf 'FAIL\n' > "$$case_dir/status.txt"
	    printf 'FAIL\t%s\t%s\t%s\n' "$$name" "$$status" "$$elapsed" >> "$$run/results.tsv"
	    printf 'FAIL %s (exit %s); see %s/logs/console.log\n' "$$name" "$$status" "$$case_dir" >&2
	    tail -n 30 "$$case_dir/logs/console.log" >&2
	    exit 1
	fi
	printf 'PASS\n' > "$$case_dir/status.txt"
	printf 'PASS\t%s\t%s\t%s\n' "$$name" "$$status" "$$elapsed" >> "$$run/results.tsv"
	printf 'PASS %s\n' "$$name"
	grep '^PASS ' "$$case_dir/logs/console.log" || true

# Synthesis uses separate run directories and never depends on simulation targets.
.PHONY: synth-check synth-prepare synth-run synth-summary synth
synth-check:
	@env $(foreach v,$(SYNTH_SETTINGS),$(if $(filter undefined,$(origin $(v))),,$(call shquote,$(v)=$($(v))))) \
	  "$(TCLSH)" synth/check_setup.tcl

synth-prepare:
	@env $(foreach v,$(SYNTH_SETTINGS),$(if $(filter undefined,$(origin $(v))),,$(call shquote,$(v)=$($(v))))) \
	  "$(TCLSH)" synth/prepare.tcl "$(SYNTH_BUILD_DIR)" $(call shquote,$(RUN_ID))
	root="$$(pwd -P)"
	run="$$(cd -- "$(SYNTH_BUILD_DIR)/runs/$(RUN_ID)" && pwd -P)"
	tool="$$(command -v "$(DC_SHELL)" || true)"
	if [[ -z "$$tool" ]]; then tool=$(call shquote,$(DC_SHELL));
	elif [[ "$$tool" != /* ]]; then tool="$$root/$$tool"; fi
	printf '%s\n' "$$tool" > "$$run/dc_tool.txt"
	command=("$$tool" -f "$$run/inputs/synth/run_synth.tcl")
	{
	    printf '#!/usr/bin/env bash\nset -euo pipefail\n# Load the Synopsys lab environment before executing.\ncd -- %q\n' "$$run/work"
	    printf '%q ' "$${command[@]}"; printf '\n'
	} > "$$run/command.sh"
	{
	    printf 'Project: %s\nMake goals: %s\nMake flags: %s\n' "$$root" $(call shquote,$(MAKECMDGOALS)) $(call shquote,$(MAKEFLAGS))
	    printf 'Design Compiler argv: '; printf '%q ' "$${command[@]}"; printf '\n'
	    printf 'Effective synthesis settings: configuration.txt and resolved_config.tcl\n'
	} > "$$run/invocation.txt"
	printf 'DC command recorded in %s/command.sh\n' "$$run"

synth: SYNTH_RUN_DIR = $(SYNTH_BUILD_DIR)/runs/$(RUN_ID)
synth: synth-prepare synth-run

synth-run:
	@run="$$(cd -- "$(SYNTH_RUN_DIR)" && pwd -P)"
	tool="$$(cat "$$run/dc_tool.txt")"
	command -v "$$tool" >/dev/null || { echo 'Load /tools/software/synopsys/setup.csh in tcsh first.' >&2; exit 1; }
	[[ "$$(cat "$$run/status.txt")" == PREPARED ]] || { echo 'This run has already started; prepare a new RUN_ID.' >&2; exit 1; }
	status=0
	bash "$$run/command.sh" 2>&1 | tee "$$run/logs/console.log" || status=$$?
	if [[ "$$status" != 0 ]] || [[ "$$(cat "$$run/status.txt")" != COMPLETED ]] \
	  || grep -Eq '^[[:space:]]*(Error:|Fatal:|SYNTHESIS_FAILED:)' "$$run/logs/console.log"; then
	    printf 'FAILED\n' > "$$run/status.txt"
	    printf 'Synthesis failed; inspect %s/logs/console.log\n' "$$run" >&2
	    exit 1
	fi
	printf 'Synthesis flow completed. Review timing/constraints; this does not establish timing closure.\n'
	cat "$$run/reports/summary.tsv"

# Reporting-only recovery preserves the original status, snapshots and outputs.
synth-summary:
	@"$(TCLSH)" synth/summarize.tcl "$(SYNTH_RUN_DIR)"
