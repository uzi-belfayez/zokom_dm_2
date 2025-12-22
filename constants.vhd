library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

package constants is
    constant    R_TYPE_OPCODE  :   std_logic_vector(6 downto 0):= "0110011";
    constant    I_TYPE_OPCODE  :   std_logic_vector(6 downto 0):= "0010011";
    constant    S_TYPE_OPCODE  :   std_logic_vector(6 downto 0):= "0100011";
    constant    B_TYPE_OPCODE  :   std_logic_vector(6 downto 0):= "1100011";
    constant    U_TYP1_OPCODE  :   std_logic_vector(6 downto 0):= "0110111";
    constant    U_TYP2_OPCODE  :   std_logic_vector(6 downto 0):= "0010111";
    constant    J_TYP1_OPCODE  :   std_logic_vector(6 downto 0):= "1101111";
    constant    J_TYP2_OPCODE  :   std_logic_vector(6 downto 0):= "1100111";
    constant    L_TYPE_OPCODE  :   std_logic_vector(6 downto 0):= "0000011";   -- for LOAD instructions

    constant    R_TYPE  :   std_logic_vector(2 downto 0) := "000";
    constant    I_TYPE  :   std_logic_vector(2 downto 0) := "001";
    constant    S_TYPE  :   std_logic_vector(2 downto 0) := "010";
    constant    B_TYPE  :   std_logic_vector(2 downto 0) := "011";
    constant    U_TYPE  :   std_logic_vector(2 downto 0) := "100";
    constant    J_TYPE  :   std_logic_vector(2 downto 0) := "101";
    constant    L_TYPE  :   std_logic_vector(2 downto 0) := "110";
    constant    UNKTYP  :   std_logic_vector(2 downto 0) := "111";
end package;
