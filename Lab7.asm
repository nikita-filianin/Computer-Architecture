TITLE LAB7
; ЛР  №7
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
;------------------------І.ЗАГОЛОВОК ПРОГРАМИ-----------------------------------------
IDEAL              ; Директива - тип Асемблера tasm
MODEL SMALL        ; Директива - тип моделі пам'яті
STACK 256          ; Директива - розмір стеку
;------------------------ІІ.МАКРОСИ---------------------------------------------------
; Макрос для ініціалізації
MACRO MInit
    mov ax, @data  ; ax <- @data
    mov ds, ax	   ; ds <- ax	
    mov es, ax	   ; es <- ax	
ENDM MInit         ; Кінець макроса
 
;------------------ІІІ.ПОЧАТОК СЕГМЕНТУ ДАНИХ-----------------------------------------
DATASEG
	string db 254 ; змінна для строки
	
	str_len db 0
	
	db 254 dup ('*') ; заповнюємо буфер "*"
	
	; Змінні для виводу меню
	menu_01 db "---------------MENU-----------------",13,10,'$'
	menu_02 db "G = count",13,10,'$'
	menu_03 db "H = beep",13,10,'$'
 	menu_04 db "k = for biggest",13,10,'$' 
	menu_05 db "c = for exit",13,10,'$'
	menu_06 db "-------------MENU-END---------------",13,10,'$'
	exit_mes db "Finished",13,10,'$'
	
	; Константи для виводу звуку
	mess db ?
	TIME EQU 3000
	FREQUENCY EQU 1000
	PORT_B EQU 61H
	COMMAND_REG EQU 43H
	CHANNEL_2 EQU 42H
	symbol db ?
	
	; Змінні для завдань по варінтам
	expr db "(a1-a2)*a3*a4+a5",13,10,'$'
	v1 db "a1 = -1",13,10,'$'
	v2 db "a2 = 1",13,10,'$'
	v3 db "a3 = 1",13,10,'$'
	v4 db "a4 = 2",13,10,'$'
	v5 db "a5 = 3",13,10,'$'
	
	; Константи для завдань по варінтам
	a1 EQU -1
	a2 EQU 1
	a3 EQU 1
	a4 EQU 2
	a5 EQU 3
	
	; Код виходу
	exCode db 0

;------------------IV.ПОЧАТОК СЕГМЕНТУ КОДУ-------------------------------------------
CODESEG
Start:
MInit				; Виклик макросу
	
Main:
	; Виводимо меню 
	call display_main
	; Викликаємо функцію зчитування з клавіатури
	call input
	
	; Перевіряємо отримані значення
	cmp ax, 047h
	je count
	
	cmp ax, 048h
	je beep
	
	cmp ax, 063h
	je exit
	
	cmp ax, 06Bh
	je findbiggest
	
	jmp Main

; Основні мітки обробки запитів
count:
	call calc
	jmp Main
	
beep: 
	call beep_sound	
	jmp Main
	
findbiggest:
	call big
	jmp Main
	
exit:
	mov dx, offset exit_mes
	call print

;---------------------------------4. Вихід з програми-----------------------------
	mov ah,4ch					; Завантаження числа 4ch до регістру ah
								; (Функція DOS 4ch - виходу з програми)
	mov al,[exCode] 			; отримання коду виходу
	int 21h 					; виклик функції DOS 4ch

; Призначення: вивід меню
; Вхід: -
; Вихід: -
PROC display_main
	; переривання для очистки екрану
	mov ah, 0
	mov al, 3
	int 10h
	
	; виклик процедури для відображення меню порядково
	mov dx, offset menu_01
	call print
	
	mov dx, offset menu_02
	call print
	
	mov dx, offset menu_03
	call print
	
	mov dx, offset menu_04
	call print
	
	mov dx, offset menu_05
	call print
	
	mov dx, offset menu_06
	call print
	
	ret
ENDP display_main

; Призначення: зчитування символів з клавіатури
; Вхід: -
; Вихід: -
PROC input
	mov ah, 0ah
	mov dx, offset string 	;записуємо початок буферу в регістр
	int 21h
	
	xor ax,ax
	mov bx, offset string 	; записуємо початок буферу в регістр
	mov ax, [bx+1] 			; заносимо в ах значення символа
	shr ax, 8				; зсув в регістрі ax
	ret						; повертаємось з процедури
ENDP input

; Призначення: відображення змінної
; Вхід: dx
; Вихід: -
PROC print
	mov ah, 9h		; Переривання для виводу в консоль
	int 21h			; виклик переривання 9h
	xor dx,dx		; очистка dx
	ret				; повертаємось з процедури
ENDP print

PROC wait_time ; процедура очікування, простий перебіг за 2 циклами
push cx
mov cx, TIME
loop1:                 
  PUSH cx               
  MOV  cx,  TIME
  loop2:
     LOOP loop2
  POP  cx
  LOOP loop1
pop cx
ret
ENDP wait_time  ; кінець процедури очікування

; Призначення: вивід звуку
; Вхід: -
; Вихід: -
PROC beep_sound
	marker:
		int 16h 			; Зберігає значення з клавіатури
		mov [symbol], al
		cmp [symbol], 'q' 	; Перевірка на відповідність і встановлення прапору ознаки
		jz Exit
	
	mov al, 10110110b 		
	out COMMAND_REG, al 	; байт в порт командний регістр
		
	mov bx, FREQUENCY		; виставляємо частоту
	mov dx,0012h			; 
	mov ax,34DDh			;
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
ENDP beep_sound

; Призначення: вирахунок виразу
; Вхід: -
; Вихід: -
PROC calc
; Вивід даних
	mov dx, offset expr
	call print
	
	mov dx, offset v1
	call print
	
	mov dx, offset v2
	call print
	
	mov dx, offset v3
	call print
	
	mov dx, offset v4
	call print
	
	mov dx, offset v5
	call print
	
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
	mov ah ,01h
	int 21h			; Переривання 1h
	ret				; повертаємось з процедури
ENDP calc

; Призначення: знаходження найбільшого значення
; Вхід: -
; Вихід: -
PROC big
; Вивід даних
	mov dx, offset v1
	call print
	
	mov dx, offset v2
	call print
	
	mov dx, offset v3
	call print
	
	mov dx, offset v4
	call print
	
	mov dx, offset v5
	call print
	
	mov ax, a1 		; ax <- a1
	cmp ax, a2 		; порівнюємо a1 та a2
	jg comp2 		; якщо а2 < а1
	mov ax, a2 		; якщо а2 > а1
comp2:
; Ідентично, але з новим ax, якщо знаходить більше
	cmp ax, a3
	jg comp3
	mov ax, a3
comp3:
	cmp ax, a4
	jg comp4
	mov ax, a4

comp4:
	cmp ax, a5
	jg biggest
	mov ax, a5
	
biggest:
	; Результат
	call result
	
	mov ah ,01h
	int 21h			; Переривання 1h
	ret				; повертаємось з процедури
ENDP big

; Призначення: вивід числа
; Вхід: ax - число
; Вихід: -
PROC result
	cmp ax, 0
	jge pos				;ax > 0 
	
	push ax				; ax в стек
	mov al, '-'			
	mov ah, 0eh
	int 10h 			; вивід мінуса
	pop ax				; ax з стеку
	neg ax
	
; переривання для відображення числа
	pos:
		add ax, 30h		; в ascii код
		mov ah, 0eh
		int 10h			; вивід числа
	
	ret					; повертаємось з процедури
ENDP result

end Start