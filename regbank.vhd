library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity regbank is
    generic (
        dataWidth      : integer:=32
    );
    port (
        RA      :   in      std_logic_vector(4 downto 0);
        RB      :   in      std_logic_vector(4 downto 0);
        RW      :   in      std_logic_vector(4 downto 0);
        BusW    :   in      std_logic_vector(dataWidth - 1 downto 0);
        BusA    :   out     std_logic_vector(dataWidth - 1 downto 0);
        BusB    :   out     std_logic_vector(dataWidth - 1 downto 0);
        WE      :   in      std_logic;
        clk     :   in      std_logic;
        reset   :   in      std_logic
    );
end entity regbank;

architecture behav of regbank is

    type    regType is array (0 to 31) of std_logic_vector(dataWidth - 1 downto 0);
    signal  regBank32 :   regType;
    constant zero   : std_logic_vector (4 downto 0):= (others => '0');
    begin


    process (clk, reset)
    begin
        if (reset = '1') then
            for i in 0 to 31 loop
                --regBank32(i)    <= (others => '0');
                regBank32(i)    <= std_logic_vector(to_unsigned(i,dataWidth));
            end loop;
        elsif rising_edge(clk) then
            if WE = '1' then
                if RW /= zero then
                    regBank32(to_integer(unsigned(RW))) <=  BusW;
                end if;
            end if;
        end if;
    end process;

    BusA  <=  regBank32(to_integer(unsigned(RA)));
    BusB  <=  regBank32(to_integer(unsigned(RB)));


end behav;