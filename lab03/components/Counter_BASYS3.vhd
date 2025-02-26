--------------------------------------------------------------------------------
-- 
-- Lab 03 Demo: Counter_BASYS3
-- Sean Graham
--
--     Wrapper implementing the Counter entity on the BASYS3 board.
--     
--     Inputs:
--       'clk' system clock
--       'btnD' on-board push button. resets the counter to 0.
--       'btnR' on-board push button. increments the counter
--
--     Outputs:
--       'led' on-board leds. only the led corresponding to count will be lit
--       'seg' 'an' seven segment display. shows current count in decimal
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Counter_BASYS3 is
    port(
        clk: in std_logic;
        
        btnR: in std_logic;
        btnD: in std_logic;
        
        led: out std_logic_vector(15 downto 0);
        seg: out std_logic_vector(6 downto 0);
        an: out std_logic_vector(3 downto 0)
    );
end Counter_BASYS3;

architecture Counter_BASYS3_ARCH of Counter_BASYS3 is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';
    
    -- when low input is followed by a high, signal has just gone high
    constant FIRST_ACTIVE: std_logic_vector(1 downto 0) := (ACTIVE, not ACTIVE);
    
    -- bcd literals
    constant BCD_BLANK: std_logic_vector(3 downto 0) := "0000";
    
    ----------------------------------------------------------------COMPONENTS--
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
    
    -- seven segment driver
    component SevenSegmentDriver is
        port(
            reset: in std_logic;
            clock: in std_logic;

            digit3: in std_logic_vector(3 downto 0);    --leftmost digit
            digit2: in std_logic_vector(3 downto 0);    --2nd from left digit
            digit1: in std_logic_vector(3 downto 0);    --3rd from left digit
            digit0: in std_logic_vector(3 downto 0);    --rightmost digit

            blank3: in std_logic;    --leftmost digit
            blank2: in std_logic;    --2nd from left digit
            blank1: in std_logic;    --3rd from left digit
            blank0: in std_logic;    --rightmost digit

            sevenSegs: out std_logic_vector(6 downto 0);    --MSB=g, LSB=a
            anodes:    out std_logic_vector(3 downto 0)    --MSB=leftmost digit
        );
    end component;
    
    -------------------------------------------------------------------SIGNALS--
    -- asynchronous inputs
    signal clock: std_logic;
    signal reset: std_logic;
    
    -- counter
    signal countEn: std_logic;
    signal countDigits: std_logic_vector(7 downto 0);
    
    -- bcd digits
    signal countTens: std_logic_vector(3 downto 0);
    signal countOnes: std_logic_vector(3 downto 0);
    
    -- seven seg
    signal blankTens: std_logic;
begin
    -- map async inputs
    clock <= clk;
    reset <= btnD;
    
    -- synchronize async button input and trigger on first cycle high
    -- note, physical_io_package has components for this
    -- in : btnR
    -- out: countEn
    CLEAN_INPUT: process (reset, clock) is
        -- buffer of the last 4 inputs
        -- introduces a small delay for inputs to propogate
        variable inputs: std_logic_vector(3 downto 0);
    begin
        if (reset = ACTIVE) then
            -- on reset, saturate the buffer with low inputs
            countEn <= not ACTIVE;
            inputs := (others => not ACTIVE);
        elsif rising_edge(clock) then
            -- shift next input into buffer
            inputs := btnR & inputs(3 downto 1);
            
            -- count only when the button is first pressed
            -- note, effectively shortens the synchronizer chain by 2
            if (inputs(1 downto 0) = FIRST_ACTIVE) then
                countEn <= ACTIVE;
            else
                countEn <= (not ACTIVE);
            end if;
        end if;
    end process;
    
    -- map counter to hardware
    -- in : (clock, reset) countEn
    -- out: countDigits, led
    UUT: Counter port map(
        reset => reset,
        clock => clock,
        
        countEn => countEn,
        
        digits => countDigits,
        mask => led -- drive led output
    );
    
    -- split BCD count into digits
    countTens <= countDigits(7 downto 4);
    countOnes <= countDigits(3 downto 0);
    
    -- blank leading digit when it is zero
    BLANK_LEADING: with countTens select
        blankTens <= ACTIVE       when "0000",
                     (not ACTIVE) when others;
    
    -- map seven segment component
    SEG_OUT: SevenSegmentDriver port map(
        reset => reset,
        clock => clock,

        digit3 => BCD_BLANK, -- don't care, will be blanked
        digit2 => BCD_BLANK, -- don't care, will be blanked
        digit1 => countTens,
        digit0 => countOnes,

        blank3 => ACTIVE, -- always blanked
        blank2 => ACTIVE, -- always blanked
        blank1 => blankTens,
        blank0 => (not ACTIVE), -- always visible
        
        sevenSegs => seg,
        anodes => an
    );
end Counter_BASYS3_ARCH;
