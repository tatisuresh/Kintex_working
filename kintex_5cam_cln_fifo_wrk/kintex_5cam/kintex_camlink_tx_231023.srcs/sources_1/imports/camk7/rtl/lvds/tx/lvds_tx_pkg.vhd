library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lvds_tx_pkg is
function calc_total_links(in_str : string;LVDS_LINK_WIDTH : natural) return natural;
end lvds_tx_pkg;
package body lvds_tx_pkg is
function calc_total_links(in_str : string;LVDS_LINK_WIDTH : natural) return natural is
begin
  if(in_str = "TRUE") then
    return LVDS_LINK_WIDTH + 1;
  else
    return LVDS_LINK_WIDTH;
  end if;
end function calc_total_links;
end lvds_tx_pkg;

    