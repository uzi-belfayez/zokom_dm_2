library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity sm is
    generic (
        dataWidth      : integer:=32
    );
    port (
        data       : in std_logic_vector (dataWidth - 1 downto 0); -- Donnée à écrire (depuis rs2)
        q          : in std_logic_vector (dataWidth - 1 downto 0); -- Donnée lue en mémoire (Valeur actuelle)
        res        : in std_logic_vector (1 downto 0);             -- Adresse LSB (Alignement)
        funct3     : in std_logic_vector (2 downto 0);             -- Type (SB, SH, SW)
        dataOut    : out std_logic_vector (dataWidth - 1 downto 0) -- Donnée modifiée vers dmem
    );
end entity sm;

architecture behav of sm is

    -- Alias pour manipuler les octets
    alias data_0 : std_logic_vector(7 downto 0) is data(7 downto 0);
    alias data_1 : std_logic_vector(7 downto 0) is data(15 downto 8);
    alias data_2 : std_logic_vector(7 downto 0) is data(23 downto 16);
    alias data_3 : std_logic_vector(7 downto 0) is data(31 downto 24);

    alias q_0 : std_logic_vector(7 downto 0) is q(7 downto 0);
    alias q_1 : std_logic_vector(7 downto 0) is q(15 downto 8);
    alias q_2 : std_logic_vector(7 downto 0) is q(23 downto 16);
    alias q_3 : std_logic_vector(7 downto 0) is q(31 downto 24);

    signal m     : std_logic_vector (3 downto 0); -- Masque global (1=Garder mémoire, 0=Ecrire data)
    signal m_b   : std_logic_vector (3 downto 0); -- Masque Byte
    signal m_h   : std_logic_vector (3 downto 0); -- Masque Half

begin

    -- Si le bit de masque est '1', on garde l'ancienne valeur (q), sinon on prend la nouvelle (data)
    -- On construit le mot de sortie octet par octet
    dataOut(7 downto 0)   <= q_0 when m(0) = '1' else data_0;
    dataOut(15 downto 8)  <= q_1 when m(1) = '1' else data_1;
    dataOut(23 downto 16) <= q_2 when m(2) = '1' else data_2;
    dataOut(31 downto 24) <= q_3 when m(3) = '1' else data_3;

    -- Génération des masques
    -- Half Word : Selon res(1) (bit 1 de l'adresse)
    m_h <= "0011" when res(1) = '1' else "1100"; -- "0011" -> garde bas (écrit haut), "1100" -> garde haut (écrit bas)

    -- Byte : Selon res (00, 01, 10, 11)
    process (res)
    begin
        case res is
            when "00"   => m_b <= "1110"; -- Ecrit octet 0
            when "01"   => m_b <= "1101"; -- Ecrit octet 1
            when "10"   => m_b <= "1011"; -- Ecrit octet 2
            when "11"   => m_b <= "0111"; -- Ecrit octet 3
            when others => m_b <= "1111";
        end case;
    end process;

    -- Sélection selon funct3 (SB="000", SH="001", SW="010")
    process (funct3, m_b, m_h)
    begin
        case funct3(1 downto 0) is
            when "00"   => m <= m_b;    -- SB
            when "01"   => m <= m_h;    -- SH
            when "10"   => m <= "0000"; -- SW (Tout écraser)
            when others => m <= "1111"; -- Sécurité
        end case;
    end process;

end behav;