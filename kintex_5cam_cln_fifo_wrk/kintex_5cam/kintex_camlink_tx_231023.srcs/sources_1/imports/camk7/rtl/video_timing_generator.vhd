 --*****************************************************************************
--  ______________
-- |              |
-- |    ^         |  Vendor             : Logic Fruit
-- |   / \        |  Version            : 1.0
-- |  /   \      _|  Application        : Project
-- |-/     \    / |  Filename           : video_timing_generator.vhd
-- |        \  /  |  Date Last Modified : $Date: 2014/11/08 16:00:45 $
-- |         \/   |  Date Created       : Mon Aug 11 2014
-- |______________|
--
-- Device           : 7 Series
-- Design Name      : VSS
-- Purpose          :
-- Reference        :
-- Revision History :
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_textio.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE std.textio.all;

entity video_timing_generator is
    generic(
      sim                            :  integer    :=  0;
      HSYNC_ACTIVE_LOW               :  STD_LOGIC  := '1';
      VSYNC_ACTIVE_LOW               :  STD_LOGIC  := '1';
      INTERLACED_VIDEO               :  integer    :=  0;
      YCBCR_422_ONE_PIXEL_PER_CLOCK  :  integer    :=  0 
    );
    port(
      -- Clock signals for SVGA 800*600 Resolution @ 60Hz frame rate at 40MHz pixel clock
      video_clk           :  in  std_logic;   -- clock input of 40MHz
      video_clk_en        :  in  std_logic;

      hactive_duration    :  in  std_logic_vector(15 downto 0) := x"0280"; --640
      vactive_duration    :  in  std_logic_vector(15 downto 0) := x"01e0"; --480
      hsync_duration      :  in  std_logic_vector(15 downto 0) := x"0060"; --096
      hback_duration      :  in  std_logic_vector(15 downto 0) := x"0030"; --048
      hfront_duration     :  in  std_logic_vector(15 downto 0) := x"0010"; --016
      vsync_duration      :  in  std_logic_vector(15 downto 0) := x"0002"; --002
      vback_duration      :  in  std_logic_vector(15 downto 0) := x"0021"; --033
      vfront_duration     :  in  std_logic_vector(15 downto 0) := x"000a"; --010

      line_count          :  out  std_logic_vector(15 downto 0);
      Hsync               :  out  std_logic;
      Vsync               :  out  std_logic;
      Hblank              :  out  std_logic;  --active high -> for horizontal blanking period it is '1'
      Vblank              :  out  std_logic;  --active high -> for vertical blanking period it is '1'
      -- Signal indicating that valid data should be available for display at data ports during timing generation
      data_en             :  out  std_logic
    );
END video_timing_generator ;

ARCHITECTURE rtl OF video_timing_generator IS

---------------------######################################################################################
--Signal declarations
---------------------######################################################################################

    -- Video timing and data signals
    signal  hactive_duration_i      :  unsigned(15 downto 0)        ;
    signal  vactive_duration_i      :  unsigned(15 downto 0)        ;
    signal  hsync_duration_i        :  unsigned(15 downto 0)        ;
    signal  hback_duration_i        :  unsigned(15 downto 0)        ;
    signal  hfront_duration_i       :  unsigned(15 downto 0)        ;
    signal  vsync_duration_i        :  unsigned(15 downto 0)        ;
    signal  vback_duration_i        :  unsigned(15 downto 0)        ;
    signal  vfront_duration_i       :  unsigned(15 downto 0)        ;
    signal  htotal_duration         :  unsigned(15 downto 0)        ;
    signal  pix_cnt                 :  unsigned(15 downto 0)        :=  (others => '0');
    signal  line_cnt                :  unsigned(15 downto 0)        :=  (others => '0');
    signal  active_pix              :  std_logic                    :=  '0';
    signal  hsync_int               :  std_logic                    :=  '0';
    signal  hsync_int_n             :  std_logic                    :=  '0';
    signal  vsync_int               :  std_logic                    :=  '0';
    signal  vsync_int_n             :  std_logic                    :=  '0';
    signal  hblank_int              :  std_logic                    :=  '0';
    signal  vblank_int              :  std_logic                    :=  '0';

    -- debug signals
    signal field_count              :  std_logic_vector(7 downto 0) := (others => '0');
    signal vsync_d                  :  std_logic                    := '0';
    signal ce                       :  std_logic                    := '0';
