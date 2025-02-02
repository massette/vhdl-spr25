--------------------------------------------------------------------------------
--
-- Lab 02 Demo: CenterPattern_TB
-- Sean Graham
-- 
--     Testbench for the CenterPattern entity.
--
--     Tests all permutations of countBits in the default direction (left),
--       then again in the active direction (right). Reports to the console on
--       unexpected output.
--     Uses array and record types to automate tests.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CenterPattern_TB is
    -- note, a testbench will typically have an empty entity declaration
end CenterPattern_TB;

architecture CenterPattern_TB_ARCH of CenterPattern_TB is
    ----------------------------------------------------------TYPE DEFINITIONS--
    -- grouped inputs to CenterMask with their expected combinational output
    type t_TEST is record
        count: integer;
        direction: std_logic;
        result: std_logic_vector(15 downto 0);
    end record t_TEST;
    
    -- a generic list of at least one test
    type t_TEST_ARRAY is array (positive range <>) of t_TEST;
    
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';
    
    -- time width of each test
    constant STEP_TIME: time := 20 ns;
    
    -- directions
    constant RIGHT: std_logic := '0';
    constant LEFT : std_logic := '1';

    -- tests
    constant ALL_TESTS: t_TEST_ARRAY(1 to 16) := ( 
        ( 0, RIGHT, "0000000000000000" ),
        ( 1, RIGHT, "0000000010000000" ),
        ( 2, RIGHT, "0000000011000000" ),
        ( 3, RIGHT, "0000000011100000" ),
        ( 4, RIGHT, "0000000011110000" ),
        ( 5, RIGHT, "0000000011111000" ),
        ( 6, RIGHT, "0000000011111100" ),
        ( 7, RIGHT, "0000000011111110" ),
        ( 0, LEFT,  "0000000000000000" ),
        ( 1, LEFT,  "0000000100000000" ),
        ( 2, LEFT,  "0000001100000000" ),
        ( 3, LEFT,  "0000011100000000" ),
        ( 4, LEFT,  "0000111100000000" ),
        ( 5, LEFT,  "0001111100000000" ),
        ( 6, LEFT,  "0011111100000000" ),
        ( 7, LEFT,  "0111111100000000" )
    );
    
    -----------------------------------------------------------------COMPONENT--
    -- uut
    component CenterPattern is
        port(
            countBits: in std_logic_vector(2 downto 0);
            directionMode: in std_logic;

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
    
    -- convert t_TEST to a descriptive name
    function print_test(
        test: t_TEST
    ) return string is
    begin
        if (test.direction = RIGHT) then
            return "RIGHT_" & integer'image(test.count);
        else
            return "LEFT_" & integer'image(test.count);
        end if;
    end function;
    
    -------------------------------------------------------------------SIGNALS--
    signal countBits: std_logic_vector(2 downto 0);
    signal directionMode: std_logic;
    signal mask: std_logic_vector(15 downto 0);
begin
    -- generate test inputs
    -- in : no inputs
    -- out: countBits, directionBits
    DRIVE_INPUTS: process is
    begin
        -- initialize signals
        countBits <= (others => '0');
        directionMode <= RIGHT;
        
        -- run all test cases
        for i in ALL_TESTS'range loop
            countBits <= std_logic_vector(to_unsigned(ALL_TESTS(i).count, 3));
            directionMode <= ALL_TESTS(i).direction;
            
            -- alert if results do not match
            wait for STEP_TIME;
            assert (mask = ALL_TESTS(i).result)
                report "FAILED TEST #" & integer'image(i)
                & " (" & print_test(ALL_TESTS(i)) & ")"
                & ". Expected " & print_bits(ALL_TESTS(i).result)
                & ", received " & print_bits(mask);
        end loop;
        
        wait;
    end process;
    
    -- map test signals
    -- in : countBIts, directionBits
    -- out: no outputs
    UUT: CenterPattern port map(
        countBits => countBits,
        directionMode => directionMode,
        
        mask => mask
    );
end CenterPattern_TB_ARCH;
