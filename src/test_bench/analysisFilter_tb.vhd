-- The MIT License (MIT)
--
-- Copyright (c) 2024 Lovre Bogdanic, lovre.bogdanic@gmail.com
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.ola_package.all;
use work.analysisFilter_package.all;
 
entity analysisFilter_tb IS
end analysisFilter_tb;
 
architecture behavior OF analysisFilter_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    component analysisFilter
    generic (
        SIMULATION      : boolean;
        VALUE_WIDTH     : integer;
        HOP_SIZE        : integer;
        FRAME_SIZE      : integer;
        ADDR_WIDTH      : integer;  -- this generic is dependent from FRAME_SIZE -> ADDR_WIDTH = ceil(log2(FRAME_SIZE))
        ANA_WIN_SRCFILE : string
    );
    port(
         i_wrClk : in  std_logic;
         i_rdClk : in  std_logic;
         i_af    : in  aF_inputs_type;
         o_af    : out aF_outputs_type
        );
    end component;

    --Inputs
    signal i_wrClk : std_logic := '0';
    signal i_rdClk : std_logic := '0';
    signal i_af    : aF_inputs_type;

    --Outputs
    signal o_af    : aF_outputs_type;
   
    signal slvX_expectedValue : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0):=(others=>'0');
    signal slvX_currentValue  : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0):=(others=>'0');

    -- Clock period definitions
    constant i_wrClk_period : time := 200 ns;
    constant i_rdClk_period : time := 1 ns;
    constant rst_time       : time := 1000 ns;

begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: analysisFilter 
    generic map (
        SIMULATION      => TRUE,
        VALUE_WIDTH     => VALUE_WIDTH_INIT,
        HOP_SIZE        => HOP_SIZE_INIT,
        FRAME_SIZE      => FRAME_SIZE_INIT,
        ADDR_WIDTH      => ADDR_WIDTH_INIT,
        ANA_WIN_SRCFILE => ANA_WIN_SRCFILE_INIT
    )
    port map (
        i_wrClk => i_wrClk,
        i_rdClk => i_rdClk,
        i_af => i_af,
        o_af => o_af
    );



    -- reset generation
    i_af.sl_reset_slow <= '1', '0' after rst_time;       

    -- Clock process definitions
    i_wrClk_process :process
    begin
        i_wrClk <= '0';
        wait for rst_time/2;
        loop
            i_wrClk <= '1';
            wait for i_wrClk_period/2;
            i_wrClk <= '0';
            wait for i_wrClk_period/2;
        end loop;
    end process;
   
    i_rdClk_process :process
    begin
        i_rdClk <= '0';
        wait for rst_time/2;
        loop
            i_rdClk <= '1';
            wait for i_rdClk_period/2;
            i_rdClk <= '0';
            wait for i_rdClk_period/2;
        end loop;
    end process;

 
    -- Stimulus process
    generation_proc: process(i_wrClk)
        file infile        : text is in "..\..\..\..\verification\IO_files\anaInputs.txt";
        variable v_inline    : line;            --line number declaration
	    variable v_readValue : integer;
        
        variable v_invalidCounter    : integer;  -- to simulate number of invalid pixels that come between valid ones
        constant c_numberOfInvalids  : integer := 0;
    begin
        if rising_edge(i_wrClk) then
            if i_af.sl_reset_slow = '1' then
                i_af.sl_dataValid   <= '0';
                i_af.slvX_dataValue <= (others => '0');
                v_invalidCounter := 0;
            else
                if (v_invalidCounter = c_numberOfInvalids) then
                    v_invalidCounter := 0;
                    i_af.sl_dataValid <= '1';
                    if (not endfile(infile)) then     
                        readline(infile, v_inline);       --reading a line from the file.
                        --reading the data from the line and putting it in a variable.
                        read(v_inline, v_readValue);
                        i_af.slvX_dataValue <= std_logic_vector(to_signed(v_readValue,VALUE_WIDTH_INIT));
                    else
                        --report "Success: end of verification!" severity failure;
                        i_af.slvX_dataValue <= (others => '0');
                    end if;
                else
                    i_af.sl_dataValid <= '0';
                    v_invalidCounter := v_invalidCounter+1;
                end if;
            end if;
        end if;    
    end process;
    
    verification_proc: process(i_rdClk)
        file infile        : text is in "..\..\..\..\verification\IO_files\anaOutputs.txt";
        variable v_inline    : line;            --line number declaration
	    variable v_readValue : integer;
        
        variable v_expectedValue : integer := 0;
        variable v_currentValue  : integer := 0;
        
        variable v_readRequestCounter    : integer;  -- to simulate number of invalid pixels that come between valid ones
        constant c_readRequestRate  : integer := 0;
    begin
        if i_af.sl_reset_slow = '1' then
            i_af.sl_readRequest <= '0';
            v_readRequestCounter := 0;
        elsif rising_edge(i_rdClk) then
            if (v_readRequestCounter = c_readRequestRate) then
                v_readRequestCounter := 0;
                i_af.sl_readRequest <= '1';
            else
                v_readRequestCounter := v_readRequestCounter+1;
                i_af.sl_readRequest <= '0';
            end if;    

            if o_af.sl_dataValid = '1' then
                if (not endfile(infile)) then     
                    readline(infile, v_inline);       --reading a line from the file.
                    --reading the data from the line and putting it in a variable.
                    read(v_inline, v_readValue);
                    v_expectedValue := v_readValue;
                    v_currentValue  := to_integer(signed(o_af.slvX_dataValue));
                    if  v_currentValue /= v_expectedValue then
                        report "ERROR in readout" severity failure;
                    end if;
                    
                    -- only for debug
                    slvX_expectedValue <= std_logic_vector(to_signed(v_expectedValue,VALUE_WIDTH_INIT));
                    slvX_currentValue  <= o_af.slvX_dataValue;
                else
                    report "Success: end of verification!" severity failure;
                end if;
            end if;
        end if;    
    end process;

end behavior;
