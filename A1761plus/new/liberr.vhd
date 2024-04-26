----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.10.2023 11:52:43
-- Design Name: 
-- Module Name: liberr - Behavioral
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


package liberr is
constant cnoErr         : std_logic_vector(7 downto 0) := X"00";
constant cSysClkSyncErr : std_logic_vector(7 downto 0) := X"01";
constant cResetErr      : std_logic_vector(7 downto 0) := X"02";
end liberr;

package body liberr is

end liberr;