library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity lm is
    generic (
        dataWidth      : integer:=32
    );
    port (
        data       : in std_logic_vector (dataWidth - 1 downto 0); 
        res        : in std_logic_vector (1 downto 0);             
        funct3     : in std_logic_vector (2 downto 0);             
        dataOut    : out std_logic_vector (dataWidth - 1 downto 0) 
    );
end entity lm;

architecture behav of lm is

    alias byte0 : std_logic_vector(7 downto 0) is data(7 downto 0);
    alias byte1 : std_logic_vector(7 downto 0) is data(15 downto 8);
    alias byte2 : std_logic_vector(7 downto 0) is data(23 downto 16);
    alias byte3 : std_logic_vector(7 downto 0) is data(31 downto 24);
    
    alias half0 : std_logic_vector(15 downto 0) is data(15 downto 0);
    alias half1 : std_logic_vector(15 downto 0) is data(31 downto 16);

    signal selected_byte : std_logic_vector(7 downto 0);
    signal selected_half : std_logic_vector(15 downto 0);
    
    signal sign_bit_b : std_logic;
    signal sign_bit_h : std_logic;
    
    alias is_unsigned : std_logic is funct3(2);

    alias size_type   : std_logic_vector(1 downto 0) is funct3(1 downto 0);

begin


    with res select selected_byte <=
        byte0 when "00",
        byte1 when "01",
        byte2 when "10",
        byte3 when others; -- "11"


    selected_half <= half0 when res(1) = '0' else half1;

    sign_bit_b <= '0' when is_unsigned = '1' else selected_byte(7);
    sign_bit_h <= '0' when is_unsigned = '1' else selected_half(15);

    process (size_type, selected_byte, selected_half, data, sign_bit_b, sign_bit_h)
    begin
        case size_type is
            when "00" => 
                dataOut <= (31 downto 8 => sign_bit_b) & selected_byte;
                
            when "01" => 
                dataOut <= (31 downto 16 => sign_bit_h) & selected_half;
                
            when "10" => 
                dataOut <= data;

            when others =>
                dataOut <= data;
        end case;
    end process;

end behav;
