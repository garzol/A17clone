----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:33:49 10/12/2019 
-- Design Name: 
-- Module Name:    clkgen - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.Common.all;

entity clkgen is
    Port ( hiclk : in  STD_LOGIC;
	        c_a  : in  STD_LOGIC;
           nc_b : in  STD_LOGIC;
           nrst : in  STD_LOGIC;
           pps4_ph : out  pps4_ph_type;
			  diagclk  : out  STD_LOGIC);
end clkgen;

architecture Behavioral of clkgen is
--type pps4_ph_type is (idlexx, idle00, idle01, idle10, idle11, phi1A, phi1, phi2, phi3A, phi3, phi4);
signal lclk : std_logic_vector (1 downto 0) := "00";
signal lclk_prev : std_logic_vector (1 downto 0) := "00";
signal pps4_t0 : pps4_ph_type := idlexx;
signal last_pps4 : pps4_ph_type := idlexx;
signal diagclk_t0 : STD_LOGIC := '0';

begin	
	
	pps4_ph <= pps4_t0;
	diagclk <= diagclk_t0;
	
	process(hiclk)
	begin
		if rising_edge(hiclk) then
			lclk_prev <= lclk;
			lclk(1)<=c_a;
			lclk(0)<=nc_b;
		   if nrst = '0' then
				pps4_t0 <= idlexx;
			else
				case lclk is 
					when "00" =>
						if lclk_prev = "10" then
							pps4_t0 <= phi1A;
						elsif lclk_prev = "01" then
							pps4_t0 <= phi2;
						elsif lclk_prev = "00" then
							null;
						else
							pps4_t0 <= idle00;
						end if;
					when "10" =>
						if lclk_prev = "00" then
							pps4_t0 <= phi3A;
						elsif lclk_prev = "11" then
							pps4_t0 <= phi4;
						elsif lclk_prev = "10" then
							null;
						else
							pps4_t0 <= idle10;
						end if;				
					when "11" =>
						if lclk_prev = "10" then
							pps4_t0 <= phi3;
						elsif lclk_prev = "11" then
							null;
						else
							pps4_t0 <= idle11;
						end if;				
					when "01" =>
						if lclk_prev = "00" then
							pps4_t0 <= phi1;
						elsif lclk_prev = "01" then
							null;
						else
							pps4_t0 <= idle01;
						end if;				
					when others =>
						null;
				end case;
			end if; --end if nrst
		end if;

	end process;

	
	process(hiclk)
		variable v_diagcycle : natural range 0 to 5000000 := 0;
		variable v_count : natural range 0 to 5 := 0;
	begin
		if rising_edge(hiclk) then
			last_pps4 <= pps4_t0;
			v_diagcycle := v_diagcycle + 1;
			if v_diagcycle = 5000000 then
				if v_count < 5 then
					diagclk_t0 <= '0';
				else
					diagclk_t0 <= '1';
				end if;
				v_diagcycle := 0;
				v_count := 0;
			end if;
			if last_pps4 /= pps4_t0 then
				case pps4_t0 is
					when phi1A =>
						if last_pps4 = phi4 then
							v_count := v_count + 1;
						else
							v_count := 0;
						end if;
					when phi1 =>
						if last_pps4 = phi1A then
							v_count := v_count + 1;
						else
							v_count := 0;
						end if;
					when phi2 =>
						if last_pps4 = phi1 then
							v_count := v_count + 1;
						else
							v_count := 0;
						end if;
					when phi3A =>
						if last_pps4 = phi2 then
							v_count := v_count + 1;
						else
							v_count := 0;
						end if;
					when phi3 =>
						if last_pps4 = phi3A then
							v_count := v_count + 1;
						else
							v_count := 0;
						end if;
					when phi4 =>
						if last_pps4 = phi3 then
							v_count := v_count + 1;
						else
							v_count := 0;
						end if;
					when others =>
							v_count := 0;
				end case;	
				if v_count > 5 then
					v_count := 5;
				end if;
			end if;
			
				
		end if;

	end process;
	

end Behavioral;
	
			
		

