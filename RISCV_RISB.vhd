library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.constants.all;

entity RISCV_RISB is
    generic (
        dataWidth      : integer:=32;
        addrWidth      : integer:=32;
        memDepth       : integer:=100;
        memoryFile     : string:="./prog.hex"
    );
    port ( clk, reset : in std_logic );
end;

architecture behav of RISCV_RISB is
    constant aluOpWidth : natural:=5;

    -- Composants (abrégés)
    component compteur generic (TAILLE:integer); port(din:in std_logic_vector; clk,load,reset:in std_logic; dout:out std_logic_vector); end component;
    component imem generic (DATA_WIDTH,ADDR_WIDTH,MEM_DEPTH:natural; INIT_FILE:string); port(address:in std_logic_vector; Data_Out:out std_logic_vector); end component;
    component regbank generic (dataWidth:integer); port(RA,RB,RW:in std_logic_vector; BusW:in std_logic_vector; BusA,BusB:out std_logic_vector; WE,clk,reset:in std_logic); end component;
    component alu generic (dataWidth,aluOpWidth:integer); port(opA,opB,aluOp:in std_logic_vector; res:out std_logic_vector); end component;
    component mux2to1 generic (DATA_WIDTH:integer); port(in0,in1:in std_logic_vector; sel:in std_logic; dout:out std_logic_vector); end component;
    component dmem generic (DATA_WIDTH,ADDR_WIDTH,MEM_DEPTH:natural); port(addr,data:in std_logic_vector; write,clk:in std_logic; q:out std_logic_vector); end component;
    
    component ir_dec_risb generic (dataWidth,aluOpWidth:integer); 
        port (instr:in std_logic_vector; aluOp:out std_logic_vector; insType:out std_logic_vector; RI_sel,rdWrite,wrMem,loadAcc:out std_logic; memType:out std_logic_vector; pc_load,bsel:out std_logic); 
    end component;
    component imm_ext_risb generic (dataWidth:integer); port(instr:in std_logic_vector; insType:in std_logic_vector; immExt:out std_logic_vector); end component;
    component lm generic (dataWidth:integer); port(data:in std_logic_vector; res:in std_logic_vector; funct3:in std_logic_vector; dataOut:out std_logic_vector); end component;
    component sm generic (dataWidth:integer); port(data,q:in std_logic_vector; res:in std_logic_vector; funct3:in std_logic_vector; dataOut:out std_logic_vector); end component;

    -- Signaux
    signal instr, src1, src2, immExt, src2Mux, result, dataOutMem, dataInMem, dataOutLM, resMux : std_logic_vector(dataWidth-1 downto 0);
    signal pc, pcBy4, pc_in, addr_dmem : std_logic_vector(addrWidth-1 downto 0);
    signal aluOp : std_logic_vector(aluOpWidth-1 downto 0);
    signal insType, memType : std_logic_vector(2 downto 0);
    signal RI_sel, rdWrite, wrMem_sig, loadAcc, pc_load : std_logic;
    signal align_bits : std_logic_vector(1 downto 0);

    alias rs1 : std_logic_vector(4 downto 0) is instr(19 downto 15);
    alias rs2 : std_logic_vector(4 downto 0) is instr(24 downto 20);
    alias rd  : std_logic_vector(4 downto 0) is instr(11 downto 7);

begin
    -- 1. Fetch
    pcBy4 <= "00" & pc(addrWidth-1 downto 2) when to_integer(unsigned(pc)) < memDepth*4 else (others=>'0');
    
    -- Le signal 'load' du PC est connecté à 'pc_load' du contrôleur (actuellement à 0)
    pc_1 : compteur generic map (TAILLE=>addrWidth) port map (din=>pc_in, clk=>clk, load=>pc_load, reset=>reset, dout=>pc);
    imem_1 : imem generic map (DATA_WIDTH=>dataWidth, ADDR_WIDTH=>addrWidth, MEM_DEPTH=>memDepth, INIT_FILE=>memoryFile) port map (address=>pcBy4, Data_Out=>instr);
    
    -- 2. Decode
    ir_dec_1 : ir_dec_risb generic map (dataWidth=>dataWidth, aluOpWidth=>aluOpWidth) 
        port map (
            instr=>instr, aluOp=>aluOp, insType=>insType, 
            RI_sel=>RI_sel, rdWrite=>rdWrite, wrMem=>wrMem_sig, 
            loadAcc=>loadAcc, -- Controle MuxWB
            pc_load=>pc_load, -- Controle Saut PC
            memType=>memType, bsel=>open
        );

    imm_ext_1 : imm_ext_risb generic map (dataWidth=>dataWidth) port map (instr=>instr, insType=>insType, immExt=>immExt);
    rb_1 : regbank generic map (dataWidth=>dataWidth) port map (RA=>rs1, RB=>rs2, RW=>rd, BusW=>resMux, BusA=>src1, BusB=>src2, WE=>rdWrite, clk=>clk, reset=>reset);

    -- 3. Execute
    mux_alu_b : mux2to1 generic map (DATA_WIDTH=>dataWidth) port map (in0=>src2, in1=>immExt, sel=>RI_sel, dout=>src2Mux);
    alu_1 : alu generic map (dataWidth=>dataWidth, aluOpWidth=>aluOpWidth) port map (opA=>src1, opB=>src2Mux, aluOp=>aluOp, res=>result);

    -- 4. Memory (Read-Modify-Write via SM)
    addr_dmem  <= result(addrWidth-1 downto 2) & "00";
    align_bits <= result(1 downto 0);
    
    dmem_1 : dmem generic map (DATA_WIDTH=>dataWidth, ADDR_WIDTH=>addrWidth, MEM_DEPTH=>memDepth)
        port map (addr=>addr_dmem, data=>dataInMem, write=>wrMem_sig, clk=>clk, q=>dataOutMem);

    sm_1 : sm generic map (dataWidth=>dataWidth)
        port map (data=>src2, q=>dataOutMem, res=>align_bits, funct3=>memType, dataOut=>dataInMem);

    lm_1 : lm generic map (dataWidth=>dataWidth)
        port map (data=>dataOutMem, res=>align_bits, funct3=>memType, dataOut=>dataOutLM);

    -- 5. Write Back (Mux piloté par loadAcc)
    mux_wb : mux2to1 generic map (DATA_WIDTH=>dataWidth) 
        port map (
            in0 => result,      -- ALU Result (R, I, S)
            in1 => dataOutLM,   -- Memory Out (L)
            sel => loadAcc, 
            dout => resMux
        );

end behav;