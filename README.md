# OLA
Overlap-Add method implementation in VHDL

## Usage

This repo contains Vivado (2025.1) project file and random Spartan 7 device is taken just to have an example that works out of the box, but there is nothing manufacturer or device specific in the source code.

Hop and frame sizes and word width are flexible but I only worked with and tested power of two values. In order to change those values make following steps:

1) set wanted values in *verification/IO_files/OLA_model.py* and execute that python file in it's folder
    - *OLA_model.py* will generate needed analysis and synthesis window values that are used for BRAM initialization and, furthermore, it will generate IO files used in testbench for design verification
2) set above mentioned values in the *src/packages_and_libraries/ola_package.vhdl*
3) run implementation / simulation

## Notes on VHDL writing style

This code is written using ’two-process’ design method. More about this method you can read [here](https://download.gaisler.com/research_papers/vhdl2proc.pdf).

Simply put, it separates combinatorial logic and synchronization registers into two separate process (hence the name). It takes a bit to get used to, but it's very nice afterwords.

## License

MIT-License
