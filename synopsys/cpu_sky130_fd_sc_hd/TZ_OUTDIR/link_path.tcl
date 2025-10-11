setConf REF_LIBS [list \
  sky130_fd_sc_hd.ndm \
]

lappend ::search_path .
lappend ::search_path /tech/sky130/libs/sky130_library/ndm

set ::link_library *
lappend ::link_library *
lappend ::link_library sky130_fd_sc_hd__ff_100C_1v65
# process_label : (none)
# process : 1
# voltage : 1.6500
# temperature : 100.0000

setConf MODE "func"
setConf CORNER "nominal"
