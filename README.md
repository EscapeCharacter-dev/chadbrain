# Chadbrain
A buggy brainfuck interpreter written in assembly. Runs in real mode.
## Building
```
nasm -fbin -o chadbrain.bin main.asm
qemu-system-i386 chadbrain.bin # running the brainfuck interpreter
```
## Instructions
These are the instructions supported:  
 - `+`, Increments current cell
 - `-`, Decrements current cell
 - `>`, Increments cell pointer
 - `<`, Decrements cell pointer
 - `[`, If current cell is zero, jump to the next instruction after the next closing square bracket
 - `]`, If current cell is not zero, jump back to the next instruction after the previous closing square bracket
 - `.`, Prints out current cell
 - `,`, Reads character from input into current cell
 - `^`, Sets current cell value to 0xFF  
Pressing the ESCAPE key during instruction fetch will stop the current
   command.
## Help, it's doing weird stuff!
Restarting the machine should fix the bug. You can still make a pull
request if you think you found a bug in the code.