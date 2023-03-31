----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:10:29 04/21/2021 
-- Design Name: 
-- Module Name:    mngios - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.Common.all;

entity mngios is
    Port ( c_a : out  STD_LOGIC;
           nc_b : out  STD_LOGIC;
           SYSCLK : in  STD_LOGIC;
           rst : in  STD_LOGIC);

end mngios;

architecture Behavioral of mngios is

begin


end Behavioral;

