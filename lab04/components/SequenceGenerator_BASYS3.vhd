--------------------------------------------------------------------------------
-- 
-- Lab 04 Demo: SequenceGenerator_BASYS3
-- Sean Graham
--
--     Wrapper implementing the SequenceGenerator entity on the BASYS3 board.
--     For each sequence generated, the terms are displayed one at a time,
--       switching at 4Hz. Upon reaching the end of a sequence, awaits input.
--
--     Inputs:
--       'clk' system clock
--       'btnD' on-board push button. resets generator to first seed
--       'btnR' on-board push button. if ready, selects next sequence
--                                    otherwise, does nothing
--
--     Outputs:
--       'seg' on-board seven-segment display. shows current term
--       'led' on-board leds. shows current term
--
--             all outputs blanked when no sequence is selected
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SequenceGenerator_BASYS3 is
    port(
        clk: in std_logic;
        
        btnD: std_logic;
        btnR: std_logic;

        led: std_logic_vector(15 downto 0)
        seg: std_logic_vector(15 downto 0)
        an: std_logic_vector(15 downto 0)
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
    -- button input
    component Debouncer is
        port(
            reset: in std_logic;
            clock: in std_logic;

            asyncIn: in std_logic;
            syncOut: out std_logic;
        );
    end component;
    
    component LevelDetector is
        port(
            reset: in std_logic;
            clock: in std_logic;

            trigger: in std_logic;
            pulseOut: out std_logic
        );
    end component;

    -- uut
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

    -- display drivers
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
    -- async signals
    signal reset: std_logic;
    signal clock: std_logic;
    
    -- handle inputs
    signal btnRSync: std_logic;
    signal readyEn: std_logic;

    -- timer
    signal timerEn: std_logic;

    -- sequence state
    signal currentState: t_SEQ_STATE;
    signal nextState: t_SEQ_STATE;
    
    signal loadSeqEn: std_logic;
    signal showSeqMode: std_logic;

    -- sequence generator
    signal readyEn: std_logic;
    signal seqTerm1: std_logic_vector(3 downto 0);
    signal seqTerm2: std_logic_vector(3 downto 0);
    signal seqTerm3: std_logic_vector(3 downto 0);
    signal seqTerm4: std_logic_vector(3 downto 0);
    signal seqTerm5: std_logic_vector(3 downto 0);

    -- multiplex terms
    signal currentIndex: integer range 1 to 5;
    signal currentTerm: integer range 0 to 15;
    signal lastTermMode: std_logic;

    -- seven segment driver
    signal segTens: std_logic_vector(3 downto 0);
    signal segOnes: std_logic_vector(3 downto 0);
    signal blankTens: std_logic;
begin
    -- map asynchronous signals
    reset <= btnD;
    clock <= clk;

    -- synchronize and debounce asynchronous button input
    -- in : (reset, clock) btnR
    -- out: btnRSync
    SYNC_READY: Debouncer port map(
        reset => reset,
        clock => clock,

        asyncIn => btnR,
        syncOut => btnRSync
    );

    -- only trigger when button is first pressed
    -- in : (reset, clock) btnRSync
    -- out: readyEn
    DETECT_READY: LevelDetector port map(
        reset => reset,
        clock => clock,

        trigger => btnRSync,
        pulseOut => readyEn
    );

    -- store and update state
    -- in : (reset, clock) nextState
    -- out: currentState
    SEQ_REG: process (reset, clock) is
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
    -- in : currentState, readyEn, nextEn, lastTermMode
    -- out: loadSeqEn, 
    SEQ_TRANS: process (currentState) is
    begin
        -- set defaults
        nextState <= currentState;
        loadSeqEn <= (not ACTIVE);
        showSeqMode <= (not ACTIVE);
        
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
                -- load next sequence, prepare to display 
                loadSeqEn <= ACTIVE;
                nextState <= SHOW_SEQ;

            ----------------------------------------------------------SHOW_SEQ--
            when SHOW_SEQ =>
                seqMode <= ACTIVE;
                
                -- wait for last term to be displayed
                if (timerEn = ACTIVE) and (lastTermMode = ACTIVE) then
                    nextState <= AWAIT_INPUT;
                end if;
        end case;
    end process;
    
    -- generate 5Hz pulse signal
    -- in : (reset, clock) loadSeqEn
    -- out: nextEn
    MAKE_TIMER: process (reset, clock) is
        variable count: integer range 0 to (TIMER_PERIOD / CLOCK_PERIOD);
    begin
        if (reset = ACTIVE) then
            -- reset to low
            count := 0;
            nextEn <= (not ACTIVE);
        elsif rising_edge(clock) then
            -- set default
            nextEn <= (not ACTIVE);

            if (loadSeqEn = ACTIVE) then
                -- clear when loading a new sequence
                count := 0;
            elsif (count < (TIMER_PERIOD / CLOCK_PERIOD)) then
                -- otherwise, increment counter
                count := count + 1;
            else
                -- set ready on overflow
                count := 0;
                nextEn <= ACTIVE;
            end if;
        end if;
    end process;

    -- map sequence generator to hardware
    -- in : (reset, clock) loadSeqEn
    -- out: seqTerm1, seqTerm2, seqTerm3, seqTerm4, seqTerm5
    UUT: SequenceGenerator port map(
        reset => reset,
        clock => clock,

        nextEn => loadSeqEn,

        random1 => seqTerm1,
        random2 => seqTerm2,
        random3 => seqTerm3,
        random4 => seqTerm4,
        random5 => seqTerm5
    );

    -- select current term in sequence
    -- in : (reset, clock) nextEn
    -- out: currentIndex
    SELECT_TERM: process (reset, clock) is
    begin
        if (reset = ACTIVE) then
            currentIndex <= 1;
        elsif rising_edge(clock) then
            -- update index
            if (loadSeqTerm = ACTIVE) then
                -- clear when reading new sequence
                currentIndex <= 1;
            elsif (nextEn = ACTIVE) then
                -- increment index
                if (currentIndex < 5) then
                    currentIndex <= currentIndex + 1;
                else
                    currentIndex <= 1;
                end if;
            end if;
        end if;
    end process;

    -- load selected term from sequence generator
    with currentIndex select
    currentTerm <= seqTerm1 when 1,
                   seqTerm2 when 2,
                   seqTerm3 when 3,
                   seqTerm4 when 4,
                   seqTerm5 when 5;

    -- check if we're on the final term of the sequence, for state transition
    CHECK_LAST: process (currentIndex) is
    begin
        if (currentIndex < 5) then
            lastTermMode <= ACTIVE;
        else
            lastTermMode <= (not ACTIVE);
        end if;
    end process;

    -- drive led outputs
    -- in : currentTerm
    -- out: led
    DRIVE_LED: process (currentTerm) is
        variable index: integer range 0 to 15;
    begin
        -- convert to integer index
        index := to_integer(unsigned(currentTerm));
        
        -- turn off all leds, except current term
        led <= (others => not ACTIVE);
        led(currentTerm) <= ACTIVE;
    end process;

    -- convert current term to bcd digits
    BCD_TENS: segTens <= std_logic_vector(to_unsigned(currentTerm / 10));
    BCD_ONES: segOnes <= std_logic_vector(to_unsigned(currentTerm mod 10));

    -- blank leading digit if zero
    -- in : segTens
    -- out: blankTens
    CHECK_TENS: process (segTens) is
    begin
        if (segTens = "0000") then
            blankTens <= ACTIVE;
        else
            blankTens <= (not ACTIVE);
        end if;
    end process;

    -- todo: drive seven seg output
    DRIVE_SEG: SevenSegmentDriver port map(
        reset => reset,
        clock => clock,

        digit3 => "0000",
        digit2 => "0000",
        digit1 => segTens,
        digit0 => segOnes,

        blank3 => ACTIVE,
        blank2 => ACTIVE,
        blank1 => blankTens,
        blank0 => (not ACTIVE),

        sevenSegs => seg,
        anodes => an
    );
end SequenceGenerator_BASYS3_ARCH;