-----------------------------------------------------------------------------------------------------------
BEGIN

process(video_clk)
begin
  if rising_edge(video_clk) then
      hactive_duration_i  <=  unsigned(hactive_duration);
      vactive_duration_i  <=  unsigned(vactive_duration);
      hsync_duration_i    <=  unsigned(hsync_duration);
      hback_duration_i    <=  unsigned(hback_duration);
      hfront_duration_i   <=  unsigned(hfront_duration);
      vsync_duration_i    <=  unsigned(vsync_duration);
      vback_duration_i    <=  unsigned(vback_duration);
      vfront_duration_i   <=  unsigned(vfront_duration);

      htotal_duration <= hactive_duration_i + hsync_duration_i + hback_duration_i + hfront_duration_i;
      -- hhalf_duration  <= '0' & htotal_duration(15 odwnto 1);
  end if;
end process;

process(video_clk)
begin
  if rising_edge(video_clk) then
    if YCBCR_422_ONE_PIXEL_PER_CLOCK = 1 then
      ce <= '1';
    else
      ce <= not ce;
    end if;
  end if;
end process;

progressive_video_gen : if INTERLACED_VIDEO = 0 generate
  -- Process to generate video timing at 25.175MHz
  process(video_clk)
  begin
    if(rising_edge(video_clk)) then
        if(video_clk_en = '0') then
            pix_cnt     <=  (others => '0');
            line_cnt    <=  (others => '0');
            active_pix  <=  '0';
            hsync_int   <=  '0';
            hsync_int_n <=  '1';
            vsync_int   <=  '0';
            vsync_int_n <=  '1';
        elsif ce = '1' then
            if(pix_cnt = hback_duration_i + hfront_duration_i + hsync_duration_i + hactive_duration_i - 1) then
                pix_cnt <=  (others => '0');
            else
                pix_cnt <=  pix_cnt + 1;
            end if;
    
            if(line_cnt = vback_duration_i + vfront_duration_i + vsync_duration_i + vactive_duration_i - 1) then
                if(pix_cnt = hback_duration_i + hfront_duration_i + hsync_duration_i + hactive_duration_i - 1) then
                    line_cnt  <=  (others => '0');
                end if;
            else
                if(pix_cnt = hback_duration_i + hfront_duration_i + hsync_duration_i + hactive_duration_i - 1) then
                    line_cnt  <=  line_cnt + 1;
                end if;
            end if;
    
            if((pix_cnt >= 0) and (pix_cnt <= hactive_duration_i -1)) then
                if((line_cnt >= 0) and (line_cnt <= vactive_duration_i - 1)) then
                    active_pix  <=  '1';
                else
                    active_pix  <=  '0';
                end if;
            else
                active_pix  <= '0';
            end if;
    
            if (pix_cnt >= hactive_duration_i + hfront_duration_i) and (pix_cnt <= hactive_duration_i + hfront_duration_i + hsync_duration_i - 1) then
                hsync_int   <= '0';
                hsync_int_n <= '1';
            else
                hsync_int   <= '1';
                hsync_int_n <= '0';
            end if;
    -----BLANKING 
            if((pix_cnt >= 0) and (pix_cnt <= hactive_duration_i -1)) then
                hblank_int  <=  '0';
            else
                hblank_int  <=  '1';
            end if;
            if((line_cnt >= 0) and (line_cnt <= vactive_duration_i -1)) then
                vblank_int  <=  '0';
            else
                vblank_int  <=  '1';
            end if;
            
            
            if (line_cnt = vactive_duration_i + vfront_duration_i-1) and (pix_cnt >= hactive_duration_i + hfront_duration_i) then
                vsync_int   <= '0';
                vsync_int_n <= '1';
            elsif (line_cnt > vactive_duration_i + vfront_duration_i-1) and (line_cnt < vactive_duration_i + vfront_duration_i + vsync_duration_i - 1) then
                vsync_int   <= '0';
                vsync_int_n <= '1';
            elsif (line_cnt = vactive_duration_i + vfront_duration_i + vsync_duration_i - 1) and (pix_cnt < hactive_duration_i + hfront_duration_i) then
                vsync_int   <= '0';
                vsync_int_n <= '1';
            else
                vsync_int   <= '1';
                vsync_int_n <= '0';
            end if;
        else
            active_pix  <= '0';
        end if;
    end if;
  end process;
