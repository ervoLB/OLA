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

use work.analysisFilter_package.all;
--
entity analysisFilter_writeProcess is
generic (
    VALUE_WIDTH   : integer;
    HOP_SIZE      : integer;
    FRAME_SIZE    : integer;
    ADDR_WIDTH    : integer
);
port(
    i_clk              : in std_logic;
    i_afWp             : in aF_wp_inputs_type;
    o_afWp             : out aF_wp_outputs_type
);
end entity analysisFilter_writeProcess;

architecture rtl of analysisFilter_writeProcess is


    type reg_type is record
        slvX_dataValue   : std_logic_vector(VALUE_WIDTH-1 downto 0);
        usX_dataAddr     : unsigned(ADDR_WIDTH-1 downto 0);
        usX_hopCounter   : unsigned(ADDR_WIDTH-1 downto 0);  -- TODO: add here generec value?
        sl_wrEnable      : std_logic;
        sl_hopDone_p     : std_logic;
        sl_resetFlag     : std_logic;
    end record;
    
    constant reg_type_Init : reg_type := (
        slvX_dataValue    => (others=>'0'),
        usX_dataAddr      => (others=>'1'), -- to manage to write on address 0 we need to set this on max value and on the first valid value it will be overflowed to address 0
        usX_hopCounter    => (others=>'1'), -- to count first valid value as 0
        sl_wrEnable       => '0',
        sl_hopDone_p      => '0',
        sl_resetFlag      => '1');

    signal r, c                : reg_type;

begin

    combinational_part : process(r,i_afWp)
        variable v : reg_type;
    begin
        v := r;
        
        v.sl_hopDone_p := '0';
        v.sl_wrEnable  := '0';
        
        v.slvX_dataValue := i_afWp.slvX_dataValue;       -- register input data
        if i_afWp.sl_dataValid = '1' then                -- if data is valid process it 
            v.usX_hopCounter  := r.usX_hopCounter + 1;  -- increment counter
            v.usX_dataAddr    := r.usX_dataAddr + 1;     -- set the address to counter value minus one
            v.sl_wrEnable     := '1';
            v.sl_resetFlag    := '0';
            
            if (r.usX_hopCounter = HOP_SIZE-1) and (r.sl_resetFlag = '0') then   -- usX_hopCounter can per default have HOP_SIZE-1 value and sl_resetFlag simply verifies
                                                                                 -- if this is default value or true number of valid values that are written in this cycle
                -- if this is last of the new hop values
                v.sl_hopDone_p    := '1';                -- send pulse
                v.usX_hopCounter := (others=>'0');      -- reset counter
            end if;
        end if;
        
        if i_afWp.sl_reset_slow = '1' then -- reset the unit
            v := reg_type_Init;
        end if;

        c <= v;                            -- variables to combinatorial signal
    end process;

    synchronous_part : process(i_clk)
    begin
        if rising_edge(i_clk) then
            r <= c;
        end if;
    end process;
    
    -- set outputs
    o_afWp.slvX_dataValue <= r.slvX_dataValue;
    o_afWp.usX_dataAddr   <= r.usX_dataAddr;
    o_afWp.sl_wrEnable    <= r.sl_wrEnable;
    o_afWp.sl_hopDone_p   <= r.sl_hopDone_p;
    
end rtl;
