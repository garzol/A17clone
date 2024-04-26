----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.11.2023 11:07:39
-- Design Name: 
-- Module Name: pps4bus - Behavioral
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

use work.libpps4.all;

entity pps4bus is
     Port ( hiclk    : in    STD_LOGIC;
            spo      : in    std_logic;
            pps4_phi : in    pps4_ph_type;
            nid      : in    std_logic_vector(8 downto 1);
            ndo      : out   std_logic_vector(8 downto 1);
            bid      : inout std_logic_vector(8 downto 1);
            seldirdl : out   std_logic;
            seldirdh : out   std_logic
          );
end pps4bus;

architecture Behavioral of pps4bus is

signal seldirdl_int : std_logic := '1';
signal seldirdh_int : std_logic := '1';

begin

    seldirdl_int      <=  '0'             when bid(4 downto 1) /= "ZZZZ" else
                         '1';
    seldirdl          <= seldirdl_int;
    
    seldirdh_int      <= '0'              when bid(8 downto 5) /= "ZZZZ" else
                         '1';
    seldirdh          <= seldirdh_int;
  
    bid               <= nid;
                           
    ndo(4 downto 1)   <= bid(4 downto 1) when seldirdl_int = '0' else
                        (others => '1');
                         
    ndo(8 downto 5)   <= bid(8 downto 5) when seldirdh_int = '0' else
                        (others => '1');
                         


end Behavioral;
