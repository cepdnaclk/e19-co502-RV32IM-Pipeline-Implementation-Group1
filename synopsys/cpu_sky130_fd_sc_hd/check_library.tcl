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
    set all_blocks [get_blocks -quiet *]
    if {[llength $all_blocks] == 0} {
        puts "✗ NO BLOCKS FOUND in library"
        puts ""
        puts "Library structure:"
        puts "  Main dir: [file normalize $LIB_NAME]"
        if {[catch {exec ls -la $LIB_NAME} contents]} {
            puts "  Cannot list contents: $contents"
        } else {
            puts "$contents"
        }
    } else {
        puts "✓ Found [llength $all_blocks] block(s):"
        foreach blk $all_blocks {
            set blk_name [get_object_name $blk]
            puts "  - $blk_name"
            
            # Try to open and get info
            if {[catch {open_block $blk} err]} {
                puts "    ERROR: Cannot open: $err"
            } else {
                puts "    Successfully opened"
                set cb [current_block]
                if {$cb ne ""} {
                    puts "    Current block: [get_object_name $cb]"
                }
            }
        }
    }
    
} else {
    puts "✗ Library directory does NOT exist"
    puts "Expected location: [file normalize $LIB_NAME]"
}

puts ""
puts "========== End Diagnostic =========="
exit
