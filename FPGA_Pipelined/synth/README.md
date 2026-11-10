# Design Compiler baseline

This flow prepares an integrated CPU/SRAM synthesis experiment using the local
Georgia Tech/SiliconJackets collateral. Scripts and RTL are snapshotted per run;
licensed library/model files remain in the lab checkout. No synthesis results
are supplied with these scripts. The project owner runs Design Compiler.

## Commands

Run from `FPGA_Pipelined/`:

```text
make synth-check                     # Pure Tcl setup/path checks; no DC
make synth-prepare                   # Snapshot inputs and record command; no DC
```

Then load the Synopsys environment in tcsh:

```tcsh
source /tools/software/synopsys/setup.csh
make synth-run                       # Run the latest PREPARED snapshot
```

Alternatively, prepare and run together with a fresh ID:

```tcsh
make synth RUN_ID=tt-baseline-01
make synth SYNTH_PERIOD_NS=10 RUN_ID=tt-10ns-01
```

Omit `RUN_ID` to generate a UTC timestamp/PID identifier. Existing run names
are rejected. `synth-run` rejects a run that has already started, preserving
prior outputs. To run a particular prepared snapshot:

```tcsh
make synth-run SYNTH_RUN_DIR=build/synth/runs/tt-baseline-01
```

For direct invocation after loading the environment, the recorded
`build/synth/latest/command.sh` changes into the correct work directory and
starts DC using the saved Tcl. Running it directly does not tee console output;
`make synth-run` captures that output in `logs/console.log`.

`synth-check` checks paths/settings/Tcl completeness. It is not HDL compilation,
DB loading, Design Compiler execution, or evidence of timing closure.

## Recorded baseline

| Setting | Default |
|---|---|
| Top | `cpu_sram_system` |
| CPU parameters | `PREDICT=1`, `PREFETCH=0` |
| Memories | Two `CF_SRAM_1024x32` macro cells, 4 KiB per port |
| Mapping library | Regular `sky130_tt_1.8_25.db` only |
| SRAM library | `CF_SRAM_1024x32_tt_180V_25C.db` |
| Corner | Nominal TT, 1.8 V, 25 C |
| Clock | 20 ns, waveform `{0 10}`; 50 MHz *target* |
| Setup/hold uncertainty | 0.2 / 0.1 ns |
| Clock transition | 0.1 ns |
| Input delay min/max | 0.2 / 2.0 ns |
| Output delay min/max | 0.2 / 2.0 ns |
| Input driver | `BUFX2`, excluding `clk` |
| Output load | 0.033442 pF per output, following the lab example |
| Compile | `compile -map_effort high`, up to four cores |
| Interconnect | Library-default wire-load behavior in `top` mode; no extracted parasitics |

The I/O budgets, uncertainty, and loading are **experimental assumptions**.
They are not measured package/host requirements or signoff constraints. The
clock period is a requested constraint, not an achieved-frequency claim.

The lab setup was adapted rather than sourced wholesale. The reference lab
flow maps with TT and HS libraries while applying SS/FF analysis conditions.
This flow starts with one regular TT cell library and a matching TT SRAM view;
it does not claim worst-corner or multi-corner coverage. The standard-cell
condition is `tt_1.8_25`; the SRAM library's nominal condition is `Typ` at the
same voltage/temperature. No DFT, automatic clock gating, or measured power
analysis is enabled. Scan cells matching the lab's `SDFF*` exclusion are
excluded from mapping.

Both reset/mode inputs remain constrained inputs. No case analysis, false paths,
or multicycle exceptions hide host-mode logic or adapter timing. The CPU
retirement interface remains present and its area is included. This is an
integrated-system boundary; `SYNTH_TOP=cpu` is a separate optional core-only
experiment that must not be compared as though it included SRAM.

## Libraries and overrides

Defaults reference:

```text
~/physical-design-onboarding-F26/resources/synopsys_libs/sky130_tt_1.8_25.db
~/physical-design-onboarding-F26/inputs/CF_SRAM_1024x32/db/CF_SRAM_1024x32_tt_180V_25C.db
```

`synth/config.tcl` is the source of defaults. The Makefile forwards supplied
`SYNTH_*` settings during checking/preparation. Common overrides:

