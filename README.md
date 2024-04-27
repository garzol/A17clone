# A17clone
vhdl files for making an A17xx clone either for spartan-3 or spartan-7

main branch is for spartan 7

## A1761plus  (spartan 7 vhdl-2008 code)  
In this directory: all sources of the A1761 clone for recel sys 3.  
With soft HM6508 integrated=>one can choose between real, or SW NVRAM  

### Hierarchy  

* rriotctrl.vhd: main module 
   * clkgen.vhd: generation of pps4 phases
   * ioxadapter.vhd: map 16 IOs to 2x8 IO board  
   * RRIOTA17.vhd: rom+ram+ioctrl  
      * ramctrl.vhd: 128 nibbles ram   
          * A1761INTERNRAM (IP)    
      * romctrl.vhd: 2KBytes rom (1K for A1761)  
          * A1761INTERNRAM (IP)  
      * ioctrl.vhd: PPS4/2 IO manager
   * hmsys.ctrl: recel sys3 NVRAM emulation
      * CD4040  
      * HM6508
   * nvramread.vhd: i2C fram. not used
      * i2c_master.vhd
   * ledctl.vhd: management of 3-led flashing for diag
   * pps4tr.vhd: send various infos thru uart (wifi)
      * GPFIFO (IP)
      * TRFIFO (IP)
      * uart_tx.vhd
      * uart_rx.vhd
      * 10788.vhd: model of GPKD pps4 display chip  

### Module description
#### rriotctrl.vhd: Entry point
This module is the main entity. It makes the interface with HW of clone core board (V3)
It manages everything, based on the use of the following components:
*  clkgen: state machine which takes ckA /ckB on input and generates phi1A, phi1, phi2, phi3A, phi3, phi4
*  ioxAdapter: this entity takes "standard" IO0..15 and makes the interface with the real HW environment of clones, which is made of 2 banks of 8 IOs each. The adapter takes care of reading the 16 input state twice per PPS4 cpu cycle, and apply the 16 outputs after selecting the appropriate bank, also twice per cycle.
*  RRIOTA17: Entity of standard A17 component. RIOTA17 has a generic list of params that allows user to select the appriopriate device for their needs. It contains:
      *  ROM entity (2KB)
      *  RAM entity (128x4bits)
      *  IO subsection
*  ledctrl: Manage the RGB leds of the core board. Gives various feedbacks on the general state of the system. This entity is in permanent works at the moment.
*  nvramMng: This is the I2C FRAM driver. Not tested at the moment. Shall not be confused with the NVRAM management of the RECEL SYS3 (HM6508) **Nothing to do with it** and **Not tested at all**
*  pps4TR: management of UART interface, which is connected to WiFi ESP8285 on the board. Will send infos to PC over wifi, such as program trace, display status, IO state, and many more. Can also take commands from the PC (Byte command only, at the moment)
*  hmsys: Duplication of the RECEL sys3 NVRAM circuitry. For test only, and initialisation of the NVRAM, if data were lost. Send command 'h' to activate the original circuitry, present on the MPU, or 'i' to activate internal *fake* NVRAM. It is called *fake* because data are not really saved on power down. Instead, a fixed reputed *working set* of data is loaded at every power on. Then, you can start with 'i' to be able to start and after a ball home, you can switch to 'h' to upload correct data in the physical HM6508. Then restart in 'h' mode (will be default on next version, but **NOT** with current version.





 



---
   
     
   

