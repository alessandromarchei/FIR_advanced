library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;


--THIS MODULE DESCRIBES A GENERIC REGISTER IN A BEHAVIORAL ARCHITECTURE
entity REG is
    Generic (
        NBIT : integer := 14 -- default number of bits
    );
    Port (
        clk     : in std_logic;
        reset   : in std_logic;
        enable  : in std_logic;
        data_in : in std_logic_vector(NBIT-1 downto 0);
        data_out: out std_logic_vector(NBIT-1 downto 0)
    );
end REG;

--THE DATA IS LATCHED DURING THE RISING EDGE OF THE CLOCK
architecture Behavioral of REG is
    signal reg : std_logic_vector(NBIT-1 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '0' then
            reg <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                reg <= data_in;
            end if;
        end if;
    end process;

    data_out <= reg;
end Behavioral;
