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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

package common is

type   t_sreg is array(0 to 15) of std_logic_vector(3 downto 0);

function count_ones(s : in std_logic_vector) return integer;

function get_bit_pos(s : std_logic_vector) return integer;

end common;

package body common is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;
function count_ones(s : in std_logic_vector) return integer is
  variable temp     : integer range s'range := 0;
begin
  for ii in s'range loop
    if s(ii) = '1' then 
        temp := temp + 1; 
    end if;
  end loop;
  
  return temp;
end function count_ones;

function get_bit_pos(s : std_logic_vector) return integer is
  variable idx_last : integer range -1 to s'length-1 := -1;
begin
  for ii in s'range loop
    if s(ii) = '1' then 
        idx_last := ii;
    end if;
  end loop;
    
  return idx_last;
end function get_bit_pos;


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
