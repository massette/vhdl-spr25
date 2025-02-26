--------------------------------------------------------------------------------
--
-- Lab 03 Demo: SequenceGenerator_TB
-- Sean Graham
-- 
--     Testbench for the SequenceGenerator entity. Samples three separate
--     sequences separated by 2 ms. Due to the psedo-random nature of outputs,
--     expected outputs cannot be known in advance, so tests cannot be
--     automated.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity SequenceGenerator_TB is
end SequenceGenerator_TB;

architecture SequenceGenerator_TB_ARCH of SequenceGenerator_TB is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';
    
    constant CLOCK_PERIOD: time := 10 ns;
    constant STEP_TIME: time := 2 ms;
    
    -----------------------------------------------------------------COMPONENT--
    -- uut: sequence generator
    component SequenceGenerator is
        port(
            reset: in std_logic;
            clock: in std_logic;
            
            nextEn: in std_logic;
            
            term: out std_logic_vector(3 downto 0);
            lastMode: out std_logic
        );
    end component;
    
    -------------------------------------------------------------------SIGNALS--
    signal reset: std_logic;
    signal clock: std_logic;
    
    -- inputs
    signal nextEn: std_logic;
    
    -- outputs
    signal term: std_logic_vector(3 downto 0);
    signal lastMode: std_logic;
begin
end SequenceGenerator_TB_ARCH;