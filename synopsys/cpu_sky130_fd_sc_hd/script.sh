#!/bin/bash

# Define paths as variables
RTL_CPU_PATH="../../cpu"

# Exit on any error and enable error trapping
set -e
trap 'cleanup_on_error' ERR

# Prepare directories
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_BASE_DIR="results"
TEMP_RESULTS_DIR="temp_results_$TIMESTAMP"
FAILED_DIR="failed"

# Function to cleanup on error
cleanup_on_error() {
    echo "========== ERROR OCCURRED - SAVING TO FAILED FOLDER =========="
    echo "Execution failed at $(date)"
    
    # Remove any previous failed results (keep only latest failure)
    if [ -d "$FAILED_DIR" ]; then
        echo "Removing previous failed results"
        rm -rf "$FAILED_DIR"
    fi
    
    # Save current attempt to failed directory
    if [ -d "$TEMP_RESULTS_DIR" ]; then
        echo "Saving failed attempt to: $FAILED_DIR"
        mv "$TEMP_RESULTS_DIR" "$FAILED_DIR"
        echo "Failed results saved in $FAILED_DIR for debugging"
    fi
    
    # Clean up any partial library files
    if [ -d "cpu_LIB" ]; then
        echo "Removing partial library directory"
        rm -rf "cpu_LIB"
    fi
    
    echo "========== CLEANUP COMPLETE - FAILED RESULTS SAVED IN $FAILED_DIR =========="
    exit 1
}

# Create temporary results directory for this run  
mkdir -p "$TEMP_RESULTS_DIR"

# Export TEMP_RESULTS_DIR as environment variable for TCL scripts to use
export TEMP_RESULTS_DIR
echo "========== Using temporary results directory: $TEMP_RESULTS_DIR =========="
echo "========== Environment variable TEMP_RESULTS_DIR exported for TCL scripts =========="
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
    vcs -sverilog -full64 -kdb -debug_access+all cpu_tb.v +vcs+fsdbon -o simv | tee "../synopsys/cpu_sky130_fd_sc_hd/$TEMP_RESULTS_DIR/vcs_compile.log"
    echo "VCS compilation completed successfully"
    
    # Step 2: Run Simulation
    echo "========== STEP 2: Run Simulation =========="
    ./simv +fsdb+all=on +fsdb+delta | tee "../synopsys/cpu_sky130_fd_sc_hd/$TEMP_RESULTS_DIR/simulation.log"
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

# Step 5: Save successful results (only if execution was successful)
echo "========== STEP 5: Saving Successful Results =========="

# Create results base directory if it doesn't exist
mkdir -p "$RESULTS_BASE_DIR"

# Move temporary results to timestamped subdirectory in results
FINAL_RESULTS_DIR="$RESULTS_BASE_DIR/$TIMESTAMP"
mv "$TEMP_RESULTS_DIR" "$FINAL_RESULTS_DIR"
echo "Successful results saved to: $FINAL_RESULTS_DIR"

# Clean up any old temporary files
echo "Cleaning up old temporary files..."
rm -rf temp_results_* 2>/dev/null || true
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

if git pull --rebase --autostash origin main | tee "$FINAL_RESULTS_DIR/git_pull_before_push.log"; then
    echo "Git pull completed"
else
    echo "Warning: Git pull failed"
fi

if git push | tee "$FINAL_RESULTS_DIR/git_push.log"; then
    echo "Changes pushed to remote repository"
else
    echo "Warning: Git push failed"
fi

set -e  # Re-enable exit on error

echo "========== All Steps Completed Successfully =========="
echo "Execution completed at $(date)"
echo "Results and logs are saved in: $FINAL_RESULTS_DIR"

# Final cleanup - remove any remaining temporary files or directories
echo "Performing final cleanup..."
rm -rf temp_results_* 2>/dev/null || true
echo "Final cleanup completed"

echo "========== SYNTHESIS AND ANALYSIS COMPLETE =========="

