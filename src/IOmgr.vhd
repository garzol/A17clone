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
use ieee.numeric_std.all;               -- Needed for shifts

use work.Common.all;

entity IOmgr is

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
    port  ( pps4_phi : in pps4_ph_type; 
				IOCmd : in  STD_LOGIC_VECTOR (8 downto 1);
				W_IO : in  STD_LOGIC;
            Addr : in  STD_LOGIC_VECTOR (6 downto 0);
            Din : in  STD_LOGIC_VECTOR (4 downto 1);
            Dout : out  STD_LOGIC_VECTOR (4 downto 1);
            IIO_VEC : inout STD_LOGIC_VECTOR(15 DOWNTO 0);
            OIO_VEC : inout STD_LOGIC_VECTOR(15 DOWNTO 0);
            T_ENABLE_VEC : inout STD_LOGIC_VECTOR(15 DOWNTO 0));
								
end IOmgr;

architecture Behavioral of IOmgr is


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

	variable devNum :  STD_LOGIC_VECTOR(4 DOWNTO 1);
	variable iotype :  STD_LOGIC;
	
	begin		 
		 process (pps4_phi)
		 begin
			--during phi4+phi1A, if W_IO=1 then data bus is 
			--DIO[8:5] is dev num and DIO[4:1] is command xxx0 for SES
			--or xxx1 for SOS
	
			if pps4_phi = phi1A then  
				--are we handling IO or RAM?
				if W_IO = '1' then
					--devNum is 4-bit device num. for A1752 only bits of the middle are used
					--but other devices may have numbers such as C or 3		
					devNum := IOCmd(8 downto 5);
					if (devNum = cDEVNUM) then
						iotype := IOCmd(1);
					end if; --endif devnum=cdevnum
				end if; --endif w_io
			end if;--endif pps4_phi test
		 end process;
		
end Behavioral;
