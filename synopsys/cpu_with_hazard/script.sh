#!/bin/bash

# Prepare directories
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="results"
OLD_RESULTS_DIR="old_results"

# Step -1: Archive old results if they exist
if [ -d "$RESULTS_DIR" ]; then
    echo "========== Archiving old results =========="
    mkdir -p "$OLD_RESULTS_DIR"
    mv "$RESULTS_DIR" "$OLD_RESULTS_DIR/results_$TIMESTAMP"
    echo "Old results moved to $OLD_RESULTS_DIR/results_$TIMESTAMP"
fi

# Now create a fresh results directory
mkdir -p "$RESULTS_DIR"

# Step 0: Git Pull
echo "========== STEP 0: Git Pull =========="
git pull | tee "$RESULTS_DIR/git_pull.log"

# Step 1: VCS Compile (inside cpu/)
echo "========== STEP 1: VCS Compile =========="
pushd ../../cpu > /dev/null
vcs -sverilog -full64 -kdb -debug_access+all cpu_tb.v +vcs+fsdbon -o simv | tee "../synopsys/cpu_with_hazard/$RESULTS_DIR/vcs_compile.log"

# Step 2: Run Simulation
echo "========== STEP 2: Run Simulation =========="
./simv +fsdb+all=on +fsdb+delta | tee "../synopsys/cpu_with_hazard/$RESULTS_DIR/simulation.log"
popd > /dev/null

# Check and optionally remove existing library directory
LIB_DIR="cpu_LIB"
if [ -d "$LIB_DIR" ]; then
    echo "Library directory '$LIB_DIR' already exists."
    echo "Removing existing library directory before synthesis to avoid errors..."
    rm -rf "$LIB_DIR"
fi


# Step 3: RTL Synthesis
echo "========== STEP 3: RTL Synthesis =========="
rtl_shell -f rtla.tcl | tee "$RESULTS_DIR/rtl_synthesis.log"

# Step 4: Power Restoration
echo "========== STEP 4: Power Restoration =========="
pwr_shell -f restore_new.tcl | tee "$RESULTS_DIR/power_restore.log"

# Step 5: Git Commit and Push
echo "========== STEP 5: Git Commit and Push =========="
git add .
git commit -m "Auto commit: results and logs after synthesis and power analysis"
git pull --rebase --autostash origin main | tee "$RESULTS_DIR/git_pull_before_push.log"
git push | tee "$RESULTS_DIR/git_push.log"

echo "========== All Steps Completed =========="
echo "Results and logs are saved in the '$RESULTS_DIR' folder."

