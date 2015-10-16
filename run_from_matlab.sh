# This command will generate a random C program using Csmith.
# This script is intended to be called from Matlab
echo "--Csmith Started--"
csmith --no-argc > randgen.c
#csmith --no-arrays --no-bitfields --no-consts --no-longlong --no-int8 --no-uint8 --max-block-depth 2 --no-structs --no-unions --no-volatiles --no-const-pointers --no-argc --no-safe-math > dhakacity.c
echo "--Csmith Completed--"
