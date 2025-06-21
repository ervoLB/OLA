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

library std;
use std.textio.all;

entity simProbe_lite is
generic (
    VALUE_WIDTH   : integer;
    fileName      : string
);
port(
    i_clk       : in std_logic;
    i_dataValid : in std_logic;
    i_dataValue : in std_logic_vector(VALUE_WIDTH-1 downto 0)    
);
end simProbe_lite;

architecture behavioral of simProbe_lite is

begin
    verification_proc: process(i_clk)
        file outfile        : text open write_mode is fileName;
        variable outline    : line;   
	    variable writeValue : integer;
        
    begin
        if rising_edge(i_clk) then
            if i_dataValid = '1' then
                write(outline, integer'image(to_integer(signed(i_dataValue))) );
                writeline(outfile, outline);
            end if;
        end if;    
    end process;



end behavioral;