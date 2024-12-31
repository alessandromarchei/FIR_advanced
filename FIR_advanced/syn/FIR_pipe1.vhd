library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


-- FIR_3 filter with FILTER ORDER = 10, NBIT = 14
-- VIN = 1 when the input signal is valid, ENABLE LIKE SIGNAL (if at cloCLK cycle VIN = 0, do not sample the DIN value)
-- VOUT = 1 when the DOUT (filtered data) is ready


--FROM THE myfilter.c file we obtained that with a SHIFT AMOUNT = 19, the THD = -34dB, still acceptable.
--Since we are working with Nb = 14, the output of each multiplier is equal to 28 bits (at most),
--hence we can represent the results of each multiplication with the 9 MSBs of the right value, concatenating
--6 ZEROS as LSBs

entity FIR_PIPE1 is
port (
    CLK     : in std_logic;
    RST_n     : in std_logic;
    DIN3k : in std_logic_vector(13 downto 0);             -- input data
    DIN3k1: in std_logic_vector(13 downto 0);             -- input data
    DIN3k2: in std_logic_vector(13 downto 0);             -- input data
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
    DOUT3k : out std_logic_vector(13 downto 0);            -- output data
    DOUT3k1: out std_logic_vector(13 downto 0);            -- output data
    DOUT3k2: out std_logic_vector(13 downto 0);            -- output data
    VOUT  : out std_logic);                               -- validation output signal  
end FIR_PIPE1;


architecture structural of FIR_PIPE1 is

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
type factors is array(0 to 12) of std_logic_vector(13 downto 0);
type X is array(0 to 4) of std_logic_vector(13 downto 0);
type pipe1 is array(0 to 11) of std_logic_vector(14 downto 0);  --pipeline signals for STAGE 1

signal X3k, X3k1, X3k2 : X;     --arrays of vectors to represent the delayed versions of X[3k], X[3k+1], X[3k+2], 
signal b_out : N1_regs;
signal DOUT_3k, DOUT_3k1, DOUT_3k2: std_logic_vector(13 downto 0);
signal DOUT_3k_sig, DOUT_3k1_sig, DOUT_3k2_sig: std_logic_vector(14 downto 0);
signal VIN_pipe: std_logic;
signal x3k_trunc, x3k1_trunc, x3k2_trunc : multrunc;
signal fact : factors;
signal mul_x3k, mul_x3k1, mul_x3k2 : mulout;
signal x3k_pipe1, x3k1_pipe1, x3k2_pipe1 : pipe1;

begin

--FF to PROPAGATE THE VOUT SIGNAL
DFF_0 : FFD port map(CLK, RST_n, '1', VIN, VIN_pipe);
DFF_1 : FFD port map(CLK, RST_n, '1', VIN_pipe, VOUT);

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


--INPUT REGISTERS TO STORE THE DINi data
DIN3k_reg : REG generic map(14) port map(clk, RST_n, VIN, DIN3k, X3k(0));
DIN3k1_reg : REG generic map(14) port map(clk, RST_n, VIN, DIN3k1, X3k1(0));
DIN3k2_reg : REG generic map(14) port map(clk, RST_n, VIN, DIN3k2, X3k2(0));

--OUTPUT REGISTERS TO STORE THE DOUTi data
DOUT3k_reg : REG generic map(14) port map(clk, RST_n, VIN_pipe, DOUT_3k, DOUT3k);
DOUT3k1_reg : REG generic map(14) port map(clk, RST_n, VIN_pipe, DOUT_3k1, DOUT3k1);
DOUT3k2_reg : REG generic map(14) port map(clk, RST_n, VIN_pipe, DOUT_3k2, DOUT3k2);


--REGISTERS TO CREATE THE DELAYED VERSIONS OF X[3k], X[3k+1], X[3k+2], 
PIPES : for i in 0 to 3 generate
    X3K_i : REG generic map(14) port map(clk, RST_n, VIN_pipe, X3k(i), X3k(i+1));
    X3K1_i : REG generic map(14) port map(clk, RST_n, VIN_pipe, X3k1(i), X3k1(i+1));
    X3K2_i : REG generic map(14) port map(clk, RST_n, VIN_pipe, X3k2(i), X3k2(i+1));
