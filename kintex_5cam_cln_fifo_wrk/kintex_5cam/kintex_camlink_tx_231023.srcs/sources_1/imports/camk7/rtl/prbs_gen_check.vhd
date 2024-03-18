----------------------------------------------------------------------------
-- DESCRIPTION
----------------------------------------------------------------------------
--   This module generates or check a PRBS pattern. The following table shows how  
--   to set the GENERICS for compliance to ITU-T Recommendation O.150 Section 5.
--    
--   When the CHK_MODE is "false", it uses a  LFSR strucure to generate the
--   PRBS pattern.
--   When the CHK_MODE is "true", the incoming data are loaded into prbs registers
--   and compared with the locally generated PRBS 
-- 
----------------------------------------------------------------------------
-- GENERICS 
----------------------------------------------------------------------------
--   CHK_MODE     : true  =>  check mode
--                  false =>  generate mode

--   INV_PATTERN  : true  =>  invert PRBS pattern
--                            in "generate mode" the generated prbs is inverted bit-wise at outputs
--                            in "check mode" the input data are inverted before processing

--   POLY_LENGTH  :           length of the polynomial (number of shift register stages)

--   POLY_TAP     :           intermediate stage that is xor-ed with the last stage to generate to next prbs bit 

--   NBITS        :           bus size of DATA_IN and DATA_OUT
--

----------------------------------------------------------------------------
-- NOTES
----------------------------------------------------------------------------
--
--
--   Set parameters to the following values for a ITU-T compliant PRBS
--------------------------------------------------------------------------------
-- POLY_LENGTH POLY_TAP INV_PATTERN  || nbr of   bit seq.   max 0      feedback   
--                                   || stages    length  sequence      stages  
-------------------------------------------------------------------------------- 
--     7          6       false      ||    7         127      6 ni        6, 7   
--     9          5       false      ||    9         511      8 ni        5, 9   
--    11          9       false      ||   11        2047     10 ni        9,11   
--    15         14       true       ||   15       32767     15 i        14,15   
--    20          3       false      ||   20     1048575     19 ni        3,20   
--    23         18       true       ||   23     8388607     23 i        18,23   
--    29         27       true       ||   29   536870911     29 i        27,29   
--    31         28       true       ||   31  2147483647     31 i        28,31   
--
-- i=inverted, ni= non-inverted
------------------------------------------------------------------------------
--
-- In the generated parallel PRBS, LSB is the first generated bit, for example
--         if the PRBS serial stream is : 000001111011... then
--         the generated PRBS with a parallelism of 3 bit becomes:
--            data_out(2) = 0  1  1  1 ... 
--            data_out(1) = 0  0  1  1 ...  
--            data_out(0) = 0  0  1  0 ... 
-- In the received parallel PRBS, LSB is oldest bit received
--
-- RESET pin is not needed for power-on reset : all registers are properly inizialized 
-- in the source code.
-- 
--------------------------------------------------------------------------------
-- PINS DESCRIPTION 
--------------------------------------------------------------------------------
--
--      RST          : in : syncronous reset active high

--      CLK          : in : system clock

--      DATA_IN      : in : inject error (in generate mode)
--                          data to be checked (in check mode)

--      EN           : in : enable/pause pattern generation/check

--      DATA_OUT     : out: generated prbs pattern (in generate mode)
--                          error found (in check mode)
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity prbs_gen_check is
   generic (      
      CHK_MODE    : boolean := true; 
      INV_PATTERN : boolean := false;
      POLY_LENGTH : natural range 2 to 63 := 7 ;
      POLY_TAP    : natural range 1 to 62 := 6 ;
      NBITS       : natural range 1 to 512 := 24
   );
   port (
      RST             : in  std_logic;                            -- sync reset active high
      CLK             : in  std_logic;                            -- system clock
      DATA_IN         : in  std_logic_vector(NBITS - 1 downto 0); -- inject error/data to be checked
      insert_error    : in  std_logic := '0';
      sync            : in  std_logic := '0';
      EN              : in  std_logic;                            -- enable/pause pattern generation
      DATA_OUT        : out std_logic_vector(NBITS - 1 downto 0):= (others => '0')  -- generated prbs pattern/errors found
   );
end prbs_gen_check;

architecture prbs_gen_check of prbs_gen_check is

   type prbs_type is array (NBITS downto 0) of std_logic_vector(1 to POLY_LENGTH);
   signal prbs       : prbs_type := (others => (others => '1'));
   signal data_in_i  : std_logic_vector(NBITS-1 downto 0);    
   signal prbs_xor_a : std_logic_vector(NBITS-1 downto 0);                                                  
   signal prbs_xor_b : std_logic_vector(NBITS-1 downto 0);                                                 
   signal prbs_msb   : std_logic_vector(NBITS downto 1); 
   signal error_reg      : std_logic_vector(NBITS-1 downto 0);
   signal DATA_OUT_int   : std_logic_vector(NBITS-1 downto 0);
      
begin 

   data_in_i <= DATA_IN when INV_PATTERN = false else (not DATA_IN);
           
   g1: for I in 0 to NBITS-1 generate            
      prbs_xor_a(I) <= prbs(I)(POLY_TAP) xor prbs(I)(POLY_LENGTH);
      prbs_xor_b(I) <= prbs_xor_a(I) xor data_in_i(I);      
      prbs_msb(I+1) <= prbs_xor_a(I) when (CHK_MODE = false or sync = '0') else data_in_i(I);        
      prbs(I+1) <= prbs_msb(I+1) & prbs(I)(1 to POLY_LENGTH-1);      
   end generate;
      
   PRBS_GEN_01 : process (CLK)
   begin
      if rising_edge(CLK) then
         if RST = '1' then
            prbs(0) <= (others => '1');
            DATA_OUT_int <= (others => '1');
         elsif EN = '1' then
            DATA_OUT_int <= prbs_xor_b;
            prbs(0) <= prbs(NBITS);                                                                  
         end if;
      end if;
   end process;
  
  error_reg <= (0 => insert_error, others => '0');
  
  DATA_OUT <= DATA_OUT_int xor error_reg;
            
end prbs_gen_check;