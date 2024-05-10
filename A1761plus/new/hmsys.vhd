----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.04.2024 18:57:04
-- Design Name: 
-- Module Name: hmsys - Behavioral
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
-- when areset is high, addresses are reset to 0
library UNISIM;
use UNISIM.VComponents.all;

entity hmsys is
    Port (
           hiclk       : in        STD_LOGIC;
           nEn         : in        std_logic;
           aClk        : in        STD_LOGIC;
           aReset      : in        STD_LOGIC;
           dout        : out       STD_LOGIC;
           din         : in        STD_LOGIC;
           wEn         : in        STD_LOGIC
          );
end hmsys;

architecture Behavioral of hmsys is

COMPONENT CD4040
  PORT (
    CLK : IN STD_LOGIC;
    SCLR : IN STD_LOGIC;
    Q : OUT STD_LOGIC_VECTOR(9 DOWNTO 0) 
  );
END COMPONENT;

COMPONENT HM6508
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) 
  );
END COMPONENT;

signal HMADDR    : STD_LOGIC_VECTOR(9 DOWNTO 0);
signal WENABL    : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal DOUTA_INT : STD_LOGIC_VECTOR(0 DOWNTO 0);


--next 2 lines to avoid pointless warnings about black boxes (advice from https://www.xilinx.com/support/answers/9838.html)
attribute box_type : string; 
attribute box_type of CD4040    : component is "black_box"; 
attribute box_type of HM6508    : component is "black_box"; 

begin

--dout      <= not DOUTA_INT(0); --allows to get 500, but well... (hminitram installed)
--dout      <= DOUTA_INT(0);   --gives 508 (?)    (hminitram installed)
WENABL(0) <=   not wEn;

--that is not satisfying because we don't take into account the delay 
--between enalbe and write enable during which dout is still Hi-Z
--while here it will output data during the time chip is enable but not yet /WE
--but that me enough to get it work, then...
dout      <= DOUTA_INT(0) when wEn='1' and  nEn='0' else
             'Z';
          
MYCOUNTER : CD4040
  PORT MAP (
    CLK => not aClk,  --Rising edge clock signal, I think not or not not will don't care
    SCLR => aReset,   --Synchronous Clear: forces the output to a low state when driven high
    Q => HMADDR
  );

MYRAMCMOS : HM6508
  PORT MAP (
    clka   => hiclk,
    ena    => not nEn, --nEn is active low
    wea    => WENABL,
    addra  => HMADDR,
    dina   => (0 => not din), --not: because the ttl value is (not F/F state) of IO01
    --dina   => (0 => din),
    douta  => DOUTA_INT
  );
  
  
end Behavioral;
