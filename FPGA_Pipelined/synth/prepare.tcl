# Pure Tcl preparation. Run via make synth-prepare; no EDA tool is launched.
proc write_text {path text} {
    set channel [open $path w]
    puts $channel $text
    close $channel
}
proc tree_files {directory} {
    set files {}
    foreach path [glob -nocomplain -directory $directory *] {
        if {[file isdirectory $path]} {
            lappend files {*}[tree_files $path]
        } else {
            lappend files $path
        }
    }
    return [lsort $files]
}
if {[catch {
    if {[llength $argv] != 2} { error "Usage: tclsh synth/prepare.tcl BUILD_DIR RUN_ID" }
    source [file join [file dirname [info script]] config.tcl]
    synthcfg::validate
    lassign $argv build_root run_id
    if {![regexp {^[A-Za-z0-9][A-Za-z0-9._-]*$} $run_id]} { error "Invalid RUN_ID: $run_id" }
    set build_root [file normalize $build_root]
    set run [file join $build_root runs $run_id]
    if {[file exists $run]} { error "Run already exists; choose a new RUN_ID: $run" }
    file mkdir $run
    foreach name {inputs logs reports outputs work alib} { file mkdir [file join $run $name] }
    set source_project $synthcfg::project_dir
    file copy [file join $source_project rtl] [file join $run inputs rtl]
    file copy [file join $source_project synth] [file join $run inputs synth]
    file copy [file join $source_project Makefile] [file join $run inputs Makefile.snapshot]

    # Serialize all effective values; future environment changes cannot silently
    # alter this run. Source paths point at the saved RTL and scripts.
    set channel [open [file join $run resolved_config.tcl] w]
    puts $channel "# Effective configuration for this prepared run."
    foreach key $synthcfg::keys {
        set value [set ::synthcfg::$key]
        if {$key eq "project_dir"} { set value [file join $run inputs] }
        puts $channel [list set ::synthcfg::$key $value]
    }
    puts $channel [list set ::synthcfg::run_dir $run]
    close $channel
    set channel [open [file join $run configuration.txt] w]
    synthcfg::describe $channel
    puts $channel "source_project              $source_project"
    puts $channel "prepared_utc                [clock format [clock seconds] -gmt 1 -format %Y-%m-%dT%H:%M:%SZ]"
    if {[catch {exec git -C $source_project rev-parse HEAD} revision]} { set revision unavailable }
    puts $channel "git_commit                  $revision"
    if {[catch {exec git -C $source_project status --short -- .} changes]} { set changes unavailable }
    puts $channel "source_git_status:\n$changes"
    close $channel

    set copied_files [tree_files [file join $run inputs]]
    write_text [file join $run sources.sha256] [exec sha256sum -- {*}$copied_files]
    set libraries [list $synthcfg::std_db]
    if {$synthcfg::top eq "cpu_sram_system"} { lappend libraries $synthcfg::sram_db }
    write_text [file join $run libraries.sha256] [exec sha256sum -- {*}$libraries]
    write_text [file join $run status.txt] PREPARED
    set latest [file join $build_root latest]
    if {[file exists $latest] || ![catch {file type $latest}]} {
        if {[file type $latest] ne "link"} { error "Refusing to replace non-symlink: $latest" }
        file delete $latest
    }
    file link -symbolic $latest $run
    puts "Prepared synthesis run: $run"
    puts "No Design Compiler or synthesis was run."
} message]} {
    puts stderr "Synthesis preparation failed: $message"
    exit 1
}
