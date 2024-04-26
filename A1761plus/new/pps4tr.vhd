----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.11.2023 11:32:04
-- Design Name: 
-- Module Name: pps4tr - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

use work.common.all;
use work.libpps4.all;
use work.liberr.all;    -- list of error codes
use work.libfram.all;    -- list of error codes

entity pps4TR is
    Port ( 
           hiclk       : in     STD_LOGIC;
           spo         : in     STD_LOGIC;
           pps4_phi    : in     pps4_ph_type;
		   TXp         : out    STD_LOGIC;  
		   RXp         : in     STD_LOGIC;  
           rrsel       : in     std_logic;
           ab          : in     STD_LOGIC_VECTOR (11 downto 1);
           din         : in     STD_LOGIC_VECTOR (8 downto 1);
           status      : out    STD_LOGIC_VECTOR (7 downto 0);
           hm_user_sel : out    std_logic;
           inpx        : in     STD_LOGIC_VECTOR (15 downto 0);
           outx        : in     STD_LOGIC_VECTOR (15 downto 0);
           wio         : in     STD_LOGIC);

end pps4TR;


architecture Behavioral of pps4TR is

constant c_trfifo_length : integer := 8;      --256 slots

COMPONENT TRFIFO
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
    full : OUT STD_LOGIC;
    data_count : OUT STD_LOGIC_VECTOR(c_trfifo_length-1 DOWNTO 0);
    --almost_full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
    --data_count : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    --wr_rst_busy : OUT STD_LOGIC;
    --rd_rst_busy : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT GPFIFO
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;


component uart_rx is
 generic (
	g_CLKS_PER_BIT : integer := 2604   -- i.e. 19200bauds if clock at 50MHz Needs to be set correctly
	);
 port (
	i_clk       : in  std_logic;
	i_rx_serial : in  std_logic;
	o_rx_dv     : out std_logic;
	o_rx_byte   : out std_logic_vector(7 downto 0)
	);
end component uart_rx;
 
component uart_tx is
 generic (
	g_CLKS_PER_BIT : integer := 2604   -- Needs to be set correctly
	);
 port (
	i_clk       : in  std_logic;
	i_tx_dv     : in  std_logic;
	i_tx_byte   : in  std_logic_vector(7 downto 0);
	o_tx_active : out std_logic;
	o_tx_serial : out std_logic;
	o_tx_done   : out std_logic
	);
end component uart_tx;

component GPKD10788
    Port ( 
           hiclk         : in     STD_LOGIC;
           spo           : in     STD_LOGIC;
           pps4_phi      : in     pps4_ph_type;
           sc5           : in     STD_LOGIC;
           sc6           : in     STD_LOGIC;
           sc7           : in     STD_LOGIC;
           x             : out    STD_LOGIC_VECTOR (7 downto 0);
           dbs           : out    STD_LOGIC;

           status        : out    std_logic_vector (7 downto 0);
           RDA_data_st   : out    t_sreg;
           RDB_data_st   : out    t_sreg;
           dspl_A_off_st : out    std_logic;
           dspl_B_off_st : out    std_logic;
           
                      
           da : out STD_LOGIC_VECTOR (4 downto 1);
           db : out STD_LOGIC_VECTOR (4 downto 1);
           y  : in STD_LOGIC_VECTOR (7 downto 0);
           id : in STD_LOGIC_VECTOR (8 downto 1);
           wio: in STD_LOGIC;
           do : out STD_LOGIC_VECTOR (8 downto 1);
           dldir : out STD_LOGIC);
end component;

--uart sigs
-- constant c_CLKS_PER_BIT : integer := 2604;  --19200 bauds
constant c_CLKS_PER_BIT : integer := 434;      --115200 bauds
signal r_TX_DV     : std_logic := '0';    -- command start transmitting
signal r_TX_BYTE   : std_logic_vector(7 downto 0); -- byte to send
signal w_TX_DONE   : std_logic := '0';  -- rises when finished
signal w_TX_BUSY   : std_logic := '0';  -- 0 TX if available, 1 otherwise

