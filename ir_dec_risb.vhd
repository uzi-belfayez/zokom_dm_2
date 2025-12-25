library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.constants.all;

entity ir_dec_risb is
    generic (
        dataWidth   : integer := 32;
        aluOpWidth  : integer := 5 
    );
    port ( 
        -- 1. Ajout de l'horloge et du reset (Le contrôleur devient séquentiel)
        clk, reset      : in  std_logic;
        
        instr           : in  std_logic_vector (dataWidth - 1 downto 0);
        bres            : in  std_logic;
        
        -- 2. Sorties pour gérer REG (RI) et PC
        ri_enable       : out std_logic; -- Active l'écriture dans le Registre d'Instruction
        pc_enable       : out std_logic; -- Autorise le PC à compter (+4)
        
        -- Signaux Datapath existants
        aluOp           : out std_logic_vector (aluOpWidth - 1 downto 0);
        insType         : out std_logic_vector(2 downto 0);
        loadType        : out std_logic_vector(2 downto 0);
        memType         : out std_logic_vector(2 downto 0);
        
        RI_sel          : out std_logic;
        rdWrite         : out std_logic;
        wrMem           : out std_logic;
        
        loadAccJump     : out std_logic_vector(1 downto 0);
        pc_load         : out std_logic;
        bsel            : out std_logic_vector(1 downto 0);
        btype           : out std_logic_vector(2 downto 0)
    );
end entity ir_dec_risb;

architecture behav of ir_dec_risb is

    -- 3. Décomposition en 5 états
    type state_type is (FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK);
    signal current_state : state_type;

    -- Alias pour lecture instruction
    alias opcode    : std_logic_vector(6 downto 0) is instr(6 downto 0);
    alias funct3    : std_logic_vector(2 downto 0) is instr(14 downto 12);
    alias funct7_b5 : std_logic is instr(30);

    -- Signaux internes pour dissocier le décodage (combinatoire) de l'activation (séquentielle)
    signal instType_local : std_logic_vector(2 downto 0);
    signal rdWrite_raw    : std_logic; -- "Voudrait" écrire dans le registre
    signal wrMem_raw      : std_logic; -- "Voudrait" écrire en mémoire
    signal pc_load_raw    : std_logic; -- "Voudrait" sauter

begin

    -- =========================================================================
    -- PROCESS SÉQUENTIEL : GESTION DES ÉTATS (FSM)
    -- =========================================================================
    process (clk, reset)
    begin
        if reset = '1' then
            current_state <= FETCH;
        elsif rising_edge(clk) then
            case current_state is
                when FETCH     => current_state <= DECODE;
                when DECODE    => current_state <= EXECUTE;
                when EXECUTE   => current_state <= MEMORY;
                when MEMORY    => current_state <= WRITEBACK;
                when WRITEBACK => current_state <= FETCH;
            end case;
        end if;
    end process;

    -- =========================================================================
    -- PROCESS COMBINATOIRE 1 : DÉCODAGE DE L'INSTRUCTION (Comme avant)
    -- =========================================================================
    -- Ce process détermine QUOI faire en fonction de l'instruction, 
    -- indépendamment de l'étape temporelle.
    
    -- A. Type d'Instruction
    process (opcode) begin
        case opcode is
            when R_TYPE_OPCODE => instType_local <= R_TYPE;
            when I_TYPE_OPCODE => instType_local <= I_TYPE;
            when L_TYPE_OPCODE => instType_local <= L_TYPE;
            when S_TYPE_OPCODE => instType_local <= S_TYPE;
            when B_TYPE_OPCODE => instType_local <= B_TYPE;
            when J_TYP1_OPCODE => instType_local <= J_TYPE; 
            when J_TYP2_OPCODE => instType_local <= I_TYPE; 
            when U_TYP1_OPCODE => instType_local <= U_TYPE; 
            when U_TYP2_OPCODE => instType_local <= U_TYPE; 
            when others        => instType_local <= UNKTYP;
        end case;
    end process;
    insType <= instType_local;

    -- B. Opération ALU
    process (instType_local, funct3, funct7_b5, opcode) begin
        aluOp <= (others => '0');
        if instType_local = R_TYPE then
            aluOp <= '0' & funct7_b5 & funct3;
        elsif instType_local = I_TYPE and opcode /= J_TYP2_OPCODE then
            if funct3 = "101" then aluOp <= '0' & funct7_b5 & funct3;
            else aluOp <= "00" & funct3; end if;
        end if;
    end process;
    btype <= funct3;

    -- C. Signaux de contrôle "Bruts" (Raw)
    process (instType_local, funct3, opcode, bres)
    begin
        -- Reset par défaut
        rdWrite_raw <= '0'; wrMem_raw <= '0'; pc_load_raw <= '0';
        RI_sel <= '0'; bsel <= "00"; loadAccJump <= "00";
        loadType <= "010"; memType <= "010";

        case instType_local is
            when R_TYPE => 
                rdWrite_raw <= '1';
                
            when I_TYPE => 
                rdWrite_raw <= '1'; RI_sel <= '1';
                if opcode = J_TYP2_OPCODE then -- JALR
                    pc_load_raw <= '1'; bsel <= "00"; loadAccJump <= "10";
                end if;
                
            when L_TYPE => 
                rdWrite_raw <= '1'; RI_sel <= '1'; loadAccJump <= "01"; loadType <= funct3;
                
            when S_TYPE => 
                RI_sel <= '1'; wrMem_raw <= '1'; memType <= funct3;
                
            when B_TYPE => 
                bsel <= "01"; RI_sel <= '1'; pc_load_raw <= bres;
                
            when J_TYPE => -- JAL
                rdWrite_raw <= '1'; RI_sel <= '1'; bsel <= "01"; pc_load_raw <= '1'; loadAccJump <= "10";
                
            when U_TYPE =>
                rdWrite_raw <= '1'; RI_sel <= '1';
                if opcode = U_TYP1_OPCODE then -- LUI
                    bsel <= "10"; loadAccJump <= "00";
                else -- AUIPC
                    bsel <= "01"; loadAccJump <= "00";
                end if;
            when others => null;
        end case;
    end process;

    -- =========================================================================
    -- PROCESS COMBINATOIRE 2 : GÉNÉRATION DES SORTIES SELON L'ÉTAT (4)
    -- =========================================================================
    process (current_state, rdWrite_raw, wrMem_raw, pc_load_raw)
    begin
        -- Valeurs par défaut (sécurité)
        ri_enable <= '0';
        pc_enable <= '0';
        rdWrite   <= '0';
        wrMem     <= '0';
        pc_load   <= '0';

case current_state is
        when FETCH =>
            ri_enable <= '1'; 
            pc_enable <= '0';  
            -- On garde le PC stable pour que l'ALU utilise la bonne adresse plus tard

        when DECODE =>
            null;

-- ir_dec_risb.vhd

        when EXECUTE =>
            -- Retirez ou mettez à 0 l'assignation de pc_load ici
            pc_load <= '0'; 

        when MEMORY =>
            wrMem <= wrMem_raw;

        when WRITEBACK =>
            rdWrite <= rdWrite_raw;
            
            -- GESTION DU PC UNIFIÉE ICI :
            if pc_load_raw = '1' then
                -- C'est un saut : on charge l'adresse cible maintenant
                pc_load <= '1'; 
                pc_enable <= '0'; -- On ne fait pas +4 car on saute
            else
                -- Ce n'est pas un saut : on passe à l'instruction suivante
                pc_load <= '0';
                pc_enable <= '1'; -- PC = PC + 4
            end if;
            
    end case;
    end process;

end behav;