----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.10.2023 17:52:18
-- Design Name: 
-- Module Name: nvramMng - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.libfram.all;

entity nvramMng is
Generic (
                   g_size        : natural := 128;
                   g_baseAddr    : std_logic_vector(15 downto 0) := X"0000"
         );
Port (
                   hiclk       : in     STD_LOGIC;
                   
                   --to r/w entire memory FRAM<->RAM
                   start       : in     std_logic;                    -- rising edge to start
                   command     : in     std_logic_vector(1 downto 0); -- command to be executed
                   done        : out    std_logic;                    -- set to 0 on start until finished

                   --hold the current nibble
                   cur_nibble  : out    std_logic_vector(3 downto 0);
                   cur_addr    : in     natural range 0 to 2*g_size-1;  --cur address of the nibble in #nibbles
                   
                   --access i2C
                   scl         : inout  STD_LOGIC;
                   sda         : inout  STD_LOGIC
		   );
end nvramMng;

architecture Behavioral of nvramMng is


component i2c_master
  GENERIC(
    input_clk : INTEGER; --input clock speed from user logic in Hz
    bus_clk   : INTEGER);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component i2c_master;


constant cslavec80id : std_logic_vector(6 downto 0) := "1010000";

-- signals for iic management
signal busy_iic    : STD_LOGIC :='0';
signal i2c_addr    : std_logic_vector (6 downto 0);
signal i2c_rw      : STD_LOGIC :='0';
signal i2c_data_wr : std_logic_vector (7 downto 0);
signal i2c_data_rd : std_logic_vector (7 downto 0);

signal error_iic : STD_LOGIC :='0';
signal i2c_ena   : STD_LOGIC :='0';
signal data_iic_in  : std_logic_vector (7 downto 0);
signal addr_iic     : std_logic_vector (7 downto 0);
signal operation_iic: std_logic_vector (1 downto 0) := "00";
--now we need memory to save NVRAM...
type   t_nvram is array(0 to g_size-1) of std_logic_vector(7 downto 0);

signal NVRAM_data : t_nvram;
signal last_busy_iic: std_logic := '0';

signal reset_n : std_logic := '1';
signal done_int     : std_logic := '1';

signal last_start : std_logic := '0';

--state machine
TYPE machine IS (st_idle, st_reset, st_writeByte, st_writeAll, st_readAll,  st_stop); --needed states
SIGNAL state         : machine;                        --state machine


begin
     cur_nibble <= NVRAM_data(cur_addr/2)(3 downto 0) when (cur_addr mod 2 = 0) else
                   NVRAM_data(cur_addr/2)(7 downto 4);
                   
     done <= done_int;

     -- test read_iic_eprom
	 process (hiclk)
		 variable stop_reading : boolean := false;
		 variable stop_writing : boolean := true;
		 variable framAddr     : integer range 0 to 31 := 0;
		 variable offs         : natural range 0 to 31 := 6;
         constant C_STRING     : string   := "AA55 Consulting group zobi";
         constant C_OFFSET     : integer range 0 to 31 := 5;
         variable sleepers     : natural range 0 to 1000000 := 0;
         variable busy_falling_edge : boolean := false;
         variable busy_cnt     : integer := 0;
         variable substate     : integer := 0;
         variable tempozobi    : character := C_STRING(1);
         
	 begin
	   if rising_edge(hiclk) then

            last_busy_iic <= busy_iic;                       --capture the value of the previous i2c busy signal
            IF(last_busy_iic = '0' AND busy_iic = '1') THEN  --i2c busy just went high
                busy_cnt := busy_cnt + 1;                    --counts the times busy has gone from low to high during transaction
            END IF;

	        last_start <= start;
	        
	        case state is 
	           when st_idle =>
	               substate := 0;
	               if last_start = '0' and start = '1' then
	                   done_int <= '0';
	                   case command is 
	                       when cFramReset =>
	                           state <= st_reset;
	                       when cFramRead =>
	                           busy_cnt := 0;
	                           state <= st_readAll;
	                       when cFramWrite =>
	                           busy_cnt := 0;
	                           state <= st_writeAll;
	                       when others =>
	                           state <= st_stop;
	                   end case;
	               end if;

	           when st_stop =>
	               done_int <= '1';
	               state <= st_idle;
	               
	           when st_reset =>
                   case substate is
                       when 0 =>
                           reset_n  <= '0';
                           substate := 1;
                       when 1 =>
                           reset_n  <= '1';
                           substate := 2;
                       when others =>
                           state <= st_stop;
                    end case; --end casesubstate
                    
	           when st_writeAll =>
                   case busy_cnt is  
                        when 0      => 
                            i2c_ena <= '1';
                            i2c_rw <= '0';                            
                            i2c_data_wr <= g_baseAddr(15 downto 8);    -- MSB address
                        when 1      =>
                            i2c_data_wr <= g_baseAddr(7 downto 0);    -- MSB address
                        when others =>
                            --temporary for unary tests
                            if busy_cnt    < C_STRING'length +2 then 
                                i2c_data_wr <= std_logic_vector(to_unsigned(character'pos(C_STRING(busy_cnt-1)), 8));
                            elsif busy_cnt < g_size+2 then  --we are at memory rank busy_cnt-2
                                i2c_data_wr <= NVRAM_data(busy_cnt-2);
                            else
                                i2c_ena <= '0';
                                state <= st_stop;
                            end if;
                    end case; --end case busy_cnt
                                
	           when st_readAll =>
                   case busy_cnt is  
                        when 0      => 
                            i2c_ena <= '1';
                            i2c_rw <= '0';                            
                            i2c_data_wr <= g_baseAddr(15 downto 8);    -- MSB address
                        when 1      =>
                            i2c_data_wr <= g_baseAddr(7 downto 0);    -- MSB address
                        when 2      =>
                            --reverse write to read
                            i2c_rw <= '1';   --operation is now read                                                      
                        when others =>
                            if busy_cnt < g_size+3 then  --we are at memory rank busy_cnt-2
                                IF(busy_iic = '0') THEN  
                                    NVRAM_data(busy_cnt-3) <= i2c_data_rd;
                                end if;
                            else
                                i2c_ena <= '0';
                                state <= st_stop;
                            end if;
                   end case; --end case busy_cnt
               
               when st_writeByte =>
                    null;
                    
               when others =>
                   i2c_ena <= '0';
                   state <= st_stop;       
	        end case; --end case state        
                   
  
		end if; -- end if rising_edge sysclock
	 end process;
	


      NVRAM_IIC :  i2c_master
       Generic Map (
                input_clk   => 50_000_000, --input clock speed from user logic in Hz
                bus_clk     => 400_000)   --speed the i2c bus (scl) will run at in Hz
       Port Map ( 
               clk          => hiclk,
               reset_n      => reset_n,				-- Reset for I2C Master
               ena          => i2c_ena,	        -- Rising edge sensitive
               addr         => cslavec80Id,	    -- I2C Address of EEPROM
               rw           => i2c_rw,          --'0' is write, '1' is read
               data_wr      => i2c_data_wr,                --data to write to slave
               busy         => busy_iic,        --indicates transaction in progress
               data_rd      => i2c_data_rd,                --data read from slave
               ack_error    => error_iic,                --flag if improper acknowledge from slave
               sda          => sda,         --serial data output of i2c bus
               scl          => scl);            --serial clock output of i2c bus
    




end Behavioral;