```text
SYNTH_LAB_ROOT              SYNTH_TOP
SYNTH_STD_DB                SYNTH_STD_LIB
SYNTH_STD_OPCOND             SYNTH_SRAM_DB
SYNTH_SRAM_LIB              SYNTH_PERIOD_NS
SYNTH_PREDICT               SYNTH_PREFETCH
SYNTH_COMPILE_MODE          SYNTH_MAX_CORES
SYNTH_SETUP_UNCERTAINTY_NS   SYNTH_HOLD_UNCERTAINTY_NS
SYNTH_CLOCK_TRANSITION_NS   SYNTH_INPUT_DELAY_MAX_NS
SYNTH_INPUT_DELAY_MIN_NS    SYNTH_OUTPUT_DELAY_MAX_NS
SYNTH_OUTPUT_DELAY_MIN_NS   SYNTH_DRIVING_CELL
SYNTH_OUTPUT_LOAD_PF
```

`SYNTH_COMPILE_MODE=ultra` selects `compile_ultra -no_autoungroup
-no_boundary_optimization` and requires the corresponding license. Changing
cell families/compile methods is a separate experimental variable. Library
internal names must match the configured names; the driver checks them when
DC loads the DBs. Check paths alone cannot verify DB contents.

Launcher settings are `DC_SHELL` (default `dc_shell`), `TCLSH` (default `tclsh`),
and `SYNTH_BUILD_DIR` (default `build/synth`). A prepared run's resolved settings
are frozen: changing Make/environment settings during `synth-run` does not
change that snapshot. Prepare a new run to change configuration or RTL.

## Flow and artifacts

```text
build/synth/
├── latest -> runs/<run-id>
└── runs/<run-id>/
    ├── configuration.txt       # Effective values, Git revision/status
    ├── resolved_config.tcl     # Frozen Tcl configuration
    ├── invocation.txt
    ├── command.sh              # Actual DC argv and working directory
    ├── dc_tool.txt             # Prepared launcher name/path
    ├── sources.sha256
    ├── libraries.sha256        # Hashes only; DBs are not copied
    ├── status.txt              # PREPARED / RUNNING / COMPLETED / FAILED
    ├── inputs/
    │   ├── rtl/                # Source snapshot, including source lists
    │   ├── synth/              # Flow snapshot
    │   └── Makefile.snapshot
    ├── work/                   # DC WORK files and startup intermediates
    ├── alib/                   # Local library-analysis cache
    ├── logs/
    ├── reports/
    └── outputs/
```

The driver loads DBs, analyzes package/core then optional SRAM-system sources,
elaborates parameters, links and checks the design, protects the two linked
macro instances, applies constraints, compiles, and writes outputs/reports.
Testbenches, the functional SRAM model and vendor simulation HDL are excluded.

Checks stop the flow on failed analysis/elaboration/link/compile, unexpected
macro count, generic unmapped cells, and unexpected level-sensitive registers.
DC command errors also make the Make target fail. Timing/constraint violations
are reported, and may remain in a completed baseline run.

Review these files first:

- `logs/console.log`: tool errors and warnings.
- `reports/check_design_pre.rpt` and `check_design_post.rpt`: structural checks.
- `reports/check_timing.rpt`: unconstrained or otherwise problematic timing.
- `reports/constraints.rpt`: violated constraints, including pulse width/period.
- `reports/timing_setup.rpt` and `timing_hold.rpt`: worst max/min paths.
- `reports/rising_to_falling_{max,min}.rpt` and
  `falling_to_rising_{max,min}.rpt`: mixed-edge adapter paths.
- `reports/area.rpt` and `summary.tsv`: total, SRAM and logic area, and slack.
- `reports/units.rpt`: the units used by DC. Area values use library area units.

Area totals come directly from DC's saved `report_area` output. Macro area is
subtracted from total cell area to obtain non-SRAM logic area for this design.
The summary uses reported text precision and avoids per-instance area queries.
Timing slack is the minimum among paths listed in the saved timing reports.

If compilation/reports completed but old summary code failed, recover the
summary without rerunning DC:

```text
make synth-summary SYNTH_RUN_DIR=build/synth/runs/<existing-run-id>
```

This creates `reports/summary-recovered.tsv` and provenance notes. It does not
change the original run status, input snapshot, netlist, DDC, or original reports.
A historical `FAILED` status remains `FAILED`; the recovered summary records it.
Existing summary files are not overwritten. Normal future runs generate
`reports/summary.tsv` through the same report parser.

Outputs include mapped Verilog, DDC, SDC, synthesis-estimated SDF, and SVF.
The SDF is not extracted post-route timing. `COMPLETED` means the flow finished;
it does **not** mean positive slack, fully constrained timing, or physical
signoff. Reported target MHz is `1000 / period_ns`, not measured maximum MHz.
Power is marked `NOT_MEASURED`; no vectorless estimate is presented as workload
power. Keep workload CPI/cycles from simulation alongside later PPA results.
