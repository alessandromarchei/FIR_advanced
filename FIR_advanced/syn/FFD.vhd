library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

--THIS MODULE IMPLEMENTS A SIMPLE D-TYPE FLIP FLOP, LATCHING AT THE RISING EDGE OF THE CLOCK
--AND WITH AN ASYNCHRONOUS RESET
entity FFD is
	Port (	
		CK:	In	std_logic;
		RESET:	In	std_logic;
		ENABLE : in std_logic;
		D:	In	std_logic;
		Q:	Out	std_logic);
end FFD;

architecture BEHAVIORAL of FFD is -- flip flop D with asyncronous reset

begin
	
	PASYNCH: process(CK,RESET)
	begin
	  if RESET='0' then
	    Q <= '0';
	  elsif CK'event and CK='1' then -- positive edge triggered:
        if ENABLE = '1' then
	        Q <= D; 
        end if;
	  end if;
	end process;

end architecture;

