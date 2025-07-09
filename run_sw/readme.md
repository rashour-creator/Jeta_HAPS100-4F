# HAPS Node  
> This directory hosts crucial files and scripts necessary for running a C program on Riscv jeta design on the HAPS node.

## Directory Structure

    Top directory/|
                    |
                    |haps_cmd.sh
                        The primary script in this project enables the execution of various tasks. Utilize "help" to understand its usage.
                    |
                    
                    |setup.sh
                        Script used to load the required tools.
                   
                    |run
                        The run directory houses the essential run script and serves as the destination for log files resulted from running the 						application.
                        |
                        |run.sh
                            This script is used for running the C application. It is invoked by 'haps_cmd.sh' when executing the run options.

## How to Run
1. Open the terminal

2. Access the host "de06-lab46" to reach the HAPS system.

3. Bash theterminals and source haps_cmd.sh with "setup" argument in the terminal.

5. on the terminal:

    1. source haps_cmd.sh with "load_design" argument.
    2. umrbusscan -l to define the device number on this HAPS board.
    3. export emu_Device="the device number".
    4. trigger the required signals in protocompiler100_runtime. ## if needed

    5. source haps_cmd.sh with "assert_processor_reset" argument.
    6. run the triggered signals in protocompiler100_runtime from GUI #if needed
    7. source haps_cmd.sh with "load_sw" argument. ##Make sure that the .bin that want to be run is called in xtor_load_kernel.tcl file called by this command"

8. The waveformviewer icon in the protocompiler100_runtime GUI will be activated to check the waveforms.

## Important Notes
1. Utilize the "help" argument to discover all available options of haps_cmd.sh.
