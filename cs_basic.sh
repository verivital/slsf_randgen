# Basic driver for running csmith. We can only detect compiler crash for default gcc
set -e
while [ true ]
do
  echo "--x--";
  ./timeout.sh csmith --no-arrays --no-bitfields --no-consts --no-longlong --no-int8 --no-uint8 --max-block-depth 2 --no-structs --no-unions --no-volatiles --no-const-pointers --no-argc --no-safe-math > test.c;
  gcc -O -w test.c -o /dev/null;
done
