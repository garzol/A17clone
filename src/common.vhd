--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package common is

type pps4_ph_type is (idlexx, idle00, idle01, idle10, idle11, phi1A, phi1, phi2, phi3A, phi3, phi4);

constant cKLA : STD_LOGIC_VECTOR := "1110";
constant cKLB : STD_LOGIC_VECTOR := "1101";
constant cKDN : STD_LOGIC_VECTOR := "0011";
constant cKER : STD_LOGIC_VECTOR := "0110";


constant cSES : STD_LOGIC := '0';
constant cSOS : STD_LOGIC := '1';

constant cROMSELCONFIG_U4CE : STD_LOGIC := '1'; --match against rrsel verified during field tests 
                                                --(check against content u4_ce.bin frome MAME)
constant cROMSELCONFIG_U5CF : STD_LOGIC := '0'; --match against rrsel verified during field tests
                                                --(check against content u5_cf.bin frome MAME)
constant cROMSEL : STD_LOGIC := cROMSELCONFIG_U5CF; --match against rrsel

constant cIONUMCONFIG_U4CE : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100"; --match against IO Device num (to be confirmed)
constant cIONUMCONFIG_U5CF : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010"; --match against IO Device num (confirmed)
constant cIONUMCONFIG :      STD_LOGIC_VECTOR(3 DOWNTO 0) := cIONUMCONFIG_U5CF; --match against IO Device num

constant cDEVNUM : STD_LOGIC_VECTOR(3 DOWNTO 0) := cIONUMCONFIG; --match against io device num (guessed value)
                                                           --we inferred that this was 
																			  --THE value of A1752CF IO dev num


--Nota: For A1753 the conf should be as follows: AB8=1 AND RAMSEL=0
----A1752 RAM
constant cRAMSEL : STD_LOGIC := '0'; --match against rrsel
constant cRAMAB8 : STD_LOGIC := '0'; --match against AB8 code we think the good value is 0
--A1753 RAM
--constant cRAMSEL : STD_LOGIC := '0'; --match against rrsel
--constant cRAMAB8 : STD_LOGIC := '1'; --match against AB8 code we think the good value is 1

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end common;

package body common is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end common;
