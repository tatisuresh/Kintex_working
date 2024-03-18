LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


ENTITY error_counter IS
  generic(
	count_width   : positive := 32;
	data_width   : positive := 32
          );
   port(
	rst          : in  STD_LOGIC;
	clk          : in  STD_LOGIC;
	ce           : in  STD_LOGIC;
	
    valid_in     : in  STD_LOGIC;
	din          : in  STD_LOGIC_VECTOR (data_width-1 downto 0); 	
	din_ref      : in  STD_LOGIC_VECTOR (data_width-1 downto 0); 
	rst_count    : in  STD_LOGIC; --pulse
	snap_count   : in  STD_LOGIC;
	
	eflag        : out STD_LOGIC;
    s_ecount     : out STD_LOGIC_VECTOR (count_width-1 downto 0);
    s_count      : out STD_LOGIC_VECTOR (count_width-1 downto 0)
	);
END error_counter ;

ARCHITECTURE rtl OF error_counter IS
    function f_log2valid_inil(x: integer) return positive is
        variable x_tmp : integer;
        variable y     : positive;
    begin
        x_tmp := x - 1;
        y := 1;
        if x_tmp > 1 then
            while x_tmp > 1 loop
                y := y + 1;
                x_tmp := x_tmp / 2;
            end loop;
        end if;
        return y;
    end;

constant biterr_bw     : natural := f_log2valid_inil(data_width);
type UnsignedArray_t   is array (natural range <>) of unsigned(biterr_bw-1 downto 0);

signal valid_d         :  std_logic;
signal biterr          :  UnsignedArray_t(data_width/4-1 downto 0);
signal bitall          :  UnsignedArray_t(data_width/4-1 downto 0);
signal n_errors        :  unsigned(biterr_bw-1 downto 0);
signal n_bits          :  unsigned(biterr_bw downto 0);

signal ecount        :  unsigned (count_width-1 downto 0);
signal count         :  unsigned (count_width-1 downto 0);
signal rst_count_d   :  std_logic;

BEGIN
  
biterrs : process ( clk, rst )
variable biterr_v    :  UnsignedArray_t((data_width/4)-1 downto 0);
variable bitall_v    :  UnsignedArray_t((data_width/4)-1 downto 0);
variable n_errors_v  :  unsigned(biterr_bw-1 downto 0);
variable n_bits_v    :  unsigned(biterr_bw downto 0);
  begin
    if rst = '1' then
	  valid_d       <= '0';
	  
      s_ecount      <= (others => '0');
      s_count       <= (others => '0');
 
      biterr        <= (others => (others => '0' ));
      bitall        <= (others => (others => '0' ));
      n_errors      <= (others => '0');      
      n_bits        <= (others => '0');      	  
    elsif rising_edge ( clk ) then
      if ce = '1' then
        valid_d          <= valid_in;
		
        if valid_in  = '1' then    
          --initialize error counter variables
          biterr_v       := (others => (others => '0' ));
          bitall_v       := (others => (others => '0' ));
          for i in (data_width/4)-1 downto 0 loop
	         for j in 3 downto 0 loop
			    bitall_v(i) := bitall_v(i) + 1;                -- error counting has been broken
                if din_ref((i*4)+j) /= din((i*4)+j) then             -- for better timing the bit
                  biterr_v(i) := biterr_v(i) + 1;                -- error counting has been broken
                end if;  
            end loop;  -- j
	      end loop; --i 
          bitall     <= bitall_v;
          biterr     <= biterr_v;
        else
          biterr     <= (others => (others => '0' ));
          bitall     <= (others => (others => '0' ));
        end if;		
		
        if valid_d  = '1' then    
	      n_errors_v     := (others => '0');
	      n_bits_v       := (others => '0');
          for i in (data_width/4)-1 downto 0 loop
	        n_bits_v   := n_bits_v   + bitall(i); --note down that bitall is a signal
	        n_errors_v := n_errors_v + biterr(i); --note down that biterr is a signal
	      end loop; --i 
          n_errors   <= n_errors_v; 
		  n_bits     <= n_bits_v;
        else
          n_errors   <= (others => '0');		
          n_bits     <= (others => '0');		
        end if;		  

        if(snap_count = '1') then           -- snap counter
          s_ecount <= std_logic_vector(ecount);               -- totol bit error at snap time
          s_count  <= std_logic_vector(count);                -- total 10 bit word revalid_inive at snap time
        end if;
      end if; --ce
    end if;   --clk
  end process ;

errcount : process (clk, rst)
  begin
    if rst = '1' then
      rst_count_d   <= '0';
      ecount        <= (others => '0');
      count         <= (others => '0');
      eflag         <= '0';
    elsif rising_edge (clk) then 
        rst_count_d <= rst_count;
        if (rst_count_d = '1') then
          eflag    <= '0';
        elsif (ce = '1' and std_logic_vector(n_errors) /= "00000") then
          eflag    <= '1';
	    end if;

        if (rst_count_d = '1') then
          ecount <= (others=>'0');
          count  <= (others=>'0');
        elsif(ce = '1') then
          ecount <= ecount + n_errors;
          count  <= count  + n_bits;
        end if;        
    end if;
  end process ;
  
END rtl;
