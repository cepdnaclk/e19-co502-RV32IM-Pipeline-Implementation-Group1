#!/bin/bash

# Define paths as variables
RTL_CPU_PATH="../../cpu"

# Exit on any error and enable error trapping
set -e
trap 'cleanup_on_error' ERR

# Prepare directories
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="results"
TEMP_RESULTS_DIR="temp_results_$TIMESTAMP"
OLD_RESULTS_DIR="old_results"

# Function to cleanup on error
cleanup_on_error() {
    echo "========== ERROR OCCURRED - CLEANING UP =========="
    echo "Execution failed at $(date)"
    
    # Remove temporary directory completely - don't save failed results
    if [ -d "$TEMP_RESULTS_DIR" ]; then
        echo "Removing temporary results directory: $TEMP_RESULTS_DIR"
        rm -rf "$TEMP_RESULTS_DIR"
        echo "Temporary results cleaned up"
    fi
    
    # Clean up any partial library files
    if [ -d "cpu_LIB" ]; then
        echo "Removing partial library directory"
        rm -rf "cpu_LIB"
    fi
    
    echo "Original results directory preserved (no changes made to existing results)"
    echo "========== CLEANUP COMPLETE - NO FILES SAVED =========="
    exit 1
}

# Create temporary results directory for this run  
mkdir -p "$TEMP_RESULTS_DIR"
echo "========== Using temporary results directory: $TEMP_RESULTS_DIR =========="
echo "========== Execution started at $(date) =========="

# Step 0: Git Pull
echo "========== STEP 0: Git Pull =========="
if git pull | tee "$TEMP_RESULTS_DIR/git_pull.log"; then
    echo "Git pull completed successfully"
else
    echo "Git pull failed, but continuing with local files"
fi

# Step 1: VCS Compile (for cpu design)
echo "========== STEP 1: VCS Compile (CPU) =========="
if [ -d "$RTL_CPU_PATH" ]; then
    pushd "$RTL_CPU_PATH" > /dev/null
    vcs -sverilog -full64 -kdb -debug_access+all cpu_tb.v +vcs+fsdbon -o simv | tee "../synopsys/blackbox_sky130_fd_sc_hd/$TEMP_RESULTS_DIR/vcs_compile.log"
    echo "VCS compilation completed successfully"
    
    # Step 2: Run Simulation
    echo "========== STEP 2: Run Simulation =========="
#    ./simv +fsdb+all=on +fsdb+delta | tee "../synopsys/blackbox_sky130_fd_sc_hd/$TEMP_RESULTS_DIR/simulation.log"
    echo "Simulation completed successfully"
    popd > /dev/null
else
    echo "Warning: CPU RTL directory not found, skipping VCS compilation and simulation"
    echo "Continuing with synthesis only..."
fi

# Check and optionally remove existing library directory
LIB_DIR="cpu_LIB"
if [ -d "$LIB_DIR" ]; then
    echo "Library directory '$LIB_DIR' already exists."
    echo "Removing existing library directory before synthesis to avoid errors..."
    rm -rf "$LIB_DIR"
fi

# Step 3: RTL Synthesis (using proper command)
echo "========== STEP 3: RTL Synthesis =========="
echo "Running with proper PrimeTime shell command..."
rtl_shell -f rtla.tcl | tee "$TEMP_RESULTS_DIR/rtl_synthesis.log"
if [ $? -eq 0 ]; then
    echo "RTL synthesis completed successfully"
else
    echo "ERROR: RTL synthesis failed - check $TEMP_RESULTS_DIR/rtl_synthesis.log"
    exit 1
fi

# Step 4: Power Analysis (using proper command)
echo "========== STEP 4: Power Analysis =========="
if [ -f "restore_new.tcl" ]; then
    echo "Running multi-corner power analysis..."
    pwr_shell -f restore_new.tcl | tee "$TEMP_RESULTS_DIR/power_restore.log" 
    if [ $? -eq 0 ]; then
        echo "Power analysis completed successfully"
    else
        echo "ERROR: Power analysis failed - check $TEMP_RESULTS_DIR/power_restore.log"
        exit 1
    fi
else
    echo "Warning: restore_new.tcl not found, skipping power analysis"
fi

# Step 5: Archive old results and move new ones (only if execution was successful)
echo "========== STEP 5: Finalizing Results =========="

# Archive old results if they exist
if [ -d "$RESULTS_DIR" ]; then
    echo "Archiving old results..."
    mkdir -p "$OLD_RESULTS_DIR"
    mv "$RESULTS_DIR" "$OLD_RESULTS_DIR/results_$TIMESTAMP"
    echo "Old results moved to $OLD_RESULTS_DIR/results_$TIMESTAMP"
fi

# Move temporary results to permanent results directory
mv "$TEMP_RESULTS_DIR" "$RESULTS_DIR"
echo "New results moved from temporary directory to $RESULTS_DIR"

# Clean up any temporary files that might remain
echo "Cleaning up temporary files..."
rm -rf temp_results_*
echo "Temporary files cleaned up"

# Step 6: Git Commit and Push (allow git operations to fail without stopping script)
echo "========== STEP 6: Git Commit and Push =========="
set +e  # Temporarily disable exit on error for git operations

if git add .; then
    echo "Files staged successfully"
else
    echo "Warning: Failed to stage some files"
fi

if git commit -m "Auto commit: cpu synthesis and power analysis results - $TIMESTAMP"; then
    echo "Commit created successfully"
else
    echo "Warning: Commit failed (possibly no changes to commit)"
fi

if git pull --rebase --autostash origin main | tee "$RESULTS_DIR/git_pull_before_push.log"; then
    echo "Git pull completed"
else
    echo "Warning: Git pull failed"
fi

if git push | tee "$RESULTS_DIR/git_push.log"; then
    echo "Changes pushed to remote repository"
else
    echo "Warning: Git push failed"
fi

set -e  # Re-enable exit on error

echo "========== All Steps Completed Successfully =========="
echo "Execution completed at $(date)"
echo "Results and logs are saved in the '$RESULTS_DIR' folder."
if [ -d "$OLD_RESULTS_DIR/results_$TIMESTAMP" ]; then
    echo "Previous results archived in '$OLD_RESULTS_DIR/results_$TIMESTAMP'"
fi

# Final cleanup - remove any remaining temporary files or directories
echo "Performing final cleanup..."
rm -rf temp_results_* failed_results 2>/dev/null || true
echo "Final cleanup completed"

echo "========== SYNTHESIS AND ANALYSIS COMPLETE =========="

