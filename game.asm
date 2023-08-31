;file game
;screen 200x320

;README
;Jump over spikes
;ESC to exit

;SPIKES: 16, 40, 64 ... 304. total - 13. d = 24
;MAP_FILE: 0110100100100[CR][LF]1011010000101[CR][LF]0110100100100[CR][LF]0110100100100[CR][LF]0110100100100[CR][LF]  - 75
.model small
.stack 100h
.data
	map_fn db "game_map.txt", 0h
	map_fh dw 0000h 
	jump db 199, 197, 195, 194, 192, 191, 190, 189, 189, 188, 188, 188, 188, 188, 189, 189, 190, 191, 192, 194, 195, 197, 199 ;22
	eror db "An error occured$"
	map db 75 dup(?), 24h
	gmover db "GAME OVER$"

	floor db 00h
	x dw 00h
	y dw 00h
.code
start:
	mov dx, @data
	mov ds, dx
	
	call graphics
	
	;LINES
	;;;;;;;;==========================
	
	;color GREEN
	mov al, 0ah
	
	xor si, 160

	sss:
	mov y, si
	mov cx, 319
	ciklas:
	mov x, cx
	call pixel
	loop ciklas
	sub si, 40
	cmp si, 0
	ja sss
	
	;;;;;;;;;;;;;;======================
	
	;SPIKES FILE
	;open file
	mov ah, 3dh
	mov al, 0
	mov dx, offset map_fn
	int 21h
	mov map_fh, ax
	
	;read file
	mov ah, 3fh
	mov bx, map_fh
	mov cx, 75
	mov dx, offset map
	int 21h
	
	;close file
	mov ah, 3eh
	mov bx, map_fh
	int 21h
	
	;SPIKES ON SCREEN============
	mov di, 40 ;- 
	xor cx, cx
	mov bx, offset map
	
	j1:
	mov si, 16

	spikeline:
	mov al, [bx]
	
	cmp al, '1'
	jne no_spike
	
	mov x, si
	mov y, di
	call spike
	
	no_spike:
	add si, 24
	inc bx
	
	mov ah, [bx]
	cmp ah, 0Dh
	jnz spikeline
	
	inc cx
	add bx, 2
	add di, 40
	cmp cx, 5
	jb j1
	
	
	;PLAYER PIXEL
	;;;;;;;======================
	mov si, offset jump
	begin:
	xor di, di
	
	move:
	mov x, di
	cmp si, offset jump
	jae j3
	;FORWARD=================
	;which floor? y = 199 - floor * 40
	mov al, floor
	mov bl, 40
	mul bl
	mov bl, 199
	sub bl, al
	xor bh, bh
	mov y, bx
	jmp j2
	
	;JUMP===================
	j3:
	;y = [si] - floor * 40
	mov al, floor
	mov bl, 40
	mul bl
	mov bl, [si]
	sub bl, al
	xor bh, bh
	mov y, bx
	dec si
	
	j2:
	
	call pxread
	
	cmp al, 0bh
	jne dont_die
	;DIE===========
	call mirei
	jmp pabaiga
	dont_die:
	
	;MOVE==========
	;color RED
	mov al, 0ch
	call pixel
	
	;read keyboard
	call key_listen
	cmp al, 1bh ;escape >>> exit
	je pabaiga
	
	cmp al, ' '
	jne no_jump
	cmp si, offset jump
	ja no_jump
	mov si, offset jump + 22
	no_jump:
	
	
	call sleep
	inc di
	cmp di, 320
	jb move
	
	mov ah, floor
	inc ah
	mov floor, ah
	cmp ah, 5
	jb begin
	;;;;;;;===========================

	
pabaiga:
mov cx, 0010h
mov dx, 0000h
call sleep
	call exit

klaida:
	mov ah, 09h
	mov dx, offset eror
	int 21h
	call exit

;FUNCTIONS -------------------
graphics:
	mov ah, 00h
	mov al, 13h ;320x200 256color (mcga, vga)
	int 10h
ret

pixel: ;al = color
push ax
push bx
push cx
push dx
	mov ah, 0ch
	mov cx, x
	mov dx, y
	mov bh, 00h ;page number
	int 10h
pop dx
pop cx
pop bx
pop ax
ret

pxread: ;al - color

push bx
push cx
push dx
	mov ah, 0dh
	xor bh, bh
	mov cx, x
	mov dx, y
	int 10h
pop dx
pop cx
pop bx

ret

spike:
push ax
push bx
push cx
push dx
mov al, 0bh ;color blue
mov cx, 8 ;height
pxline:
	mov bx, y
	dec bx
	mov y, bx
	call pixel
loop pxline
pop dx
pop cx
pop bx
pop ax
ret


sleep: ;8.192ms
push ax
push cx
push dx
	mov ah, 86h
	mov dx, 2000h
	xor cx, cx
	int 15h
pop dx
pop cx
pop ax
ret

key_listen: ;return: al = key, no key - al = 00h
	mov ah, 0bh ;check stdin status. char - al = ffh, no char - al = 00h
	int 21h
	cmp al, 0
	jz skip

	mov ah, 00h ;read char from buffer, wait if empty. al = char
	int 16h
	
	skip:
ret

mirei:
	mov ah, 09h
	mov dx, offset gmover
	int 21h
ret
exit:
	mov ax, 4c00h
	int 21h
ret

end start