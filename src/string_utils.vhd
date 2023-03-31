

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;

package str_utils is
  function str_to_slv (s: string) return std_logic_vector;
end package str_utils;

package body str_utils is

--convert string to slv
    function str_to_slv(s: string) return std_logic_vector is 
        constant ss: string(1 to s'length) := s; 
        variable answer: std_logic_vector(1 to 8 * s'length); 
        variable p: integer; 
        variable c: integer; 
    begin 
        for i in ss'range loop
            p := 8 * i;
            c := character'pos(ss(i));
            answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
        end loop; 
        return answer; 
    end function; 
	 
-- end convert to slv
end package body str_utils;

