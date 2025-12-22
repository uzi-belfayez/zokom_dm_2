library IEEE;
use IEEE.std_logic_1164.ALL;

entity mux2to1 is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        in0     : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Entrée 0 (ex: src2 / RegB)
        in1     : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Entrée 1 (ex: immExt)
        sel     : in  std_logic;                               -- Selecteur (RI_sel)
        dout    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity mux2to1;

architecture rtl of mux2to1 is
begin
    -- Si sel=0 -> dout = in0 (Type R)
    -- Si sel=1 -> dout = in1 (Type I)
    dout <= in0 when sel = '0' else in1;
end rtl;