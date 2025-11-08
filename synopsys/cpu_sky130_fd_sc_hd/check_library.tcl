#!/bin/tcsh -f
# =============================================================================
# Library Diagnostic Script
# =============================================================================
# This script checks what's actually in the cpu_LIB library
# =============================================================================

source config.tcl

puts "========== Library Diagnostic =========="
puts "Library name: $LIB_NAME"
puts ""

# Check if library directory exists
if {[file exists $LIB_NAME]} {
    puts "✓ Library directory exists at: $LIB_NAME"
    puts ""
    
    # Try to open it
    if {[catch {open_lib $LIB_NAME} err]} {
        puts "✗ ERROR: Cannot open library: $err"
        exit 1
    }
    puts "✓ Library opened successfully"
    puts ""
    
    # Check for blocks
    puts "Querying blocks with different patterns..."
    puts ""
    
    # Pattern 1: Simple wildcard
    set all_blocks [get_blocks -quiet *]
    if {[llength $all_blocks] > 0} {
        puts "✓ Pattern '*' found [llength $all_blocks] block(s):"
        foreach b $all_blocks { puts "  - [get_object_name $b]" }
    } else {
        puts "✗ Pattern '*' found nothing"
    }
    
    # Pattern 2: lib:design
    set blk2 [get_blocks -quiet ${LIB_NAME}:${DESIGN_NAME}]
    if {[llength $blk2] > 0} {
        puts "✓ Pattern '${LIB_NAME}:${DESIGN_NAME}' found [llength $blk2] block(s):"
        foreach b $blk2 { puts "  - [get_object_name $b]" }
    } else {
        puts "✗ Pattern '${LIB_NAME}:${DESIGN_NAME}' found nothing"
    }
    
    # Pattern 3: lib:design with label
    set blk3 [get_blocks -quiet ${LIB_NAME}:${DESIGN_NAME} -label rtla_optimized]
    if {[llength $blk3] > 0} {
        puts "✓ Pattern '${LIB_NAME}:${DESIGN_NAME} -label rtla_optimized' found [llength $blk3] block(s):"
        foreach b $blk3 { puts "  - [get_object_name $b]" }
    } else {
        puts "✗ Pattern '${LIB_NAME}:${DESIGN_NAME} -label rtla_optimized' found nothing"
    }
    
    # Pattern 4: Just design name
    set blk4 [get_blocks -quiet ${DESIGN_NAME}]
    if {[llength $blk4] > 0} {
        puts "✓ Pattern '${DESIGN_NAME}' found [llength $blk4] block(s):"
        foreach b $blk4 { puts "  - [get_object_name $b]" }
    } else {
        puts "✗ Pattern '${DESIGN_NAME}' found nothing"
    }
    
    # Pattern 5: Get all blocks in library
    set blk5 [get_blocks -quiet -of_objects [get_libs $LIB_NAME]]
    if {[llength $blk5] > 0} {
        puts "✓ Pattern 'get_blocks -of_objects [get_libs]' found [llength $blk5] block(s):"
        foreach b $blk5 { puts "  - [get_object_name $b]" }
    } else {
        puts "✗ Pattern 'get_blocks -of_objects [get_libs]' found nothing"
    }
    
    puts ""
    puts "Library structure:"
    puts "  Main dir: [file normalize $LIB_NAME]"
    if {[catch {exec ls -la $LIB_NAME} contents]} {
        puts "  Cannot list contents: $contents"
    } else {
        puts "$contents"
    }
    
    # Try to list design subdirectory
    if {[file exists $LIB_NAME/$DESIGN_NAME]} {
        puts ""
        puts "Design subdirectory contents:"
        if {[catch {exec ls -la $LIB_NAME/$DESIGN_NAME} design_contents]} {
            puts "  Cannot list: $design_contents"
        } else {
            puts "$design_contents"
        }
    }
    
    # Now try to actually open a block if we found any
    set found_blocks [concat $all_blocks $blk2 $blk3 $blk4 $blk5]
    if {[llength $found_blocks] > 0} {
    # Now try to actually open a block if we found any
    set found_blocks [concat $all_blocks $blk2 $blk3 $blk4 $blk5]
    if {[llength $found_blocks] > 0} {
        puts ""
        puts "=========================================="
        puts "✓ SUCCESS: Found at least one block!"
        puts "=========================================="
        puts "Attempting to open first block..."
        set test_blk [lindex $found_blocks 0]
        puts "Block to open: [get_object_name $test_blk]"
        
        if {[catch {open_block $test_blk} err]} {
            puts "✗ ERROR opening block: $err"
        } else {
            puts "✓ Successfully opened block!"
            set cb [current_block]
            if {$cb ne ""} {
                puts "  Current block: [get_object_name $cb]"
            }
        }
    } else {
        puts ""
        puts "=========================================="
        puts "✗ PROBLEM: No blocks found with any pattern!"
        puts "=========================================="
        puts "The design files exist but blocks are not queryable."
        puts "This might be a library version or tool issue."
    }
    
} else {
    puts "✗ Library directory does NOT exist"
    puts "Expected location: [file normalize $LIB_NAME]"
}

puts ""
puts "========== End Diagnostic =========="
exit
