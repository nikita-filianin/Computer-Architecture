[org 0x7c00] ; Початок BOOT сектора
[bits 16]
; ЛР №7
;------------------------------------------------------------------------------
; Архітектура комп'ютера
; ВУЗ:          КНУУ "КПІ"
; Факультет:    ФІОТ
; Курс:         1
; Група:        ІТ-03
;------------------------------------------------------------------------------
; Автори:       Філянін Чабан Хамад
; Команда:      №6
; Дата:         28/04/2021

;---------------------ПОЧАТОК СЕГМЕНТУ КОДУ-------------------------------------------
call display_main
Main:

	; Викликаємо функцію зчитування з клавіатури
	call input
	
	; Перевіряємо отримані значення
	cmp al, "G"
	je count
	
	cmp al, "H"
	je beep
	
	cmp al, "k"
	je exit
	
	; Виводимо меню 
	call display_main
	jmp Main

; Основні мітки обробки запитів
count:
	call calculate
	jmp Main
	
beep:
	call beep_sound	
	jmp Main
	
exit:
	mov dx, exit_mes
	call printf

	jmp $
; вивід меню
display_main:
	pusha
	; переривання для очистки екрану
	mov ax, 03h
	int 0x10

	
	; виклик процедури для відображення меню порядково
	mov dx, menu_01
	call printf
	
	mov dx, menu_02
	call printf
	
	mov dx, menu_03
	call printf
	
	mov dx, menu_05
	call printf
	
	mov dx, menu_06
	call printf
	popa
	ret


wait_time: ; процедура очікування, простий перебіг за 2 циклами
pusha
push cx
mov cx, TIME
loop1:                 
  push cx               
  mov  cx,  TIME
  loop2:
     LOOP loop2
  pop  cx
  LOOP loop1
pop cx
popa
ret

; вивід звуку
beep_sound:
	marker:
		int 0x16			; Зберігає значення з клавіатури
		mov [symbol], al
		
	
	mov al, 10110110b 		
	out COMMAND_REG, al 	; байт в порт командний регістр
		
	mov bx, FREQUENCY		; виставляємо частоту
	mov dx, 0012h			; 
	mov ax, 34DDh			;
	div bx					;

	out 42h, al      	; вмикаємо таймер, що буде подавати імпульси на динамік за заданою частотою
	mov al, ah
	out 42h, al 		; відправка 
	mov al, ah 

	out CHANNEL_2,al 		; відправка старшого байту
	
	in al, PORT_B 			; читання
	or al, 3 				; встановлення двох молодших бітів
	out PORT_B, al 			; пересилка байта в порт B 
	
	call wait_time
	mov cx, 50
	sound_o:
		push cx
		mov cx, 0ffffh
		loop $
		pop cx
		loop sound_o
		
	and al,11111100b ; скидаємо молодші біти
	out PORT_B, al ; пересилка байтів у зворотньому порядку
	
	ret				; повертаємось з процедури

; обрахунок виразу
calculate:
; Вивід даних
	pusha
	mov dx, expression
	call printf
	
	mov dx, v1
	call printf
	
	mov dx, v2
	call printf
	
	mov dx, v3
	call printf
	
	mov dx, v4
	call printf
	
	mov dx, v5
	call printf
	
	xor dx, dx		; dx <- 0
	mov ax, a1		; ax <- a1
	mov bx, a2		; bx <- a2
	sub ax, bx		; ax <- a1-a2


	mov bx, a3 		; bx <- a3
	imul bx 		; ax <- ax*bx
	
	mov bx, a4		; bx <- a4
	imul bx			; ax <- ax*bx
	
	mov bx, a5		; bx <-a5
	add ax, bx		; ax <- ax+bx

	call result		; Результат
	mov ah, 0x01

	popa
	ret				; повертаємось з процедури

; вивід числа
result:
	cmp ax, 0
	jge pos				; ax > 0 
	
	push ax				; ax в стек
	mov al, '-'			
	mov ah, 0eh
	int 0x10			; вивід мінуса
	pop ax				; ax з стеку
	neg ax
	
; переривання для відображення числа
	pos:
		add ax, 30h		; в ascii код
		mov ah, 0eh
		int 0x10		; вивід числа
	
	ret					; повертаємось з процедури

printf:  
       pusha  
	   mov si, dx

	; Записуємо в AL поточний символ по зміщенню SI
       print_loop:
               mov al, [si]
               cmp al, 0
               jne print_char ; Якщо це ще не кінець рядка
               popa
               ret

       print_char:
               mov ah, 0x0e
               int 0x10 ; Друкуємо символ, що знаходиться в AL
               add si, 1 ; Переходимо до наступного символа в рядку
               jmp print_loop
;---------------------------------------------------------------------
input:
	mov ah, 0
	int 0x16
	ret
	
	; Константи для завдань по варінтам
	a1 EQU -1
	a2 EQU 1
	a3 EQU 1
	a4 EQU 2
	a5 EQU 3

	; Змінні для завдань по варінтам
	expression db "(a1-a2)*a3*a4+a5",13,10,0
	v1 db "a1 = -1",13,10,0
	v2 db "a2 = 1",13,10,0
	v3 db "a3 = 1",13,10,0
	v4 db "a4 = 2",13,10,0
	v5 db "a5 = 3",13,10,0
			
; Константи для виводу звуку
	mess db 0
	TIME EQU 10000
	FREQUENCY EQU 1000
	PORT_B EQU 61H
	COMMAND_REG EQU 43H
	CHANNEL_2 EQU 42H
	symbol db 0
	; Код виходу
	exCode db 0

	; Змінні для виводу меню
	menu_01 db "---------------MENU-----------------",13,10,0
	menu_02 db "G = count",13,10,0
	menu_03 db "H = beep",13,10,0
	menu_05 db "k = for exit",13,10,0
	menu_06 db "-------------MENU-END---------------",13,10,0
	exit_mes db "Finished",13,10,0

times 510-($-$$) db 0
dw 0xAA55