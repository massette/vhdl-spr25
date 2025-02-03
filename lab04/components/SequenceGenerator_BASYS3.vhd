--------------------------------------------------------------------------------
-- 
-- Lab 04 Demo: SequenceGenerator_BASYS3
-- Sean Graham
--
--     Wrapper implementing the SequenceGenerator entity on the BASYS3 board.
--     For each sequence generated, the LEDs corresponding to the terms are lit
--     one at a time, switching at 4Hz. Upon reaching the end of a sequence,
--     waits for new input.
--
--     Inputs:
--       'clk' system clock
--       'btnD' on-board push button. resets generator to first seed
--       'btnR' on-board push button. if current sequence is done, begin next
--           sequence
--
--     Outputs:
--       'led' on-board leds. shows current term until end of current sequence,
--           otherwise unlit
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity SequenceGenerator_BASYS3 is
    port(
        clk: std_logic;
        
        btnD: std_logic;
        btnR: std_logic;
        sw: std_logic_vector(15 downto 0);

        led: std_logic_vector(15 downto 0)
    );
end SequenceGenerator_BASYS3;

architecture SequenceGenerator_BASYS3_ARCH of SequenceGenerator_BASYS3 is
    ----------------------------------------------------------TYPE DEFINITIONS--
    type t_SEQ_STATE is (AWAIT_INPUT, START_SEQ, SHOW_SEQ);

    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';

    -- timers
    constant CLOCK_PERIOD: time := 1 ns;
    constant TIMER_PERIOD: time := 200 ms;
    
    ----------------------------------------------------------------COMPONENTS--
    -- uut
    component SequenceGenerator is
        port(
            reset: in std_logic;
            clock: in std_logic;
        
            nextEn: in std_logic;

            random: out std_logic_vector(15 downto 0);
            lastTermMode: out std_logic
        );
    end component;

    -------------------------------------------------------------------SIGNALS--
    -- handle inputs
    signal readyEn: std_logic;

    -- timer
    signal timerEn: std_logic;

    -- game state
    signal currentState: t_SEQ_STATE;
    signal nextState: t_SEQ_STATE;
    
    signal seqMode: std_logic; -- indicates we are currently in a sequence

    -- sequence generator
    signal seqNextEn: std_logic;
    signal seqTerm: std_logic_vector(3 downto 0);
    signal lastTermMode: std_logic;
begin
    -- map asynchronous signals
    reset <= btnD;
    clock <= clk;

    -- synchronize asynchronous button input
    -- in : (reset, clock) btnD
    -- out: readyEn
    SYNC_READY: process (reset, clock) is
        variable inputs: std_logic_vector(3 downto 0);
    begin
        readyEn <= input(0);
        inputs := btnD & prev(3 downto 1);
    end process;
    
    -- generate 4Hz pulse signal
    -- in : (reset, clock)
    -- out: timerEn
    MAKE_TIMER: process (reset, clock) is
        variable count: integer range 0 to (TIMER_PERIOD / CLOCK_PERIOD);
    begin
        if (reset = ACTIVE) then
            -- reset to low
            count := 0;
            countEn <= (not ACTIVE);
        elsif rising_edge(clock) then
            -- set defaults
            countEn <= (not ACTIVE);

            -- update counter
            if (count < (TIMER_PERIOD / CLOCK_PERIOD)) then
                -- increment counter
                count := count + 1;
            else
                -- set high on overflow
                count := 0;
                countEn <= ACTIVE;
            end if;
        end if;
    end process;

    -- store and update state
    -- in : (reset, clock) nextState
    -- out: currentState
    GAME_REG: process (reset, clock) is
    begin
        if (reset = ACTIVE) then
            -- wait for next input after reset
            currentState <= AWAIT_INPUT;
        elsif rising_edge(clock) then
            -- update state every clock cycle
            currentState <= nextState;
        end if;
    end process;

    -- determine state outputs and next state
    -- in : currentState, readyEn, timerEn, seqLastMode
    -- out: nextState, seqMode
    GAME_TRANS: process (currentState) is
    begin
        -- set defaults
        nextState <= currentState;
        seqMode <= (not ACTIVE);
        
        -- do current state logic
        case currentState is
            -------------------------------------------------------AWAIT_INPUT--
            when AWAIT_INPUT =>
                -- transition on next user input
                if (readyEn = ACTIVE) then
                    nextState <= START_SEQ;
                end if;

            ---------------------------------------------------------START_SEQ--
            when START_SEQ =>
                -- synchronize with timer to avoid shortening first term
                if (timerEn = ACTIVE) then
                    nextState <= SHOW_SEQ;
                end if;

            ----------------------------------------------------------SHOW_SEQ--
            when SHOW_SEQ =>
                seqMode <= ACTIVE;
                
                -- wait for last term to be consumed
                if (timerEn = ACTIVE) and (seqLastMode = ACTIVE) then
                    nextState <= AWAIT_INPUT;
                end if;
        end case;
    end process;
    
    -- go to next term on timer when in a sequence
    seqNextEn <= (timerEn and seqMode);
    
    -- map sequence generator to hardware
    -- in : (reset, clock) nextEn
    -- out: seqTerm, seqLastMode
    UUT: SequenceGenerator port map(
        reset => reset,
        clock => clock,

        nextEn => seqNextEn,
        
        randomOut => seqTerm,
        lastMode => seqLastMode
    );

    -- drive led outputs
    -- in : seqTerm
    -- out: led
    DRIVE_LED: process (seqTerm) is
    begin
        -- turn off all leds, except current term
        led <= (others => not ACTIVE);
        led(seqTerm) <= ACTIVE;
    end process;
end SequenceGenerator_BASYS3_ARCH;
