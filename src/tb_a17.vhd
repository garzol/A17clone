--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:51:05 10/29/2019
-- Design Name:   
-- Module Name:   C:/Users/a030466/Downloads/a17bas2/tb_a17.vhd
-- Project Name:  a17base
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ioctrl
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
use work.Common.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_a17 IS
END tb_a17;
 
ARCHITECTURE behavior OF tb_a17 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ioctrl
    PORT( 
--           IO_6 : inout  STD_LOGIC; --added lately, not wired on pcb cf_2.0
--           IO_7 : inout  STD_LOGIC; --added lately, not wired on pcb cf_2.0
           IO : inout  STD_LOGIC_VECTOR(15 DOWNTO 0);
           TESTLED : out  STD_LOGIC;
           INITLED : out  STD_LOGIC;
           SYSCLK : in  STD_LOGIC;
           nCKB : in  STD_LOGIC;
           CKA : in  STD_LOGIC;
           SPO : in  STD_LOGIC;
           nRRSEL : in  STD_LOGIC;
           nW_IO : in  STD_LOGIC;
			  nAB : IN STD_LOGIC_VECTOR(11 DOWNTO 1);
			  nDO : inout STD_LOGIC_VECTOR(8 DOWNTO 1)); --inout after the hw modif with 8xR=30K
--			  ID : IN STD_LOGIC_VECTOR(8 DOWNTO 5));   --not used anymore
	
    END COMPONENT;
    
	component mak_ckab
		 Port ( c_a : out  STD_LOGIC;
				  nc_b : out  STD_LOGIC;
				  SYSCLK : in  STD_LOGIC;
				  rst : in  STD_LOGIC);
	end component;

	component clkgen 
		 Port ( hiclk : in  STD_LOGIC;
				  c_a : in  STD_LOGIC;
				  nc_b : in  STD_LOGIC;
				  pps4_phi : out  pps4_ph_type);
	end component;
	
	component div17
		 Port ( ckin : in  STD_LOGIC;
				  ckout : out  STD_LOGIC);
	end component;
	
   --Inputs
   signal SYSCLK : std_logic := '0';
   signal nCKB : std_logic  := '0';
   signal CKA : std_logic   := '0';
   signal SPO : std_logic   := '0';
   signal RRSEL : std_logic := '0';
   signal W_IO : std_logic  := '0';
   signal AB : std_logic_vector(11 downto 1) := (others => '0');
   signal ID : std_logic_vector(8 downto 5) := (others => '0');
   signal CK3MHZ : STD_LOGIC := '0';

	--BiDirs
   signal SIMIO_VEC : STD_LOGIC_VECTOR(15 DOWNTO 0):= "10ZX10ZX10ZX10ZX";


 	--Outputs
   signal TESTLED : std_logic;
   signal INITLED : std_logic;
   signal DO : std_logic_vector(8 downto 1);
   signal X : std_logic_vector(8 downto 1);
   signal pps4_phi_tb : pps4_ph_type;

   -- Clock period definitions
   constant SYSCLK_period : time := 20 ns;  --50MHz
 
BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: ioctrl PORT MAP (
          SIMIO_VEC,
          TESTLED,
          INITLED,
          SYSCLK,
          nCKB,
          CKA,
          SPO,
          RRSEL,
          W_IO,
          AB,
          DO
        );

	 D17    : div17 PORT MAP(SYSCLK, CK3MHZ);
    GENAB : mak_ckab     PORT MAP (CKA, nCKB, CK3MHZ, '1');
	 PHIGN : clkgen       port map (SYSCLK, CKA, nCKB, pps4_phi_tb);

   -- Clock process definitions
   SYSCLK_process :process
   begin
		SYSCLK <= '0';
		wait for SYSCLK_period/2;
		SYSCLK <= '1';
		wait for SYSCLK_period/2;
   end process;
 
 
    -- Stimulus process synced with phi
   stim_sync_proc: process(pps4_phi_tb)
   Variable Count1 : Integer range 0 to 255 := 0;
   begin		
		case pps4_phi_tb is
			when phi1A =>
				if Count1 > 127 then
					W_IO <= '1';  --0 for ram sel or 1 for IO sel
				else 
					W_IO <= '0';
				end if;
				if (Count1 mod 2 ) = 0 then
					RRSEL <= '1';
					AB <= "00010000111";
				else
					RRSEL <= '1';
					AB <= "00000000111";
				end if;
			when phi1 =>
				Count1 := Count1 + 1 mod 256;
				AB <= "ZZZZZZZZZZZ";
				DO <= "ZZZZZZZZ";
				RRSEL <= '0';
				W_IO <= '0';
			when phi2 =>
			   --write 5 to ram 87
				W_IO <= '1';
				X <= std_logic_vector(to_unsigned(Count1, 8));
				DO(8 downto 5) <= X(4 downto 1);
				--next lines for rom
				if (Count1 mod 2 ) = 0 then
					RRSEL <= '1';
					AB <= "00000000110";
				else
					RRSEL <= '1';
					AB <= "00000001011";
				end if;
				--end rom
			when phi3A =>
			   --write 5 to ram 87
				W_IO <= '1';
				X <= std_logic_vector(to_unsigned(Count1, 8));
				DO(8 downto 5) <= X(4 downto 1);
				--next lines for rom
				if (Count1 mod 2 ) = 0 then
					RRSEL <= '1';
					AB <= "00000000110";
				else
					RRSEL <= '1';
					AB <= "00000001011";
				end if;
			when phi3 =>
				RRSEL <= '0';
				W_IO <= '0';
				AB <= "ZZZZZZZZZZZ";
				DO <= "ZZZZZZZZ";
			when phi4 =>
				if Count1 > 127 then
					W_IO <= '1';  --0 for ram sel or 1 for IO sel
				else 
					W_IO <= '0';
				end if;
				if (Count1 mod 2 ) = 0 then
					RRSEL <= '1';
					AB <= "00010000111";
				else
					RRSEL <= '1';
					AB <= "00000000111";
				end if;
			when others =>
				null;
				
		end case;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
 		SPO <= '1';
     -- hold reset state for 100 ns.
      wait for 10 us;	
 		SPO <= '0';

      wait for SYSCLK_period*10;

      -- insert stimulus here 

      -- insert stimulus here 
      wait for 50 us;	

      -- insert stimulus here 
      wait for 50 us;	

      -- insert stimulus here 
      wait for 50 us;	

      -- insert stimulus here 
      wait for SYSCLK_period*10;


      wait;
   end process;

END;
