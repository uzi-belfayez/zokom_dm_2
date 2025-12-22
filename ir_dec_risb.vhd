library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.constants.all;

entity ir_dec_risb is
    generic (
        dataWidth   :   integer:=32;
        aluOpWidth  :   integer:=5 
    );
    port ( 
        instr           :   in    std_logic_vector (dataWidth - 1 downto 0);
        bres            :   in    std_logic;
        btype           :   out   std_logic_vector (2 downto 0); 
        aluOp           :   out   std_logic_vector (aluOpWidth - 1 downto 0);
        insType         :   out   std_logic_vector(2 downto 0);
        loadType        :   out   std_logic_vector(2 downto 0);
        immSig          :   out   std_logic;
        writeDataMem    :   out   std_logic;
        memDataOutSig   :   out   std_logic;
        rdWrite         :   out   std_logic;
        bsel            :   out   std_logic;
        pc_load         :   out   std_logic;
        clk             :   in    std_logic;
        reset           :   in    std_logic
    );
end entity ir_dec_risb;

architecture behav of ir_dec_risb is
    alias funct3    :   std_logic_vector(2 downto 0) is instr(14 downto 12);
    alias opcode    :   std_logic_vector(6 downto 0) is instr(6 downto 0);
    signal instType_sig : std_logic_vector(2 downto 0); -- Signal interne pour lecture
begin

    -- Process de Décodage de Type
    process (opcode)
    begin
        case opcode is
            when R_TYPE_OPCODE    => instType_sig  <=  R_TYPE;
            when I_TYPE_OPCODE    => instType_sig  <=  I_TYPE;
            when S_TYPE_OPCODE    => instType_sig  <=  S_TYPE;
            when B_TYPE_OPCODE    => instType_sig  <=  B_TYPE;
            when U_TYP1_OPCODE    => instType_sig  <=  U_TYPE;
            when U_TYP2_OPCODE    => instType_sig  <=  U_TYPE;
            when J_TYP1_OPCODE    => instType_sig  <=  J_TYPE;
            when J_TYP2_OPCODE    => instType_sig  <=  J_TYPE;
            when L_TYPE_OPCODE    => instType_sig  <=  L_TYPE;
            when others           => instType_sig  <=  UNKTYP;
        end case;
    end process;
    insType <= instType_sig;

    -- Process ALU Control (C'est ICI qu'était l'erreur)
    process (instType_sig, funct3, instr)
    begin
        -- Initialisation propre (5 bits à 0)
        aluOp <= (others => '0'); 

        case instType_sig is
            when R_TYPE  => 
                -- CORRECTION : Ajout du '0' pour faire 5 bits (1 + 1 + 3)
                aluOp   <=  '0' & instr(30) & funct3;
                
            when I_TYPE  =>  
                aluOp(2 downto 0)   <=  funct3;
                aluOp(4)            <=  '0'; -- CORRECTION : On force le bit 4 à 0
                
                if funct3 = "101" then -- SRAI / SRLI
                    aluOp(3)    <= instr(30);
                else
                    aluOp(3)    <= '0';
                end if;
                
            when others =>  
                -- CORRECTION : "00000" (5 bits) et non "0000" (4 bits)
                aluOp   <=  "00000"; 
        end case;
    end process;

    -- Process Control Signals
    process (instType_sig, funct3, bres)
    begin
        memDataOutSig   <=  '0';
        loadType        <=  "010"; 
        writeDataMem    <=  '0';
        rdWrite         <=  '0';
        bsel            <=  '0';
        pc_load         <=  '0';
        immSig          <=  '0'; -- Default

        case instType_sig is
            when R_TYPE  =>   
                immSig  <=  '0';
                rdWrite <=  '1';
            when I_TYPE  =>   
                immSig  <=  '1';
                rdWrite <=  '1';
            when L_TYPE  =>   
                immSig  <=  '1';
                memDataOutSig   <=  '1';
                loadType    <=  funct3;
                rdWrite <=  '1';
            when S_TYPE  =>   
                immSig  <=  '1'; -- Pour calculer l'adresse (rs1 + imm)
                loadType    <=  funct3; -- Pour le module SM
                writeDataMem    <= '1'; -- Active l'écriture
            when B_TYPE =>
                bsel    <= bres;
                pc_load <= bres;
            when others  =>   
                immSig  <=  '0'; 
        end case;
    end process;

    btype   <=  funct3;

end behav;