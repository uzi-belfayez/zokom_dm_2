library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.constants.all;

entity ir_dec_risb is
    generic (
        dataWidth   :   integer:=32;
        aluOpWidth  :   integer:=5  -- Le signal de sortie fait 5 bits
    );
    port ( 
        instr           :   in    std_logic_vector (dataWidth - 1 downto 0);
        
        aluOp           :   out   std_logic_vector (aluOpWidth - 1 downto 0);
        insType         :   out   std_logic_vector(2 downto 0);
        
        RI_sel          :   out   std_logic; 
        rdWrite         :   out   std_logic; 
        wrMem           :   out   std_logic; 
        loadAcc         :   out   std_logic; 
        
        memType         :   out   std_logic_vector(2 downto 0);
        pc_load, bsel   :   out   std_logic
    );
end entity ir_dec_risb;

architecture behav of ir_dec_risb is
    alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);
    alias funct3 : std_logic_vector(2 downto 0) is instr(14 downto 12);
    alias funct7_b5 : std_logic is instr(30);
begin
    process(instr, opcode, funct3, funct7_b5)
    begin
        -- Initialisation par défaut
        rdWrite <= '0'; RI_sel <= '0'; wrMem <= '0';
        loadAcc <= '0';
        insType <= UNKTYP; 
        aluOp   <= (others => '0'); -- Initialise les 5 bits à 0
        memType <= "010"; 
        pc_load <= '0'; bsel <= '0';

        case opcode is
            when R_TYPE_OPCODE => 
                insType <= R_TYPE; rdWrite <= '1'; RI_sel <= '0'; 
                -- Correction : On ajoute un '0' devant pour faire 5 bits
                aluOp <= '0' & funct7_b5 & funct3; 

            when I_TYPE_OPCODE => 
                insType <= I_TYPE; rdWrite <= '1'; RI_sel <= '1';
                if funct3 = "101" then 
                    -- SRAI/SRLI : Besoin du bit 30
                    aluOp <= '0' & funct7_b5 & funct3; 
                else 
                    -- ADDI, SLTI, etc : Bit 30 forcé à 0
                    aluOp <= "00" & funct3; 
                end if;

            when L_TYPE_OPCODE => 
                insType <= L_TYPE; 
                rdWrite <= '1'; 
                RI_sel <= '1'; 
                loadAcc <= '1';    
                wrMem <= '0'; 
                memType <= funct3; 
                aluOp   <= (others => '0'); -- 5 bits à 0 (ADD pour calcul adresse)

            when S_TYPE_OPCODE => 
                insType <= S_TYPE; rdWrite <= '0'; RI_sel  <= '1'; 
                loadAcc <= '0'; 
                wrMem   <= '1'; 
                memType <= funct3; 
                aluOp   <= (others => '0'); -- 5 bits à 0 (ADD pour calcul adresse)

            when others => null;
        end case;
    end process;
end behav;