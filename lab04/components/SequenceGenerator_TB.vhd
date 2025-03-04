--------------------------------------------------------------------------------
--
-- Lab 03 Demo: SequenceGenerator_TB
-- Sean Graham
-- 
--     Testbench for the SequenceGenerator entity.
--
--     Tests 5 seperate seqiemces with arbitrary delays of 2-5 ms.
--     Due to the psedo-random nature of outputs, expected outputs cannot be
--     known in advance, so tests have not been automated.
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

            random1: out std_logic_vector(3 downto 0);
            random2: out std_logic_vector(3 downto 0);
            random3: out std_logic_vector(3 downto 0);
            random4: out std_logic_vector(3 downto 0);
            random5: out std_logic_vector(3 downto 0)
        );
    end component;
    
    -------------------------------------------------------------------SIGNALS--
    signal reset: std_logic;
    signal clock: std_logic;
    
    -- inputs
    signal nextEn: std_logic;
    
    -- outputs
    signal random1: std_logic_vector(3 downto 0);
    signal random2: std_logic_vector(3 downto 0);
    signal random3: std_logic_vector(3 downto 0);
    signal random4: std_logic_vector(3 downto 0);
    signal random5: std_logic_vector(3 downto 0);
begin
    -- generate reset for synchronous elements
    -- out: reset
    DRIVE_RESET: process is
    begin
        -- reset to known state before running tests
        reset <= ACTIVE;
        wait for 17 ns;
        
        -- keep low for rest of test;
        reset <= (not ACTIVE);
        wait;
    end process;
    
    -- generate clock for synchronous elements
    -- out: clock
    DRIVE_CLOCK: process is
    begin
        clock <= (not ACTIVE);
        wait for (CLOCK_PERIOD / 2);
        
        clock <= ACTIVE;
        wait for (CLOCK_PERIOD / 2);
    end process;
    
    -- generate test inputs for counter
    -- in : clock
    -- out: countEn
    DRIVE_INPUTS: process is
    begin
        -- initialize signals
        nextEn <= (not ACTIVE);
        
        -- wait for first clock cycle after reset
        wait until (reset = not ACTIVE);
        wait until rising_edge(clock);
        
        -- wait for first sequence
        wait for 2.3 ms;
        nextEn <= ACTIVE;
        wait for CLOCK_PERIOD;
        nextEn <= (not ACTIVE);
     
        -- wait for second
        wait for 3.1 ms;
        nextEn <= ACTIVE;
        wait for CLOCK_PERIOD;
        nextEn <= (not ACTIVE);
        
        -- wait for third
        wait for 4.8 ms;
        nextEn <= ACTIVE;
        wait for CLOCK_PERIOD;
        nextEn <= (not ACTIVE);
        
        -- wait for fourth
        wait for 3.3 ms;
        nextEn <= ACTIVE;
        wait for CLOCK_PERIOD;
        nextEn <= (not ACTIVE);
        
        -- wait for fifth
        wait for 2.5 ms;
        nextEn <= ACTIVE;
        
        -- hold high indefinitely, to check any patterns in generated sequences
        wait;
    end process;
    
    -- map sequence generator to test signals
    UUT: SequenceGenerator port map(
        clock => clock,
        reset => reset,
        
        nextEn => nextEn,
        
        random1 => random1,
        random2 => random2,
        random3 => random3,
        random4 => random4,
        random5 => random5
    );
end SequenceGenerator_TB_ARCH;