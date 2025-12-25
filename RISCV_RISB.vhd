library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.constants.all;

entity RISCV_RISB is
    generic (
        dataWidth      : integer := 32;
        addrWidth      : integer := 32;
        memDepth       : integer := 100;
        -- Choisissez votre programme ici
        memoryFile     : string  := "./prog.hex" 
    );
    port (
        clk     : in std_logic;
        reset   : in std_logic
    );
end entity RISCV_RISB;

architecture behav of RISCV_RISB is
    constant aluOpWidth : natural := 5; 

    -- =========================================================================
    -- 1. DÉCLARATION DES COMPOSANTS
    -- =========================================================================

    -- COMPTEUR (Modifié avec pc_enable)
    component compteur 
        generic (TAILLE:integer); 
        port(din:in std_logic_vector; clk,reset,load,pc_enable:in std_logic; dout,pc_plus_4:out std_logic_vector); 
    end component;

    -- IMEM (Modifié avec clk)
    component imem 
        generic (DATA_WIDTH,ADDR_WIDTH,MEM_DEPTH:natural; INIT_FILE:string); 
        port(clk:in std_logic; address:in std_logic_vector; Data_Out:out std_logic_vector); 
    end component;

    -- NOUVEAU : REGISTRE D'INSTRUCTION (IR)
    component registre_instr
        generic ( DATA_WIDTH : integer );
        port (clk, reset, ri_enable : in std_logic; din : in std_logic_vector; dout : out std_logic_vector);
    end component;

    -- DÉCODEUR (Modifié FSM avec clk/reset et enables)
    component ir_dec_risb 
        generic (dataWidth,aluOpWidth:integer); 
        port (
            clk, reset      : in std_logic;
            instr           : in std_logic_vector; 
            bres            : in std_logic;
            -- Sorties Contrôle FSM
            ri_enable, pc_enable : out std_logic;
            -- Sorties Datapath
            aluOp           : out std_logic_vector; 
            insType, loadType, memType : out std_logic_vector;
            RI_sel, rdWrite, wrMem : out std_logic; 
            loadAccJump     : out std_logic_vector; 
            pc_load         : out std_logic; 
            bsel            : out std_logic_vector;
            btype           : out std_logic_vector
        ); 
    end component;

    -- Composants inchangés (Standard)
    component regbank generic (dataWidth:integer); port(RA,RB,RW:in std_logic_vector; BusW:in std_logic_vector; BusA,BusB:out std_logic_vector; WE,clk,reset:in std_logic); end component;
    component alu generic (dataWidth,aluOpWidth:integer); port(opA,opB,aluOp:in std_logic_vector; res:out std_logic_vector); end component;
    component dmem generic (DATA_WIDTH,ADDR_WIDTH,MEM_DEPTH:natural); port(addr,data:in std_logic_vector; write,clk:in std_logic; q:out std_logic_vector); end component;
    component imm_ext_risb generic (dataWidth:integer); port(instr:in std_logic_vector; insType:in std_logic_vector; immExt:out std_logic_vector); end component;
    component lm generic (dataWidth:integer); port(data:in std_logic_vector; res:in std_logic_vector; funct3:in std_logic_vector; dataOut:out std_logic_vector); end component;
    component sm generic (dataWidth:integer); port(data,q:in std_logic_vector; res:in std_logic_vector; funct3:in std_logic_vector; dataOut:out std_logic_vector); end component;
    component mux2to1 generic (DATA_WIDTH:integer); port(in0,in1:in std_logic_vector; sel:in std_logic; dout:out std_logic_vector); end component;
    component mux_wb generic (DATA_WIDTH:integer); port(in_alu,in_mem,in_pc4:in std_logic_vector; sel:in std_logic_vector; dout:out std_logic_vector); end component;
    component mux_opa generic (DATA_WIDTH:integer); port(in_rs1,in_pc,in_zero:in std_logic_vector; sel:in std_logic_vector; dout:out std_logic_vector); end component;
    component bc generic (dataWidth:integer); port(src1,src2:in std_logic_vector; btype:in std_logic_vector; bres:out std_logic); end component;

    -- =========================================================================
    -- 2. SIGNAUX INTERNES
    -- =========================================================================

    -- Signaux Instruction
    signal instr_raw    : std_logic_vector(dataWidth-1 downto 0); -- Sortie IMEM
    signal instr        : std_logic_vector(dataWidth-1 downto 0); -- Sortie IR (utilisée partout)

    -- Signaux PC
    signal pc, pcBy4, pc_in, pc_plus_4 : std_logic_vector(addrWidth-1 downto 0);
    
    -- Signaux Datapath
    signal src1, src2, immExt, src2Mux, src1Mux, result, dataOutMem, dataInMem, dataOutLM, resMux : std_logic_vector(dataWidth-1 downto 0);
    signal addr_dmem : std_logic_vector(addrWidth-1 downto 0);
    signal align_bits : std_logic_vector(1 downto 0);
    signal zero_sig : std_logic_vector(dataWidth-1 downto 0) := (others=>'0');

    -- Signaux Contrôle
    signal aluOp : std_logic_vector(aluOpWidth-1 downto 0);
    signal insType, memType, loadType, btype : std_logic_vector(2 downto 0);
    signal RI_sel, rdWrite, wrMem_sig, pc_load, bres : std_logic;
    signal loadAccJump, bsel : std_logic_vector(1 downto 0);
    
    -- Nouveaux signaux FSM
    signal ri_enable, pc_enable : std_logic;

    -- Alias pour les registres (Basés sur l'instruction stockée dans IR)
    alias rs1 : std_logic_vector(4 downto 0) is instr(19 downto 15);
    alias rs2 : std_logic_vector(4 downto 0) is instr(24 downto 20);
    alias rd  : std_logic_vector(4 downto 0) is instr(11 downto 7);

begin

    -- =========================================================================
    -- 3. CÂBLAGE ET INSTANCIATION
    -- =========================================================================

    -- [PC Logic]
    pcBy4 <= "00" & pc(addrWidth-1 downto 2) when to_integer(unsigned(pc)) < memDepth*4 else (others=>'0');
    pc_in <= result; -- L'adresse de saut vient toujours de l'ALU

    -- Compteur modifié : reçoit pc_enable
    pc_1 : compteur generic map (TAILLE=>addrWidth) 
        port map (
            din => pc_in, clk => clk, reset => reset,
            load => pc_load,        -- Prioritaire (Saut)
            pc_enable => pc_enable, -- Incrément simple (géré par FSM)
            dout => pc, 
            pc_plus_4 => pc_plus_4
        );

    -- [Instruction Fetch]
    -- IMEM synchrone : reçoit clk
    imem_1 : imem generic map (DATA_WIDTH=>dataWidth, ADDR_WIDTH=>addrWidth, MEM_DEPTH=>memDepth, INIT_FILE=>memoryFile) 
        port map (clk => clk, address => pcBy4, Data_Out => instr_raw);
    
    -- Registre d'Instruction (IR) : Stocke instr_raw quand ri_enable=1
    reg_instr_1 : registre_instr generic map (DATA_WIDTH => dataWidth)
        port map (
            clk => clk, reset => reset, 
            ri_enable => ri_enable, -- Piloté par le décodeur (Etat FETCH)
            din => instr_raw, 
            dout => instr           -- Cette valeur est stable pendant Decode/Exec/Mem/WB
        );

    -- [Decode / Control Unit]
    -- Décodeur séquentiel
    ir_dec_1 : ir_dec_risb generic map (dataWidth=>dataWidth, aluOpWidth=>aluOpWidth) 
        port map (
            clk => clk, reset => reset,
            instr => instr, 
            bres => bres,
            -- Sorties de pilotage séquentiel
            ri_enable => ri_enable, 
            pc_enable => pc_enable,
            -- Autres contrôles
            aluOp => aluOp, insType => insType, loadType => loadType, memType => memType,
            RI_sel => RI_sel, rdWrite => rdWrite, wrMem => wrMem_sig, 
            loadAccJump => loadAccJump, pc_load => pc_load, bsel => bsel, btype => btype
        );

    -- [Datapath Standard] (Peu de changements ici)
    
    imm_ext_1 : imm_ext_risb generic map (dataWidth=>dataWidth) port map (instr=>instr, insType=>insType, immExt=>immExt);
    
    rb_1 : regbank generic map (dataWidth=>dataWidth) 
        port map (RA=>rs1, RB=>rs2, RW=>rd, BusW=>resMux, BusA=>src1, BusB=>src2, WE=>rdWrite, clk=>clk, reset=>reset);

    bc_1 : bc generic map (dataWidth=>dataWidth) port map (src1=>src1, src2=>src2, btype=>btype, bres=>bres);

    -- Mux OpA (Rs1 / PC / Zero)
    mux_opa_1 : mux_opa generic map (DATA_WIDTH=>dataWidth) 
        port map (in_rs1=>src1, in_pc=>pc, in_zero=>zero_sig, sel=>bsel, dout=>src1Mux);

    -- Mux OpB (Rs2 / Imm)
    mux_alu_b : mux2to1 generic map (DATA_WIDTH=>dataWidth) 
        port map (in0=>src2, in1=>immExt, sel=>RI_sel, dout=>src2Mux);
    
    -- ALU
    alu_1 : alu generic map (dataWidth=>dataWidth, aluOpWidth=>aluOpWidth) 
        port map (opA=>src1Mux, opB=>src2Mux, aluOp=>aluOp, res=>result);

    -- [Memory Access]
    --addr_dmem  <= result(addrWidth-1 downto 2) & "00";
    addr_dmem <= "00" & result(addrWidth-1 downto 2);
    align_bits <= result(1 downto 0);
    
    dmem_1 : dmem generic map (DATA_WIDTH=>dataWidth, ADDR_WIDTH=>addrWidth, MEM_DEPTH=>memDepth) 
        port map (addr=>addr_dmem, data=>dataInMem, write=>wrMem_sig, clk=>clk, q=>dataOutMem);
        
    sm_1 : sm generic map (dataWidth=>dataWidth) port map (data=>src2, q=>dataOutMem, res=>align_bits, funct3=>memType, dataOut=>dataInMem);
    lm_1 : lm generic map (dataWidth=>dataWidth) port map (data=>dataOutMem, res=>align_bits, funct3=>loadType, dataOut=>dataOutLM);

    -- [Write Back]
    mux_wb_1 : mux_wb generic map (DATA_WIDTH=>dataWidth) 
        port map (in_alu=>result, in_mem=>dataOutLM, in_pc4=>pc_plus_4, sel=>loadAccJump, dout=>resMux);

end behav;