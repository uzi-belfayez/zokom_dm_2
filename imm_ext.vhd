library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.constants.all;

entity imm_ext_risb is
    generic ( dataWidth : integer:=32 );
    port (
        instr   : in  std_logic_vector(dataWidth - 1 downto 0);
        insType : in  std_logic_vector(2 downto 0); 
        immExt  : out std_logic_vector(dataWidth - 1 downto 0)
    );
end entity imm_ext_risb;

architecture behav of imm_ext_risb is
    signal immValue : unsigned (31 downto 0);
    
    alias immValue_b0       : std_logic is immValue(0);
    alias immValue_b4_1     : unsigned(3 downto 0) is immValue(4 downto 1);
    alias immValue_b10_5    : unsigned(5 downto 0) is immValue(10 downto 5);
    alias immValue_b11      : std_logic is immValue(11);
    alias immValue_b19_12   : unsigned(7 downto 0) is immValue(19 downto 12);
    alias immValue_b30_20   : unsigned(10 downto 0) is immValue(30 downto 20);
    alias immValue_b31      : std_logic is immValue(31);

begin
    process (insType, instr)
    begin
        immValue <= (others => '0');
        case insType is
            -- Type I et L (Load) partagent le même format immédiat
            when I_TYPE | L_TYPE => 
                immValue_b0       <= instr(20);
                immValue_b4_1     <= unsigned(instr(24 downto 21));
                immValue_b10_5    <= unsigned(instr(30 downto 25));
                immValue_b11      <= instr(31);
                -- Extension signe
                immValue_b19_12   <= (others => instr(31));
                immValue_b30_20   <= (others => instr(31));
                immValue_b31      <= instr(31);

            -- Type S (Store) : Immediat éclaté
            when S_TYPE => 
                immValue_b0       <= instr(7);                     -- bit 7
                immValue_b4_1     <= unsigned(instr(11 downto 8)); -- bits 11:8
                immValue_b10_5    <= unsigned(instr(30 downto 25));-- bits 30:25
                immValue_b11      <= instr(31);                    -- bit 31
                -- Extension signe
                immValue_b19_12   <= (others => instr(31));
                immValue_b30_20   <= (others => instr(31));
                immValue_b31      <= instr(31);

            when others => null;
        end case;
    end process;
    immExt <= std_logic_vector(immValue);
end behav;