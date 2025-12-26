library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity sm is
    generic (
        dataWidth      : integer:=32
    );
    port (
        data       : in std_logic_vector (dataWidth - 1 downto 0); 
        q          : in std_logic_vector (dataWidth - 1 downto 0); 
        res        : in std_logic_vector (1 downto 0);             
        funct3     : in std_logic_vector (2 downto 0);             
        dataOut    : out std_logic_vector (dataWidth - 1 downto 0) 
    );
end entity sm;


architecture behav of sm is

    alias q_0 : std_logic_vector(7 downto 0) is q(7 downto 0);
    alias q_1 : std_logic_vector(7 downto 0) is q(15 downto 8);
    alias q_2 : std_logic_vector(7 downto 0) is q(23 downto 16);
    alias q_3 : std_logic_vector(7 downto 0) is q(31 downto 24);

  
    signal data_to_write : std_logic_vector(31 downto 0);
    
 
    signal m : std_logic_vector(3 downto 0);

begin


    process (data, res, funct3)
    begin
       
        data_to_write <= data;

        if funct3(1 downto 0) = "00" then -- SB 
            case res is
                when "00"   => 
                    data_to_write(7 downto 0)   <= data(7 downto 0);
                when "01"   => 
                    data_to_write(15 downto 8)  <= data(7 downto 0);
                when "10"   => 
                    data_to_write(23 downto 16) <= data(7 downto 0);
                when "11"   => 
                    data_to_write(31 downto 24) <= data(7 downto 0);
                when others => null;
            end case;

        elsif funct3(1 downto 0) = "01" then -- SH 
            if res(1) = '1' then
                data_to_write(31 downto 16) <= data(15 downto 0);
            else                 
                data_to_write(15 downto 0)  <= data(15 downto 0);
            end if;
        end if;
    end process;


    process (res, funct3)
    begin
        m <= "1111"; 
        
        case funct3(1 downto 0) is
            when "00" => -- SB
                case res is
                    when "00" => m <= "1110"; -- Ecrit octet 0
                    when "01" => m <= "1101"; -- Ecrit octet 1
                    when "10" => m <= "1011"; -- Ecrit octet 2
                    when "11" => m <= "0111"; -- Ecrit octet 3
                    when others => null;
                end case;
            when "01" => -- SH
                if res(1) = '0' then m <= "1100"; -- Ecrit partie basse
                else                 m <= "0011"; -- Ecrit partie haute
                end if;
            when "10" => -- SW
                m <= "0000"; -- Ecrit tout
            when others => null;
        end case;
    end process;

    dataOut(7 downto 0)   <= q_0 when m(0) = '1' else data_to_write(7 downto 0);
    dataOut(15 downto 8)  <= q_1 when m(1) = '1' else data_to_write(15 downto 8);
    dataOut(23 downto 16) <= q_2 when m(2) = '1' else data_to_write(23 downto 16);
    dataOut(31 downto 24) <= q_3 when m(3) = '1' else data_to_write(31 downto 24);

end behav;