signal w_RX_DV     : std_logic := '0';  --signal a byte received (stay 1 for 4 ticks)
signal w_RX_BYTE   : std_logic_vector(7 downto 0); -- byte read

signal RX_CMD      : std_logic_vector(7 downto 0) := X"00"; -- byte command


--sig_trace is set/reset by the uart rx handler when 'T' is hit
--then, the consumer process shall track rising edges on this signal
signal trace_on    : boolean   := true;  --trace from reset
signal sig_trace   : std_logic := '0'; --start trace signal. Set for 1 phi after cmd sent from uart

signal gptrace_on  : boolean   := true;  --trace from reset
signal sig_gptrace : std_logic := '0'; --start trace signal. Set for 1 phi after cmd sent from uart

signal sig_dump    : std_logic := '0'; --start dump signal. Set for 1 phi after cmd sent from uart
signal dump_on     : boolean   := false;  --trace from reset

signal sig_gpdump  : std_logic := '0'; --start dump signal. Set for 1 phi after cmd sent from uart
signal gpdump_on   : boolean   := true;  --trace from reset

signal sig_dpdump  : std_logic := '0'; --start dump signal. Set for 1 phi after cmd sent from uart
signal dpdump_on   : boolean   := false;  --this dump is activated


signal status_int : std_logic_vector(7 downto 0) := X"02"; -- light off by default
signal status_test: std_logic_vector(7 downto 0) := X"01"; -- light off by default

--this will memorize current ROM address (at phi3A)
-- Is twelve bits long: contains rrsel&AB(11..1)
signal ROM_Addr_Latch           : std_logic_vector (11 downto 0);

signal DATA_RAM_Latch           : std_logic_vector (7 downto 0);
signal DATA_ROM_Latch           : std_logic_vector (7 downto 0);

signal RRW_Latch                : std_logic;   --latch wio at phi3A
signal RIO_Latch                : std_logic;   --latch wio at phi1A
signal RESET_Latch              : std_logic;   --latch of spo
signal RRSEL_RAM_Latch          : std_logic;   --latch of spo

--this will memorize current RAM address (at phi1A)
-- Is eight bits long: contains rrsel&AB(7..1)
signal RAM_Addr_Latch           : std_logic_vector (7 downto 0);

type   t_ram is array(0 to 255) of std_logic_vector(3 downto 0);
signal RAMCPY                   : t_ram;
signal is_RAM_Device_On         : std_logic := '0';



--signals for trace fifo
signal FIFO_DIN   : STD_LOGIC_VECTOR(39 DOWNTO 0);
signal TRFIFO_DOUT  : STD_LOGIC_VECTOR(39 DOWNTO 0);

--for the trace fifo
signal ISFIFOFULL : STD_LOGIC := '0';
signal ISFIFOVOID : STD_LOGIC;
signal FIFORD : STD_LOGIC := '0';
signal FIFORDNEXT : STD_LOGIC := '0';
signal FIFOWR : STD_LOGIC := '0';
signal FIFOWR_rst : STD_LOGIC := '0';
signal FIFOWR_combi : STD_LOGIC := '0';
signal FIFORST: STD_LOGIC := '1';   --start in reset
signal FIFODCOUNT : std_logic_vector(c_trfifo_length-1 DOWNTO 0);
--signal FIFOWRRSTBUSY :std_logic;
--signal FIFORDRSTBUSY :std_logic;

--for the game prom fifo
--signals for trace fifo
signal GPFIFO_DIN   : STD_LOGIC_VECTOR(39 DOWNTO 0);
signal GPFIFO_DOUT  : STD_LOGIC_VECTOR(39 DOWNTO 0);

signal ISGPFIFOFULL : STD_LOGIC;
signal ISGPFIFOVOID : STD_LOGIC;
signal GPFIFORD     : STD_LOGIC := '0';
signal GPFIFORDNEXT : STD_LOGIC := '0';
signal GPFIFOWR     : STD_LOGIC := '0';