end generate progressive_video_gen;


interlaced_video_gen : if INTERLACED_VIDEO = 1 generate
  process(video_clk)
  begin
    if(rising_edge(video_clk)) then
        if(video_clk_en = '0') then
            pix_cnt       <=  (others => '0');
            line_cnt      <=  (others => '0');
            active_pix    <=  '0';
            hsync_int     <=  '0';
            hsync_int_n   <=  '0';
            vsync_int     <=  '0';
            vsync_int_n   <=  '1';
        elsif ce = '1' then
            if(pix_cnt = hback_duration_i + hfront_duration_i + hsync_duration_i + hactive_duration_i - 1) then
                pix_cnt <=  (others => '0');
            else
                pix_cnt <=  pix_cnt + 1;
            end if;
    
            if(line_cnt = vback_duration_i + vfront_duration_i + vsync_duration_i + vactive_duration_i) then
                if(pix_cnt = hback_duration_i + hfront_duration_i + hsync_duration_i + hactive_duration_i - 1) then
                    line_cnt  <=  (others => '0');
                end if;
            else
                if(pix_cnt = hback_duration_i + hfront_duration_i + hsync_duration_i + hactive_duration_i - 1) then
                    line_cnt  <=  line_cnt + 1;
                end if;
            end if;
    
            if((pix_cnt >= 0) and (pix_cnt <= hactive_duration_i -1)) then
                if((line_cnt >= 0) and (line_cnt <= vactive_duration_i(15 downto 1) - 1)) or
                    ((line_cnt >= vactive_duration_i(15 downto 1) + vfront_duration_i(15 downto 1) + vsync_duration_i(15 downto 1) + vback_duration_i(15 downto 1) + 1) and 
                    (line_cnt <= vactive_duration_i + vfront_duration_i(15 downto 1) + vsync_duration_i(15 downto 1) + vback_duration_i(15 downto 1))) then
                    active_pix  <=  '1';
                else
                    active_pix  <=  '0';
                end if;
            else
                active_pix  <= '0';
            end if;
    
            if (pix_cnt >= hactive_duration_i + hfront_duration_i) and (pix_cnt <= hactive_duration_i + hfront_duration_i + hsync_duration_i - 1) then
                hsync_int   <= '0';
                hsync_int_n <= '1';
            else
                hsync_int   <= '1';
                hsync_int_n <= '0';
            end if;

            if((pix_cnt >= 0) and (pix_cnt <= hactive_duration_i -1)) then
                hblank_int  <=  '0';
            else
                hblank_int  <=  '1';
            end if;
            if((line_cnt >= 0) and (line_cnt <= vactive_duration_i(15 downto 1) - 1)) 
              or ((line_cnt >= vactive_duration_i(15 downto 1) + vfront_duration_i(15 downto 1) + vsync_duration_i(15 downto 1) + vback_duration_i(15 downto 1) + 1) 
                  and (line_cnt <= vactive_duration_i + vfront_duration_i(15 downto 1) + vsync_duration_i(15 downto 1) + vback_duration_i(15 downto 1))) then
                vblank_int  <=  '0';
            else
                vblank_int  <=  '1';
            end if;
    
            if (line_cnt = vactive_duration_i(15 downto 1) + vfront_duration_i(15 downto 1)) and (pix_cnt >= hactive_duration_i + hfront_duration_i - htotal_duration(15 downto 1)) then
            vsync_int   <= '0';
            vsync_int_n <= '1';
            elsif (line_cnt > vactive_duration_i(15 downto 1) + vfront_duration_i(15 downto 1)) and (line_cnt < vactive_duration_i(15 downto 1) + vfront_duration_i(15 downto 1) + vsync_duration_i(15 downto 1)) then
            vsync_int   <= '0';
            vsync_int_n <= '1';
            elsif (line_cnt = vactive_duration_i(15 downto 1) + vfront_duration_i(15 downto 1) + vsync_duration_i(15 downto 1)) and
                (pix_cnt < hactive_duration_i + hfront_duration_i - htotal_duration(15 downto 1)) then
            vsync_int   <= '0';
            vsync_int_n <= '1';
            elsif (line_cnt = vactive_duration_i + vfront_duration_i + vsync_duration_i(15 downto 1) + vback_duration_i(15 downto 1)) and
                (pix_cnt >= hactive_duration_i + hfront_duration_i) then
            vsync_int   <= '0';
            vsync_int_n <= '1';
            elsif (line_cnt > vactive_duration_i + vfront_duration_i + vsync_duration_i(15 downto 1) + vback_duration_i(15 downto 1)) and
                (line_cnt < vactive_duration_i + vfront_duration_i + vsync_duration_i + vback_duration_i(15 downto 1)) then
            vsync_int   <= '0';
            vsync_int_n <= '1';
            elsif (line_cnt = vactive_duration_i + vfront_duration_i + vsync_duration_i + vback_duration_i(15 downto 1)) and
                (pix_cnt < hactive_duration_i + hfront_duration_i) then
            vsync_int   <= '0';
            vsync_int_n <= '1';
            else
            vsync_int   <= '1';
            vsync_int_n <= '0';
            end if;
        else
            active_pix  <= '0';
        end if;
    end if;
  end process;
