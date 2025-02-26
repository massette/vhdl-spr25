--------------------------------------------------------------------------------
--
-- Lab 03 Demo: Counter_TB
-- Sean Graham
-- 
--     Testbench for the Counter entity.
--
--     Tests the first 17 states of the counter, at which point behavior is
--       expected to loop. For each check, increments the counter then checks
--       state.
--
--     Note, code written in the wrapper is *not* tested by the testbench.
--       so you want to keep as much logic as reasonable in the UUT.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Counter_TB is
end Counter_TB;

architecture Counter_TB_ARCH of Counter_TB is
    ----------------------------------------------------------TYPE DEFINITIONS--
    -- grouped expected outputs of Counter
    type t_TEST is record
        digits: std_logic_vector(7 downto 0);
        mask: std_logic_vector(15 downto 0);
    end record t_TEST;
    
    -- a generic list of at least one test
    type t_TEST_ARRAY is array (positive range <>) of t_TEST;
    
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';
    
    constant CLOCK_PERIOD: time := 10 ns;
    constant STEP_TIME: time := 20 ns;
    
    -- tests
    constant ALL_TESTS: t_TEST_ARRAY(1 to 17) := (
        ( "00000000", "0000000000000001" ),
        ( "00000001", "0000000000000010" ),
        ( "00000010", "0000000000000100" ),
        ( "00000011", "0000000000001000" ),
        ( "00000100", "0000000000010000" ),
        ( "00000101", "0000000000100000" ),
        ( "00000110", "0000000001000000" ),
        ( "00000111", "0000000010000000" ),
        ( "00001000", "0000000100000000" ),
        ( "00001001", "0000001000000000" ),
        ( "00010000", "0000010000000000" ),
        ( "00010001", "0000100000000000" ),
        ( "00010010", "0001000000000000" ),
        ( "00010011", "0010000000000000" ),
        ( "00010100", "0100000000000000" ),
        ( "00010101", "1000000000000000" ),
        ( "00000000", "0000000000000001" )
    );
    
    -----------------------------------------------------------------COMPONENT--
    -- uut: counter
    component Counter is
        port(
            reset: in std_logic;
            clock: in std_logic;
            
            countEn: in std_logic;
            
            digits: out std_logic_vector(7 downto 0); -- bcd tens (15:8), ones (7:0)
            mask: out std_logic_vector(15 downto 0)
        );
    end component;
    
    -----------------------------------------------------------------FUNCTIONS--
    -- convert std_logic_vector to string for logging
    function print_bits (
        bits: std_logic_vector
    ) return string is
        variable bitsString: string(1 to bits'length);
        variable i: integer range 1 to bits'length;
    begin
        -- track position in string separately
        -- to show ranges in both directions correctly
        i := 1;
        
        -- set bits
        for j in bits'range loop
            -- note, std_logic'image takes the form "'X'", so extract 2nd char
            bitsString(i) := std_logic'image(bits(j))(2);
            i := i + 1;
        end loop;
        
        -- return between quotes
        return '"' & bitsString & '"';
    end function;
    
    -------------------------------------------------------------------SIGNALS--
    signal reset: std_logic;
    signal clock: std_logic;
    
    signal countEn: std_logic;
    signal digits: std_logic_vector(7 downto 0);
    signal mask: std_logic_vector(15 downto 0);
begin
    -- generate reset signal for synchronous elements
    -- out: reset
    DRIVE_RESET: process is
    begin
        -- reset to known state before running any tests
        reset <= ACTIVE;
        wait for 17 ns;
        
        -- keep low for rest of test
        reset <= not ACTIVE;
        wait;
    end process;
    
    -- generate clock for synchronous elements
    -- out: clock
    DRIVE_CLOCK: process is
    begin
        clock <= not ACTIVE;
        wait for (CLOCK_PERIOD / 2);
        
        clock <= ACTIVE;
        wait for (CLOCK_PERIOD / 2);
        
        -- note, processes unterminated by a wait will repeat indefinitely
    end process;
    
    -- generate test inputs for counter
    -- in : clock
    -- out: countEn
    DRIVE_INPUTS: process is
    begin
        -- initalize signals
        countEn <= (not ACTIVE);
        
        -- wait until the first clock cycle after reset
        wait until (reset = not ACTIVE);
        wait until rising_edge(clock);
        
        -- wait a little longer to avoid 0-width inputs
        wait for STEP_TIME;
        
        -- run all tests
        for i in ALL_TESTS'range loop
            -- alert if results do not match
            assert (digits = ALL_TESTS(i).digits)
                report "FAILED TEST #" & integer'image(i)
                & " (BCD). Expected " & print_bits(ALL_TESTS(i).digits)
                & ", received " & print_bits(digits);
            
            assert (mask = ALL_TESTS(i).mask)
                report "FAILED TEST #" & integer'image(i)
                & " (MASK). Expected " & print_bits(ALL_TESTS(i).mask)
                & ", received " & print_bits(mask);
            
            -- keep countEn active for one step
            countEn <= ACTIVE;
            wait for STEP_TIME;
            
            -- keep countEn low for next step
            countEn <= (not ACTIVE);
            wait for STEP_TIME;
        end loop;
        
        wait;
    end process;
    
    -- map counter to test signals
    UUT: Counter port map(
        clock => clock,
        reset => reset,
        
        countEn => countEn,
        
        digits => digits,
        mask => mask
    );
end Counter_TB_ARCH;