--for interfacing with gpkd virtual component
signal GPKD_status      : std_logic_vector(7 downto 0) := (others=>'0');
--for diag through wifi
signal RDA_data_st      :  t_sreg;
signal RDB_data_st      :  t_sreg;
signal dspl_A_off_st    :  std_logic;
signal dspl_B_off_st    :  std_logic;


--for user command of configuration
signal hm_user_sel_int  : std_logic := '0'; --default is: use intern hm

--next 2 lines to avoid pointless warnings about black boxes (advice from https://www.xilinx.com/support/answers/9838.html)
attribute box_type : string; 
attribute box_type of TRFIFO       : component is "black_box"; 

begin
    hm_user_sel  <= hm_user_sel_int;
    
    FIFOWR_combi <= FIFOWR_rst or FIFOWR;
    
    status <= status_int;
    --status <= status_test;
    
    process(hiclk)
    variable trst : natural range 0 to 150 := 0;
    begin
    if rising_edge(hiclk) then
        if trst < 10 then
            FIFORST <= '1';
        else
            FIFORST <= '0';        
        end if;
--        if trst = 60 then
--            FIFOWR_rst <= '1';
--        elsif trst = 64 then
--            FIFOWR_rst <= '0';            
--        end if;
            
        if trst < 150 then
            trst := trst+1;
        end if;
    end if;
            
    end process;
    
    
    --
    process(hiclk)
        variable    checker_flag    : std_logic := '0';
        variable    lastpps4_phi    : pps4_ph_type := idlexx;
        variable    setfifowr       : boolean := false;
        variable    setgpfifowr     : boolean := false;
        variable    lastRESET_Latch : std_logic := '1';
        
        variable    nbgp2dump       : integer range 0 to 10 := 0;
        variable    watch_next      : boolean := false; --set to true when an IOL is detected
    begin
        if rising_edge(hiclk) then    
            --state machine execution, based on phases of clka/clkb
            if (sig_trace = '1') then
                trace_on <= true;
            end if;
            if (sig_gptrace = '1') then
                gptrace_on <= true;
            end if;
            if lastpps4_phi /= pps4_phi then
                case pps4_phi is
                    when phi1A   =>
                        RAM_Addr_Latch <= ab(8 downto 1);
                        DATA_ROM_Latch <= din;
                        RIO_Latch      <= wio;
                        RESET_Latch    <= spo;
                        RRSEL_RAM_Latch<= rrsel;
                        if din = X"1C" then                  --this is an IOL
                            case ROM_Addr_Latch is
--                                when X"6CC" | X"6CE" | X"6D1" | 
--                                     X"6D4" | X"6D8" =>
--                                    null;
                                when others =>
                                    nbgp2dump := 4;
                                    watch_next := true;
                            end case;
                        else
                            if watch_next = true and din(8 downto 5) /= "0100" then
                                nbgp2dump := 0;
                            else
                                null;
                                --nbgp2dump := 4;                            
                            end if;
                            watch_next := false;
                            
                        end if;                        --snatch of ram traffic: detect if ram access
                        if wio = '0' then  --this is a ram access, not an IO
                            if (rrsel = '0') then                --1 of 2 rriots
                                is_RAM_Device_On <= '1';
                            else
                                is_RAM_device_On <= '0';
                            end if;
                        else
                            is_RAM_device_On <= '0';
                        end if;
                        
                    when phi2    =>
                        if nbgp2dump > 0 then
                            nbgp2dump := nbgp2dump-1;
                        end if;
                        --store to GPFIFO
                        if ISGPFIFOFULL = '1' then
                            gptrace_on  <= false;
                        elsif gptrace_on = true then
                            if nbgp2dump > 0 then
                                -- fifo size = 32
                                GPFIFO_DIN      <= 
                                                RAM_Addr_Latch&         -- 8b
                                                "1010"&                 -- 4b (dummy)
                                                ROM_Addr_Latch&         -- 12b
                                                DATA_RAM_Latch&         -- 8b
                                                DATA_ROM_Latch;         -- 8b

--                                GPFIFO_DIN      <= 
--                                            not RAMCPY(16#1A#)&          --4b
--                                            not RAMCPY(16#1B#)&          --4b
--                                            not RAMCPY(16#19#)&          --4b
--                                            ROM_Addr_Latch&         --12b
--                                            DATA_RAM_Latch&         -- 8b
--                                            DATA_ROM_Latch;         -- 8b
                                setgpfifowr     := true;
                            end if;
                        end if;
                                
                        
                        --time to dump to trace
                        --will store ROM_Addr (12bits)
                        --          +DATA_ROM (8bits)
                        --          +CTRL sig (3bits)
                        -- default trigger is power on...
                        if ISFIFOFULL = '1' then
                            trace_on   <= false;
                        elsif trace_on = true and FIFORST = '0' and
                              (RESET_Latch = '0' or (RESET_Latch = '1' and lastRESET_Latch = '0')) then
                            FIFO_DIN     <= 
                                            RAM_Addr_Latch&         -- 8b
                                            RRSEL_RAM_Latch&        -- 1b
                                            RIO_Latch&              -- 1b
                                            RRW_Latch&              -- 1b
                                            RESET_Latch&            -- 1b
                                            ROM_Addr_Latch&         --12b
                                            DATA_ROM_Latch&         -- 8b
                                            DATA_RAM_Latch;         -- 8b
                                            
                            setfifowr       := true;
                            checker_flag := not checker_flag;
                        end if;
                        lastRESET_Latch := RESET_Latch;
                                            
                    when phi3A   =>
                        ROM_Addr_Latch <= rrsel&ab;
                        DATA_RAM_Latch <= din;
                        RRW_Latch      <= wio;

                        --snatch of ram traffic: ram write
                        if (is_RAM_Device_On = '1') then  
                            --do we have to write to A17's ram?
                            if wio = '1' then  --it is a write 
                                RAMCPY(to_integer(unsigned(RAM_Addr_Latch))) <= din(8 downto 5); 
                            end if;
                        end if;
                        
                        
                    when phi3    =>    
                         null;
        
                    when others  =>
                        null;
                end case;
            end if;
            lastpps4_phi := pps4_phi;
            if setfifowr = true then
                FIFOWR  <= '1';
            else
                FIFOWR  <= '0';
            end if;
            setfifowr := false;
            if setgpfifowr = true then
                GPFIFOWR  <= '1';
            else
                GPFIFOWR  <= '0';
            end if;
            setgpfifowr := false;
        end if;   
    end process;

 
    GPBUF : GPFIFO      PORT MAP (
            clk    => hiclk,
            rst    => '0',
            din    => GPFIFO_DIN, 
            wr_en  => GPFIFOWR,
            rd_en  => GPFIFORDNEXT,
            dout   => GPFIFO_DOUT,
            full   => ISGPFIFOFULL,
            empty  => ISGPFIFOVOID
            );

    TRBUF : TRFIFO       PORT MAP (
										    clk => hiclk,
										    srst => FIFORST,
										    din => FIFO_DIN,
										    wr_en => FIFOWR_combi,
										    rd_en => FIFORDNEXT,
										    dout => TRFIFO_DOUT,
										    full =>  ISFIFOFULL,
										    --almost_full => ISFIFOPFULL,
										    data_count   => FIFODCOUNT,
										    --wr_rst_busy  => FIFOWRRSTBUSY,
										    --rd_rst_busy  => FIFORDRSTBUSY,
										    empty => ISFIFOVOID
									       );
  
-- Instantiate UART transmitter
UART_TX_INST : uart_tx
generic map (
  g_CLKS_PER_BIT => c_CLKS_PER_BIT
  )
port map (
  i_clk       => hiclk,
  i_tx_dv     => r_TX_DV,    -- command start transmitting
  i_tx_byte   => r_TX_BYTE,  -- byte to send
  o_tx_active => w_TX_BUSY,  -- on s'en fout c'est l'image des bits a transmettre
  o_tx_serial => TXp,        -- port tx
  o_tx_done   => w_TX_DONE   -- rises when finished (lasts 1 ticks by def)
  );


-- send uart by reading fifo
-- set by user : r_TX_DV; to be set to '0' when w_TX_DONE is read to '1' (or at init)
--                        to be set to '1' for transmitting
-- In the uart impl, one sees that after w_TX_DONE goes to 1 it is kept to 1 for one cycle before reset to 0

	 process (hiclk)
	   variable    numbyt    : natural range 0 to 7 := 0;  -- common to trfifo and gpfifo, maybe not a good id?
	   variable    numbyt_dp : natural range 0 to 7 := 0;  -- dedicated to dip switches frame
	   variable    numbyt_gp : natural range 0 to 7 := 0;  -- dedicated to dip switches frame
       --for display frames that are recurrent every 100ms if no other dump in process at the same time
       variable  delay       : natural range  0 to 16777215 := 0; 
       variable  numbyt_dspl : integer range  0 to 36       := 0;
       variable  dspldump_on : boolean := false;
	 begin
      if rising_edge(hiclk) then
         if sig_dump = '1' then
            dump_on <= true;
         end if;
         
         if sig_gpdump = '1' then
            gpdump_on <= true;
         end if;
         
         if sig_dpdump = '1' then
            dpdump_on <= true;
         end if;
         
            --test only to chain trace and dump
--        if sig_auto = '1' then
--            dump_on <= true;
--        end if;         
            --tests only

        if FIFORDNEXT = '1' then
            FIFORDNEXT <= '0';
            FIFORD     <= '1';
        end if;
        
        if GPFIFORDNEXT = '1' then
            GPFIFORDNEXT <= '0';
            GPFIFORD     <= '1';
        end if;
        
        --manage the 100ms tick for displ frames
        delay := delay+1;
        if delay > 5000000 then
            delay  := 0;
            --if dump_on = false and gpdump_on = false and dpdump_on = false then
            if true then
                dspldump_on := true;
            end if;
        end if;
    
        if w_TX_DONE  = '1' then
            r_TX_DV <= '0';
        end if;
        
        if dspldump_on = true then
            if r_TX_DV = '0' then
                case numbyt_dspl is
                    when 0      =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= X"41";  --code of 'A' for display A (8-byte frame)
                        numbyt_dspl := 30; --we added the first byte lately, thus the value "30"...
                    when 30     =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= dspl_A_off_st&dspl_B_off_st&"000000";
                        numbyt_dspl := 1;
                    when 1 to 8 =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= (RDA_data_st((8-numbyt_dspl)*2+1)) & (RDA_data_st((8-numbyt_dspl)*2));
                        numbyt_dspl := numbyt_dspl+1;
                    when 9      => 
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= X"42";  --code of 'B' for display B (8-byte frame)
                        numbyt_dspl := 31; --we added the first byte lately, thus the value "30"...
                    when 31     =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= dspl_A_off_st&dspl_B_off_st&"111111";
                        numbyt_dspl := 10;
                    when 10 to 17 =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= (RDB_data_st((17-numbyt_dspl)*2+1)) & (RDB_data_st((17-numbyt_dspl)*2)) ;
                        numbyt_dspl := numbyt_dspl+1;

                    when 18       =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= X"59";  --code of 'Y' for display IOs (32-byte frame)
                        numbyt_dspl := 19; 

                    when 19       =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= outx(15 downto 8);
                        numbyt_dspl := 20;
                    when 20       =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= outx(7 downto 0);
                        numbyt_dspl := 21;
                    
                    when 21       =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= inpx(15 downto 8);
                        numbyt_dspl := 22;
                    when 22       =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= inpx(7 downto 0);
                        numbyt_dspl := 23;
                    
                    when others =>
                        dspldump_on := false;
                        numbyt_dspl := 0;
                   
                end case;
            end if;
        end if;
        
        if dump_on = true and dspldump_on = false then
            if r_TX_DV = '0' then
                if FIFORD  = '1' then
                    case numbyt is  
                        when 0   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= X"54";  --code of 'T' saying sz=4
                            numbyt := 1;
                        when 1   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= TRFIFO_DOUT(7 downto 0);  --cnotains data ram
                            numbyt := 2;
                        when 2   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= TRFIFO_DOUT(15 downto 8); --contains data rom
                            numbyt := 3;
                        when 3   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= TRFIFO_DOUT(23 downto 16); --contains rom addr 0..7
                            numbyt := 4;
                        when 4   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= TRFIFO_DOUT(31 downto 24); --contains rom addr 11..8 + 4 flags
                            numbyt := 5;
                        when 5   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= TRFIFO_DOUT(39 downto 32); --contains ram addr (8b)
                            numbyt := 0;
                            FIFORD <= '0';
                        when others =>
                            FIFORD <= '0';
                            numbyt := 0;
                      end case;
                else    --FIFORD is 0
                    if ISFIFOVOID = '0' then
                        if FIFORDNEXT = '0' then
					       FIFORDNEXT <= '1';	
					    end if;
					else 
					   dump_on <= false;
					end if;	
                    
                end if;  --endif FIFORD
            end if;      --endif r_TX_DV
          end if;        --endif dump_on


        if gpdump_on = true and dump_on = false and dspldump_on = false then
            if r_TX_DV = '0' then
                if GPFIFORD  = '1' then
                    case numbyt_gp is  
                        when 0   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= X"47";  --code of 'G' saying sz=4
                            numbyt_gp := 1;
                        when 1   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= GPFIFO_DOUT(7 downto 0);  --cnotains data rom
                            numbyt_gp := 2;
                        when 2   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= GPFIFO_DOUT(15 downto 8); --contains data ram
                            numbyt_gp := 3;
                        when 3   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= GPFIFO_DOUT(23 downto 16); --contains rom addr 0..7
                            numbyt_gp := 4;
                        when 4   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= GPFIFO_DOUT(31 downto 24); --contains end of rom addr + gpaddr 0(8b)
                            numbyt_gp := 5;
                        when 5   =>
                            r_TX_DV <= '1'; --say uart is busy	
                            r_TX_BYTE <= GPFIFO_DOUT(39 downto 32); --contains gpaddr low (8b)
                            numbyt_gp := 0;
                            GPFIFORD <= '0';
                        when others =>
                            GPFIFORD <= '0';
                            numbyt_gp := 0;
                      end case;
                else    --GPFIFORD is 0
                    if ISGPFIFOVOID = '0' then
                        if GPFIFORDNEXT = '0' then
					       GPFIFORDNEXT <= '1';	
					    end if;
					else 
					   null; --we want to dump for as long as possible
					   --gpdump_on <= false;
					end if;	
                    
                end if;  --endif GPFIFORD
            end if;      --endif r_TX_DV
          end if;        --endif gpdump_on

		--mystdmsg(8*23+1 to 8*27) <= X"43"&RAM_Data(16#0A#)&RAM_Data(16#0B#)&RAM_Data(16#6A#)&RAM_Data(16#7B#)&RAM_Data(16#2A#)&RAM_Data(16#2B#);

        if dpdump_on = true and gpdump_on = false and dump_on = false and dspldump_on = false then
            if r_TX_DV = '0' then
                case numbyt_dp is  
                    when 0   =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= X"43";  --code of 'C' saying sz=4
                        numbyt_dp := 1;
                    when 1   =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= RAMCPY(16#0A#)&RAMCPY(16#0B#);
                        numbyt_dp := 2;
                    when 2   =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= RAMCPY(16#6A#)&RAMCPY(16#7B#);
                        numbyt_dp := 3;
                    when 3   =>
                        r_TX_DV <= '1'; --say uart is busy	
                        r_TX_BYTE <= RAMCPY(16#2A#)&RAMCPY(16#2B#);
                        dpdump_on <= false;
                        numbyt_dp := 0;                        
                    when others =>
                        dpdump_on <= false;
                        numbyt := 0;
                  end case;

            end if;      --endif r_TX_DV
          end if;        --endif gpdump_on
            


        end if;
             	 
	 end process;

  -- Instantiate UART receiver
  UART_RX_INST : uart_rx
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => hiclk,
      i_rx_serial => RXp,         -- port tx
      o_rx_dv     => w_RX_DV,    -- command start transmitting
      o_rx_byte   => w_RX_BYTE  -- byte to read
      );


    --RX handling
    -- It is done in such a way that you cannot send the same command twice in a row.
    -- because RX_CMD would not change, the second command would not be detectted.
    -- thus if you want to send a command twice in a row yu need to add a dummy command
    -- such as ' ' (space, code 0x20) in the middle. Then, it will work.
	 process (hiclk)
	   variable lastw_RX_DV : std_logic := '0';
	 begin
        if rising_edge(hiclk) then
			if w_RX_DV = '1' and lastw_RX_DV = '0' then      --the driver keeps this signal to 1 for 4 ticks
                RX_CMD <= w_RX_BYTE;   --but the command is handled in a process(RX_CMD)
			end if;	                   --where it is managed only at CMD transition
			lastw_RX_DV := w_RX_DV;
	    end if;
	 end process;

     --Incoming Command processing
     process(hiclk)
        variable last_RX_CMD : std_logic_vector(7 downto 0) := X"00";
     begin
        if rising_edge(hiclk) then

            if last_RX_CMD /= RX_CMD then
                --there was a change on RX_CMD... 0 is nothing to do
                case RX_CMD is
                    --'C' for config dip switches spying dump
                    when X"43"     =>
                        status_int <= X"43";
                        sig_dpdump <= '1';
                    when X"63"     =>
                        status_int <= X"43";
                        sig_dpdump <= '1';
                    --'G' for game prom spying dump
                    when X"47"     =>
                        status_int <= X"47";
                        sig_gpdump <= '1';
                    when X"67"     =>
                        status_int <= X"47";
                        sig_gpdump <= '1';
                    --'D' for dump
                    when X"44"     =>
                        status_int <= X"44";
                        sig_dump  <= '1';
                    when X"64"     =>
                        status_int <= X"44";
                        sig_dump  <= '1';
                    --'T' trace trigger: start trace
                    --The trig is on by default at reset. when the fifo is full the trace stops
                    --use T to restart trace
                    when X"54"     =>
                       status_int <= X"54";
                       sig_trace <= '1';
                    when X"55"     =>  --U to restart gp trace
                       status_int <= X"55";
                       sig_gptrace <= '1';
                    when X"68"     =>  --h for "use real hm6508"
                       status_int <= X"68";
                       hm_user_sel_int <= '1';
                    when X"69"     =>  --i for "use intern hm6508" (default)
                       status_int <= X"69";
                       hm_user_sel_int <= '0';
                    when X"74"     =>
                       status_int <= X"54";
                       sig_trace <= '1';
                    when X"00"     =>
                        status_int <= X"20";
                    when others    =>
                        status_int <= X"FF";
                end case;
            end if;
            if sig_trace = '1' then
                sig_trace <= '0';
            end if;
            if sig_gptrace = '1' then
                sig_gptrace <= '0';
            end if;
            if sig_dump = '1' then
                sig_dump  <= '0';
            end if;
            if sig_gpdump = '1' then
                sig_gpdump  <= '0';
            end if;
            if sig_dpdump = '1' then
                sig_dpdump  <= '0';
            end if;
            last_RX_CMD := RX_CMD;
        end if;
     end process;

      GPKD  : GPKD10788    port map (hiclk=>hiclk, spo=>spo, pps4_phi=>pps4_phi,
                                     --sc5=>'1', sc6=>'0', sc7=>'1', --gottlieb sys1
                                     sc5=>'1', sc6=>'1', sc7=>'1',   --recel sys3
                                     x=>open, dbs=>open,
                                     status=>GPKD_status,
                                     RDA_data_st=>RDA_data_st,
                                     RDB_data_st=>RDB_data_st,
                                     dspl_A_off_st=>dspl_A_off_st,
                                     dspl_B_off_st=>dspl_B_off_st,
                                     da=>open, db=>open, y=>"11111111",
                                     id=>din, wio=>wio,
                                     do=>open,
                                     dldir=>open);


end Behavioral;
