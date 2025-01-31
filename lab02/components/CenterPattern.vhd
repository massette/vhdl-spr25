--------------------------------------------------------------------------------
--
-- Lab 02 Demo: CenterPattern
-- Sean Graham
-- 
--     Generates a 16-bit pattern given a number of bits and a direction.
--
--     Inputs:
--       'countBits' binary string representing a 3-bit unsigned integer.
--           encodes the number of active bits in the mask
--       'directionMode' indicates direction pattern moves from center.
--           on '0', grows "right" from 7 down to 0,
--           on '1', grows "left" from 8 to 15.
--
--     Outputs:
--       'mask' contains the generated pattern
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity CenterPattern is
    port(
        countBits: in std_logic_vector(2 downto 0);
        directionMode: in std_logic;

        mask: out std_logic_vector(15 downto 0)
    );
end CenterPattern;

architecture CenterPattern_ARCH of CenterPattern is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';

    -- integer bit representations
    constant BITS_ZERO : std_logic_vector(2 downto 0) := "000";
    constant BITS_ONE  : std_logic_vector(2 downto 0) := "001";
    constant BITS_TWO  : std_logic_vector(2 downto 0) := "010";
    constant BITS_THREE: std_logic_vector(2 downto 0) := "011";
    constant BITS_FOUR : std_logic_vector(2 downto 0) := "100";
    constant BITS_FIVE : std_logic_vector(2 downto 0) := "101";
    constant BITS_SIX  : std_logic_vector(2 downto 0) := "110";
    constant BITS_SEVEN: std_logic_vector(2 downto 0) := "111";

    -- pattern literals
    -- note, could be replaced with arrays
    constant RIGHT_ZERO : std_logic_vector(7 downto 0) := "00000000";
    constant RIGHT_ONE  : std_logic_vector(7 downto 0) := "10000000";
    constant RIGHT_TWO  : std_logic_vector(7 downto 0) := "11000000";
    constant RIGHT_THREE: std_logic_vector(7 downto 0) := "11100000";
    constant RIGHT_FOUR : std_logic_vector(7 downto 0) := "11110000";
    constant RIGHT_FIVE : std_logic_vector(7 downto 0) := "11111000";
    constant RIGHT_SIX  : std_logic_vector(7 downto 0) := "11111100";
    constant RIGHT_SEVEN: std_logic_vector(7 downto 0) := "11111110";

    constant LEFT_ZERO  : std_logic_vector(7 downto 0) := "00000000";
    constant LEFT_ONE   : std_logic_vector(7 downto 0) := "00000001";
    constant LEFT_TWO   : std_logic_vector(7 downto 0) := "00000011";
    constant LEFT_THREE : std_logic_vector(7 downto 0) := "00000111";
    constant LEFT_FOUR  : std_logic_vector(7 downto 0) := "00001111";
    constant LEFT_FIVE  : std_logic_vector(7 downto 0) := "00011111";
    constant LEFT_SIX   : std_logic_vector(7 downto 0) := "00111111";
    constant LEFT_SEVEN : std_logic_vector(7 downto 0) := "01111111";

    -------------------------------------------------------------------SIGNALS--
    signal maskLeft: std_logic_vector(7 downto 0);
    signal maskRight: std_logic_vector(7 downto 0);
begin
    -- generate pattern on left bits, as if (directionMode = 0)
    -- in : countBits
    -- out: maskLeft
    MAKE_LEFT: with countBits select
        maskLeft  <= LEFT_ZERO   when BITS_ZERO,
                     LEFT_ONE    when BITS_ONE,
                     LEFT_TWO    when BITS_TWO,
                     LEFT_THREE  when BITS_THREE,
                     LEFT_FOUR   when BITS_FOUR,
                     LEFT_FIVE   when BITS_FIVE,
                     LEFT_SIX    when BITS_SIX,
                     LEFT_SEVEN  when others;

    -- generate pattern on right bits, as if (directionMode = 1)
    -- in : countBits
    -- out: maskRight
    MAKE_RIGHT: with countBits select
        maskRight <= RIGHT_ZERO  when BITS_ZERO,
                     RIGHT_ONE   when BITS_ONE,
                     RIGHT_TWO   when BITS_TWO,
                     RIGHT_THREE when BITS_THREE,
                     RIGHT_FOUR  when BITS_FOUR,
                     RIGHT_FIVE  when BITS_FIVE,
                     RIGHT_SIX   when BITS_SIX,
                     RIGHT_SEVEN when others;

    -- select correct mask based on actual value of directionMode
    MUX: with directionMode select
        mask <= (maskLeft & RIGHT_ZERO) when ACTIVE,
                (LEFT_ZERO & maskRight) when others;
end CenterPattern_ARCH;
