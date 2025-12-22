library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity RISCV_RISB_tb is
end entity RISCV_RISB_tb;

architecture behav of RISCV_RISB_tb is

    -- Déclaration du composant à tester (Votre processeur Top-Level)
    component RISCV_RISB
        generic (
            dataWidth      : integer:=32;
            addrWidth      : integer:=32;
            memDepth       : integer:=100;
            memoryFile     : string
        );
        port (
            clk             :   in std_logic;
            reset           :   in std_logic
        );
    end component;

    -- Constantes de configuration
    constant dataWidth  : integer := 32;
    constant addrWidth  : integer := 32;
    constant memDepth   : integer := 100; -- Taille de la mémoire pour la simulation
    constant memoryFile : string  := "store_01.hex.txt"; -- Fichier contenant vos instructions (I-Type, R-Type)

    -- Signaux de test
    signal clk_t   : std_logic := '0';
    signal reset_t : std_logic;

begin

    -- Instanciation du DUT (Device Under Test)
    dut: RISCV_RISB 
        generic map (
            dataWidth   => dataWidth,
            addrWidth   => addrWidth,
            memDepth    => memDepth,
            memoryFile  => memoryFile
        )
        port map (
            clk   => clk_t,           
            reset => reset_t         
        );

    -- Génération d'horloge (Période = 10 ns)
    -- Bascule toutes les 5 ns
    clk_t <= not clk_t after 5 ns;

    -- Génération du Reset
    -- Initialisé à '1' (Reset actif), puis passe à '0' après 50 ns
    reset_t <= '1', '0' after 50 ns;

end behav;