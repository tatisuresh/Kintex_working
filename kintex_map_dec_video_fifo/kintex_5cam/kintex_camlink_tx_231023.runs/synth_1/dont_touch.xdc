# This file is automatically generated.
# It contains project source information necessary for synthesis and implementation.

# XDC: imports/camk7/fpga_top.xdc

# IP: ip/clk_wiz_1/clk_wiz_1.xci
set_property KEEP_HIERARCHY SOFT [get_cells -hier -filter {REF_NAME==clk_wiz_1 || ORIG_REF_NAME==clk_wiz_1} -quiet] -quiet

# XDC: d:/kintex_map_dec_video_fifo/kintex_5cam/kintex_camlink_tx_231023.gen/sources_1/ip/clk_wiz_1/clk_wiz_1_board.xdc
set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==clk_wiz_1 || ORIG_REF_NAME==clk_wiz_1} -quiet] {/inst } ]/inst ] -quiet] -quiet

# XDC: d:/kintex_map_dec_video_fifo/kintex_5cam/kintex_camlink_tx_231023.gen/sources_1/ip/clk_wiz_1/clk_wiz_1.xdc
#dup# set_property KEEP_HIERARCHY SOFT [get_cells [split [join [get_cells -hier -filter {REF_NAME==clk_wiz_1 || ORIG_REF_NAME==clk_wiz_1} -quiet] {/inst } ]/inst ] -quiet] -quiet

# XDC: d:/kintex_map_dec_video_fifo/kintex_5cam/kintex_camlink_tx_231023.gen/sources_1/ip/clk_wiz_1/clk_wiz_1_ooc.xdc
