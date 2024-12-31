library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


-- FIR filter with FILTER ORDER = 10, NBIT = 14
-- VIN = 1 when the input signal is valid, ENABLE LIKE SIGNAL (if at cloCLK cycle VIN = 0, do not sample the DIN value)
-- VOUT = 1 when the DOUT (filtered data) is ready


--FROM THE myfilter.c file we obtained that with a SHIFT AMOUNT = 19, the THD = -34dB, still acceptable.
--Since we are working with Nb = 14, the output of each multiplier is equal to 28 bits (at most),
--hence we can represent the results of each multiplication with the 9 MSBs of the right value, concatenating
--6 ZEROS as LSBs

entity FIR is
port (
    CLK     : in std_logic;
    RST_n     : in std_logic;
    DIN   : in std_logic_vector(13 downto 0);             -- input data
    VIN   : in std_logic;                                 -- validation input signal
    B0    : in std_logic_vector(13 downto 0);
    B1    : in std_logic_vector(13 downto 0);
    B2    : in std_logic_vector(13 downto 0);
    B3    : in std_logic_vector(13 downto 0);
    B4    : in std_logic_vector(13 downto 0);
    B5    : in std_logic_vector(13 downto 0);
    B6    : in std_logic_vector(13 downto 0);
    B7    : in std_logic_vector(13 downto 0);
    B8    : in std_logic_vector(13 downto 0);
    B9    : in std_logic_vector(13 downto 0);
    B10    : in std_logic_vector(13 downto 0);
    DOUT  : out std_logic_vector(13 downto 0);            -- output data
    VOUT  : out std_logic);                               -- validation output signal  
end FIR;


architecture structural of FIR is

component REG is
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
end component;

component FFD is
	Port (	
		CK:	In	std_logic;
		RESET:	In	std_logic;
		ENABLE : in std_logic;
		D:	In	std_logic;
		Q:	Out	std_logic);
end component;

--INTERNAL SIGNALS DECLARATION

--FACTOR SIGNALS
type regs is array(0 to 10) of std_logic_vector(13 downto 0);
type adders is array(0 to 9) of std_logic_vector(14 downto 0);
type N1_regs is array(0 to 10) of std_logic_vector(13 downto 0);
type mulout is array(0 to 10) of std_logic_vector(27 downto 0);
type multrunc is array(0 to 10) of std_logic_vector(14 downto 0);
signal registers: regs;       --signal between the registers (connect REG(i)_out to REG(i+1)_in)
signal mul_out : mulout;
signal mul_trunc : multrunc;     --results of the multiplier truncated in order to approximate the result and save area
signal add_out : adders;
signal b_out : N1_regs;
signal DOUT_sig: std_logic_vector(13 downto 0);
signal VIN_pipe: std_logic;

begin

--FF to PROPAGATE THE VOUT SIGNAL
DFF_0 : FFD port map(CLK, RST_n, '1', VIN, VIN_pipe);
DFF_1 : FFD port map(CLK, RST_n, '1', VIN_pipe, VOUT);

--REGISTERS INSTANTIATION
REGISTERS_inst : for i in 0 to 9 generate
    U_reg : REG generic map(14)
                port map(clk, RST_n, VIN_pipe, registers(i), registers(i+1));
end generate;

B_0 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B0, b_out(0));
B_1 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B1, b_out(1));
B_2 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B2, b_out(2));
B_3 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B3, b_out(3));
B_4 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B4, b_out(4));
B_5 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B5, b_out(5));
B_6 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B6, b_out(6));
B_7 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B7, b_out(7));
B_8 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B8, b_out(8));
B_9 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B9, b_out(9));
B_10 : REG generic map(14) port map(clk, RST_n, VIN_pipe, B10, b_out(10));


--INPUT REGISTER TO STORE THE DIN data
DIN_reg : REG generic map(14) port map(clk, RST_n, VIN, DIN, registers(0));

-- DA AGGIUNGEREEEEEEEEEEEEEEEEEEEEEEE
DOUT_reg : REG generic map(14) port map(clk, RST_n, VIN_pipe, DOUT_sig, DOUT);

MULTIPLY : for i in 0 to 10 generate
    MUL_i : mul_out(i) <= std_logic_vector(signed(registers(i)) * signed(b_out(i)));
end generate;

--GENERATION OF THE MULTIPLIER TRUNCATION
TRUNCATION : for i in 0 to 10 generate
    trunc_i : mul_trunc(i) <= mul_out(i)(27 downto 19) & "000000"; -- Right shift by 19 and then left shift by 19-14+1
end generate;

add_out(0) <= mul_trunc(0) + mul_trunc(1);
ADDITION : for i in 1 to 9 generate
    ADD_i : add_out(i) <= add_out(i-1) + mul_trunc(i+1);
end generate;

--CONNECTING THE LAST ADDER_OUT TO THE FILTER OUTPUT
DOUT_sig <= add_out(9)(13 downto 0);

end architecture;