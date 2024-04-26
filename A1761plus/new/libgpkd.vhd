----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.10.2023 11:07:21
-- Design Name: 
-- Module Name: libpps4 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
package libgpkd is

constant cKTR : STD_LOGIC_VECTOR := "1100"; --transfer keyboard return
constant cKTS : STD_LOGIC_VECTOR := "1010"; --transfer keyboard strobe
constant cKLA : STD_LOGIC_VECTOR := "1110"; --load display register A
constant cKLB : STD_LOGIC_VECTOR := "1101"; --load display register B
constant cKDN : STD_LOGIC_VECTOR := "0011"; --turn on display 
constant cKER : STD_LOGIC_VECTOR := "0110"; --reset keyboard error
constant cKAF : STD_LOGIC_VECTOR := "1011"; --turn off A
constant cKBF : STD_LOGIC_VECTOR := "0111"; --turn off B


                                                         



end libgpkd;

package body libgpkd is

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
 
end libgpkd;
