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
        

---
   
     
   