end generate interlaced_video_gen;


-- output assignment
line_count <=  std_logic_vector(line_cnt);
data_en    <=  active_pix;
vblank     <=  vblank_int;
hblank     <=  hblank_int;
HSYNC_LOW : IF (HSYNC_ACTIVE_LOW = '1') GENERATE
hsync    <=  hsync_int;
END GENERATE HSYNC_LOW;
VSYNC_LOW : IF (VSYNC_ACTIVE_LOW = '1') GENERATE
vsync    <=  vsync_int;
END GENERATE VSYNC_LOW;
HSYNC_HIGH :IF (HSYNC_ACTIVE_LOW = '0') GENERATE
hsync    <=  hsync_int_n;
END GENERATE HSYNC_HIGH;
VSYNC_HIGH : IF (VSYNC_ACTIVE_LOW = '0') GENERATE
vsync    <=  vsync_int_n;
END GENERATE VSYNC_HIGH;


-- Debugging file writing
Debug_gen : if sim = 1 generate
process(video_clk)
begin
  if rising_edge(video_clk) then
    if video_clk_en = '0' then
      field_count <= (others => '0');
      vsync_d     <= '0';
    else
      vsync_d     <= vsync_int;
      if vsync_d = '0' and vsync_int = '1' then
        field_count <= std_logic_vector(unsigned(field_count) + 1);
      end if;
    end if;
  end if;
end process;

process(video_clk)
    file        outfile  : text open write_mode is "vga_debug_file";
    variable    outline  : line;
begin
  if rising_edge(video_clk)then
    if video_clk_en = '1' then
      write(outline,to_integer(unsigned(field_count)));
      write(outline,string'("  "));
      write(outline,to_integer(unsigned(line_cnt)));
      write(outline,string'("  "));
      write(outline,to_integer(unsigned(pix_cnt)));
      write(outline,string'("  "));
      write(outline,vsync_int);
      write(outline,string'("  "));
      write(outline,hsync_int);
      write(outline,string'("  "));
      write(outline,active_pix);
      writeline(outfile, outline);
    end if;
  end if;
end process;
end generate;

END ARCHITECTURE rtl;