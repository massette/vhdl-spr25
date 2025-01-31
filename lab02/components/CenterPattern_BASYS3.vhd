--------------------------------------------------------------------------------
--
-- Lab 02 Demo: CenterPattern_BASYS3
-- Sean Graham
-- 
--     Wrapper for the CenterPattern entity on the BASYS3 board.
--
--     Inputs:
--       'sw' 3 leftmost, on-board switches. encode number of active bits
--       'btnD' on-board push button. reverses the direction of the pattern
--
--     Outputs:
--       'led' on-board leds. display the generated pattern
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity CenterPattern_BASYS3 is
    port(
        sw: in std_logic_vector(2 downto 0);
        btnD: in std_logic;
        led: out std_logic_vector(15 downto 0)
    );
end CenterPattern_BASYS3;

architecture CenterPattern_BASYS3_ARCH of CenterPattern_BASYS3 is
    -----------------------------------------------------------------COMPONENT--
    -- uut
    component CenterPattern is
        port(
            countBits: in std_logic_vector(2 downto 0);
            directionMode: in std_logic;

            mask: out std_logic_vector(15 downto 0)
        );
    end component;
begin
    -- map design to hardware
    -- in : sw, btnD
    -- out: led
    UUT: CenterPattern port map(
        countBits => sw,
        directionMode => btnD,
        
        mask => led
    );
end CenterPattern_BASYS3_ARCH;
