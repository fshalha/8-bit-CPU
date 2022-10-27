# This script takes in an assembly file and generates a file (named "instr_mem.mem") that contains 
# machine code which can be loaded into instr_mem array in Verilog (inside cpu.v)
# Author: Kisaru Liyanage

if [ $# -ne 1 ]; then
    echo "Usage: $0 sample_program.s"
    exit 1
fi

sample_program=$1

# assemble the assembly program into machine code
./CO224Assembler $sample_program &&

# remove old instr_mem.mem and create new one to store instruction memory content
rm instr_mem.mem
touch instr_mem.mem

# generate instruction memory content to be loaded into instr_mem array in Verilog (inside cpu.v)
while read line
do

    #echo $line
    byte3=$(echo $line | cut -c1-8)
    byte2=$(echo $line | cut -c9-16)
    byte1=$(echo $line | cut -c17-24)
    byte0=$(echo $line | cut -c25-32)
    echo $byte0" "$byte1" "$byte2" "$byte3 >> instr_mem.mem
    
done < $sample_program".machine"

echo "Instruction memory content generated!"