.PHONY: all clean

all: bindshell

bindshell: bindshell.o
	ld -m elf_x86_64 bindshell.o -o bindshell

bindshell.o: bindshell.asm
	nasm -f elf64 bindshell.asm

clean:
	rm bindshell.o bindshell
