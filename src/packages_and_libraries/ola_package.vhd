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
use ieee.Std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ola_package is 

    constant VALUE_WIDTH_INIT     : integer := 16;
    constant HOP_SIZE_INIT        : integer := 16;
    constant FRAME_SIZE_INIT      : integer := 64;

    constant SIMULATION_INIT      : boolean := FALSE;  -- NOTE: don't change this flag here. It is set in a testbench file.  
    constant ADDR_WIDTH_INIT      : integer := integer(log2(real(FRAME_SIZE_INIT)));  -- NOTE: needs to be log2(FRAME_SIZE_INIT)
    constant ANA_WIN_SRCFILE_INIT : string  := "..\..\src\init_files\analysisWindow_initFile.txt"; 
    constant SYN_WIN_SRCFILE_INIT : string  := "..\..\src\init_files\synthesisWindow_initFile.txt"; 

    type ola_inputs_type is record
        sl_reset_slow     : std_logic;
        sl_dataValid      : std_logic;
        slvX_dataValue    : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
    end record;

    type ola_outputs_type is record
        sl_dataValid     : std_logic;
        slvX_dataValue   : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
    end record;

end ola_package;


package body ola_package is


end ola_package;
