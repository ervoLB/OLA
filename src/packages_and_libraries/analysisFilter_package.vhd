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

-- ===============================================================
-- Package definition
library ieee;
use ieee.Std_logic_1164.all;
use ieee.numeric_std.all;

use work.ola_package.all;

package analysisFilter_package is 
    
    type aF_inputs_type is record -- analysisFilter inputs
        sl_reset_slow      : std_logic;
        sl_dataValid       : std_logic;
        slvX_dataValue     : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
        sl_readRequest     : std_logic;
    end record;
    
    type aF_outputs_type is record -- analysisFilter outputs
        sl_hopDone_p   : std_logic;
        sl_dataValid   : std_logic;
        slvX_dataValue : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
    end record;


    type aF_wp_inputs_type is record -- analysisFilter_writeProcess inputs
        sl_reset_slow      : std_logic;
        sl_dataValid       : std_logic;
        slvX_dataValue     : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
    end record;
    
    type aF_wp_outputs_type is record -- analysisFilter_writeProcess outputs
        slvX_dataValue : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
        usX_dataAddr   : unsigned (ADDR_WIDTH_INIT-1 downto 0);
        sl_wrEnable    : std_logic;
        sl_hopDone_p   : std_logic;
    end record;
    

    type aF_rp_inputs_type is record -- analysisFilter_readProcess inputs
        sl_reset_slow      : std_logic;
        sl_hopDone_p_async : std_logic;
        sl_readRequest     : std_logic;
        slvX_dataValue     : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
    end record;
    
    type aF_rp_outputs_type is record -- analysisFilter_readProcess outputs
        usX_dataAddr   : unsigned  (ADDR_WIDTH_INIT-1 downto 0);
        sl_hopDone_p   : std_logic;
        sl_dataValid   : std_logic;
        slvX_dataValue : std_logic_vector(VALUE_WIDTH_INIT-1 downto 0);
    end record;
    

end analysisFilter_package;


package body analysisFilter_package is


end analysisFilter_package;

