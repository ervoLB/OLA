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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity signedAdder is
generic (
    VALUE_WIDTH  : integer
);
port (  
    i_clk      : in std_logic;
    i_slvX_op1 : in std_logic_vector(VALUE_WIDTH-1 downto 0);
    i_slvX_op2 : in std_logic_vector(VALUE_WIDTH-1 downto 0);
    o_slvX_res : out std_logic_vector(VALUE_WIDTH-1 downto 0)
);
end entity signedAdder;

architecture rtl of signedAdder is


begin

    process (i_clk) is
    begin
        if rising_edge(i_clk) then
            o_slvX_res <= std_logic_vector(signed(i_slvX_op1) + signed(i_slvX_op2));
        end if;
    end process;
    
end rtl;