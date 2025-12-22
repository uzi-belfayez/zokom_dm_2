library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity lm is
    generic (
        dataWidth      : integer:=32
    );
    port (
        data       : in std_logic_vector (dataWidth - 1 downto 0); -- Sortie brute de la mémoire
        res        : in std_logic_vector (1 downto 0);             -- 2 LSB de l'adresse (Alignement)
        funct3     : in std_logic_vector (2 downto 0);             -- Type de Load (LB, LH, LW...)
        dataOut    : out std_logic_vector (dataWidth - 1 downto 0) -- Donnée formatée vers RegBank
    );
end entity lm;

architecture behav of lm is

    -- Signaux intermédiaires pour découper le mot de 32 bits
    alias byte0 : std_logic_vector(7 downto 0) is data(7 downto 0);
    alias byte1 : std_logic_vector(7 downto 0) is data(15 downto 8);
    alias byte2 : std_logic_vector(7 downto 0) is data(23 downto 16);
    alias byte3 : std_logic_vector(7 downto 0) is data(31 downto 24);
    
    alias half0 : std_logic_vector(15 downto 0) is data(15 downto 0);
    alias half1 : std_logic_vector(15 downto 0) is data(31 downto 16);

    signal selected_byte : std_logic_vector(7 downto 0);
    signal selected_half : std_logic_vector(15 downto 0);
    
    -- Bit de signe pour l'extension
    signal sign_bit_b : std_logic;
    signal sign_bit_h : std_logic;
    
    -- Drapeau unsigned (bit 2 de funct3 : 1 pour LBU/LHU)
    alias is_unsigned : std_logic is funct3(2);
    -- Taille (bits 1-0 de funct3 : 00=Byte, 01=Half, 10=Word)
    alias size_type   : std_logic_vector(1 downto 0) is funct3(1 downto 0);

begin

    -- 1. Sélection de l'octet (Byte)
    with res select selected_byte <=
        byte0 when "00",
        byte1 when "01",
        byte2 when "10",
        byte3 when others; -- "11"

    -- 2. Sélection du demi-mot (Half)
    -- On suppose un alignement correct (res(0) = '0')
    selected_half <= half0 when res(1) = '0' else half1;

    -- 3. Gestion de l'extension de signe
    -- Si unsigned, le bit de signe virtuel est forcé à 0
    sign_bit_b <= '0' when is_unsigned = '1' else selected_byte(7);
    sign_bit_h <= '0' when is_unsigned = '1' else selected_half(15);

    -- 4. Multiplexage final et Extension
    process (size_type, selected_byte, selected_half, data, sign_bit_b, sign_bit_h)
    begin
        case size_type is
            when "00" => -- Byte (LB / LBU)
                dataOut <= (31 downto 8 => sign_bit_b) & selected_byte;
                
            when "01" => -- Half (LH / LHU)
                dataOut <= (31 downto 16 => sign_bit_h) & selected_half;
                
            when "10" => -- Word (LW)
                dataOut <= data;

            when others => -- Default / Error
                dataOut <= data;
        end case;
    end process;

end behav;