end generate;

--vectors containing the Xks in order of the expressions
fact(0) <= X3k2(0);
fact(1) <= X3k1(0);
fact(2) <= X3k(0);
fact(3) <= X3k2(1);
fact(4) <= X3k1(1);
fact(5) <= X3k(1);
fact(6) <= X3k2(2);
fact(7) <= X3k1(2);
fact(8) <= X3k(2);
fact(9) <= X3k2(3);
fact(10) <= X3k1(3);
fact(11) <= X3k(3);
fact(12) <= X3k2(4);


--generate the truncated multiplication output signals for the Y[3K]
X3k_mul : for i in 0 to 10 generate
    mul_3k_i : mul_x3k(i) <= std_logic_vector(signed(b_out(i)) * signed(fact(i+2)));
    x3k_trunc_i : x3k_trunc(i) <= mul_x3k(i)(27 downto 19) & "000000";
    end generate;

--generate the truncated multiplication output signals for the Y[3K+1]
X3k1_mul : for i in 0 to 10 generate
    mul_3k1_i : mul_x3k1(i) <= std_logic_vector(signed(b_out(i)) * signed(fact(i+1)));
    x3k1_trunc_i : x3k1_trunc(i) <= mul_x3k1(i)(27 downto 19) & "000000";
    end generate;

--generate the truncated multiplication output signals for the Y[3K+2]
X3k2_mul : for i in 0 to 10 generate
    mul_3k2_i : mul_x3k2(i) <= std_logic_vector(signed(b_out(i)) * signed(fact(i)));
    x3k2_trunc_i : x3k2_trunc(i) <= mul_x3k2(i)(27 downto 19) & "000000";
    end generate;


--PIPELINE STAGE 1
PIPE_1 : for i in 0 to 10 generate
    x3k_pipe1_i : REG generic map(15) port map(clk, RST_n, VIN_pipe, x3k_trunc(i), x3k_pipe1(i));
    x3k1_pipe1_i : REG generic map(15) port map(clk, RST_n, VIN_pipe, x3k1_trunc(i), x3k1_pipe1(i));
    x3k2_pipe1_i : REG generic map(15) port map(clk, RST_n, VIN_pipe, x3k2_trunc(i), x3k2_pipe1(i));
end generate;


--PIPELINE DESCRIPTION FOR THE ADDERS CHAIN
--Y[3k]
DOUT_3k_sig <= x3k_pipe1(0) + x3k_pipe1(1) + x3k_pipe1(2) + x3k_pipe1(3) + x3k_pipe1(4) + x3k_pipe1(5) + x3k_pipe1(6) + x3k_pipe1(7) + x3k_pipe1(8) + x3k_pipe1(9) + x3k_pipe1(10);


--Y[3k+1]
DOUT_3k1_sig <= x3k1_pipe1(0) + x3k1_pipe1(1) + x3k1_pipe1(2) + x3k1_pipe1(3) + x3k1_pipe1(4) + x3k1_pipe1(5) + x3k1_pipe1(6) + x3k1_pipe1(7) + x3k1_pipe1(8) + x3k1_pipe1(9) + x3k1_pipe1(10);

--Y[3k+2]
DOUT_3k2_sig <= x3k2_pipe1(0) + x3k2_pipe1(1) + x3k2_pipe1(2) + x3k2_pipe1(3) + x3k2_pipe1(4) + x3k2_pipe1(5) + x3k2_pipe1(6) + x3k2_pipe1(7) + x3k2_pipe1(8) + x3k2_pipe1(9) + x3k2_pipe1(10);



--CONNECTING THE LAST ADDER_OUT TO THE FILTER OUTPUT
DOUT_3k <= DOUT_3k_sig(13 downto 0);
DOUT_3k1 <= DOUT_3k1_sig(13 downto 0);
DOUT_3k2 <= DOUT_3k2_sig(13 downto 0);


end architecture;