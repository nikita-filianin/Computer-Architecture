TITLE LAB8
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
MODEL SMALL     ; Директива - тип моделі пам'яті
STACK 256   ; Директива - розмір стеку
 
;------------------------ІІ.МАКРОСИ---------------------------------------------------
; Макрос для ініціалізації
MACRO MInit
    mov ax, @data  ; ax <- @data
    mov ds, ax	; ds <- ax	
    mov es, ax	 ; es <- ax	
ENDM MInit        
;------------------ІІІ.ПОЧАТОК СЕГМЕНТУ ДАНИХ-----------------------------------------
DATASEG

; Меню та службові повідомлення
MENUmsg db "----------MENU----------",0
COUNTmsg db 'Calculate',0
SOUNDmsg db 'Beep',0
BIGGESTmsg db 'Biggest',0
ABOUTmsg db 'Authors',0
EXITmsg db 'Exit',0
INSTRmsg db "Use the up/down and Enter",0
MEmsg db 'Team 6: Filianin, Chaban, Hamad',0
EXPRmsg db "(a1-a2)*a3*a4+a5",0
VALUESmsg db "a1 = -1, a2 = 1, a3 = 1, a4 = 2, a5 = 3",0

; Константи 
	a1 EQU -1
	a2 EQU 1
	a3 EQU 1
	a4 EQU 2
	a5 EQU 3

; Константи для звуку
PORT_B EQU 61H
CHANNEL_2 EQU 42H
var db ?

; Структура для пунктів меню
Struc Item
	location  dw ?
	next dw ?
	previous dw ?
	function dw ?
Ends Item

; Ініціалізація структур
about Item <0,0,0>
count Item <1342,0,0>
sound Item <0,0,0>
exitI Item <0,0,0>
big Item <0,0,0>

exCode db 0

;------------------IV.ПОЧАТОК СЕГМЕНТУ КОДУ-------------------------------------------
CODESEG
Start:
MInit       ; Ініціалізація 
mov ax, 03
int 10h		; Очистка екрану
mov ax, 1003h       
mov bl, 00
int 10h		; Вимикаємо блимання
mov ax, 0B800h    
mov es, ax		; Підключення до відеопамяті

xor di, di
mov dh, 0 	; NULL
mov dl, 072h 	; Cірий колір
mov cx, 2000 	; Заповнюємо весь відеобуфер
background:
	call draw_to_video
	loop background
	
mov di, 860   		; Зміщення в відеобуфері
mov dh, 0 		; NULL
mov dl, 08Bh 	; Темно сірий колір
xor ax, ax
mov al, 112		; Відступ
	
push di
mov cx, 10 				; Довжина меню
menu_print:
	push cx
	mov cx, 24 	; Ширина меню
	menu_print_inn:
		call draw_to_video
		loop menu_print_inn
	pop cx
	add di, ax
	loop menu_print
pop di
mov dl, 077h
	
mov si, offset MENUmsg  ; Виводимо текст 
call printSI            

add di, 114	; Йдемо на наступний рядок
	
; Ініціалізуємо змінні структур
mov ax, offset count  
mov [exitI.next], ax
mov [sound.previous], ax
mov ax, offset sound  
mov [count.next], ax
mov [big.previous], ax
mov ax, offset exitI  
mov [about.next], ax
mov [count.previous], ax
mov ax, offset about  
mov [big.next], ax	
mov [exitI.previous], ax
mov ax, offset big  
mov [sound.next], ax	
mov [about.previous], ax

mov ax, [count.location] 
add ax, 160
mov [sound.location], ax
add ax, 160
mov [big.location], ax
add ax, 160
mov [about.location], ax	
add ax, 160
mov [exitI.location], ax
	
mov ax, offset authors
mov [about.function], ax
mov ax, offset count_exp
mov [count.function], ax
mov ax, offset beep
mov [sound.function], ax
mov ax, offset exit
mov [exitI.function], ax
mov ax, offset biggest_marker
mov [big.function], ax

; Виводимо текст пунктів в меню (в bx+2 знаходиться зміщення в відеобуфері для наступного елементу)
mov bx, offset count
mov di, [bx]
mov si, offset COUNTmsg   
call printSI      
mov bx, [bx+2]         
mov di, [bx]        
mov si, offset SOUNDmsg    
call printSI   
mov bx, [bx+2]       
mov di, [bx]		
mov si, offset BIGGESTmsg    
call printSI     
mov bx, [bx+2]       
mov di, [bx]	
mov si, offset ABOUTmsg     
call printSI     
mov bx, [bx+2]       
mov di, [bx]	
mov si, offset EXITmsg     
call printSI     

mov bx, offset count
call select      	; Виділяємо перший елемент
	 
mov di, 2720	
mov si, offset INSTRmsg	; Вводимо повідомлення з інструкціями	
call printSI        

; Обробка та зчитування символів
main_read:
	call read_char     
	cmp ah, 1ch		
	je inV			; Перевірка ентеру
	cmp ah, 48h
	je down			; Перевірка стрілки вниз
	cmp ah, 50h
	je up			; Перевірка стрілки вгору
	jmp main_read   ; Якщо символ неправильний, продовжуємо зчитувати

; Знімаємо виділення з елемента та виділяемо верхній
up:
	call unselect     
	mov bx, [bx+2]    
	call select       
	jmp main_read     

; Знімаємо виділення з елемента та виділяемо нижній
down:
	call unselect     
	mov bx, [bx+4]    
	call select       
	jmp main_read     

; Виконуємо відповідну функцію
InV:
	call clear_res    
	mov di, 3040   
	mov dl, 07Ch      
	mov ax,[bx+6]     
	jmp ax          ; Переходимо до функції обробки

; Обробка виразу
count_exp:
	mov si, offset EXPRmsg
	call printSI	; Виводимо вираз
	mov si, offset VALUESmsg
	mov di, 3040          
	add di, 160
	call printSI	; Виводимо змінні
	push bx
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
	mov dl, 070h
	mov di, 3040
	add di, 320
	call print_number	; Виводимо результат
	pop bx
	jmp main_read		; Продовжуємо зчитувати

; Пошук найбільшого
biggest_marker:
	mov si, offset VALUESmsg
	mov di, 3040          
	add di, 160
	call printSI       		   ; Виводимо змінні
	push ax
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
	mov dl, 070h
	mov di, 3040
	add di, 320
	call print_number	; Виводимо результат
	pop ax
	jmp main_read		; Продовжуємо зчитувати
	
beep:
	marker:
		int 16h			; Зберігає значення з клавіатури
		mov [var], al
		cmp [var], 'q'	; Перевірка на відповідність і встановлення прапору ознаки
		jz Exit
	
	mov al, 10110110b 		
	out 43H, al ; байт в порт командний регістр
	
		
	mov ax, 2705 		; лічильник
	out CHANNEL_2, al 	; відправка 
	mov al, ah 
	out CHANNEL_2,al ; відправка старшого байту

	in al, PORT_B 	; читання
	or al, 3 		; встановлення двох молодших бітів
	out PORT_B, al 	; пересилка байта в порт B 
	
	mov cx, 200
	; цикл для обмеження по часу (200 - 4 секунди)
	sound_o:
		push cx
		mov cx, 0ffffh
		loop $
		pop cx
		loop sound_o
		
	and al,11111100b ; скидаємо молодші біти
	out PORT_B, al ; пересилка байтів у зворотньому порядку
	jmp main_read  
	
authors:
	mov si, offset MEmsg
	call printSI	; Відображаємо результати
	jmp main_read   

Exit:
     mov ax, 0700h	; Очистка екрану
     mov bh, 07h	; Параметр для кольору символів,
     mov cx, 0h    
     mov dx, 184fh  
     int 10h        
     mov ah, 04Ch ; Номер вектора переривання DOS для виходу
     int 21h

; Процедура, для поміщення в відеопамять
; Вхід: di зміщення , dh - символ, dl - параметри для кольору 
proc draw_to_video
	mov [es:di], dh
	inc di
	mov [es:di], dl
	inc di
	ret
ENDP

; Процедура, що виділяє обраний пункт меню
; Вхід: BX - адреса початку рядка 
proc select
	mov di, [bx]
	inc di
	mov dl, 07Fh ; Колір фону
; Обмеженння виділеного рядка
	mov cx, 24
	sub cx, 2
	select_marker:
		mov [es:di], dl ; Змінюємо колір
		add di, 2 ; Переходимо до іншого кольору
		loop select_marker
	ret
ENDP
; Процедура, що очищає поле результату
proc clear_res
	mov di, 3040
	mov dh, 0 ; Пустий символ
	mov dl, 07Fh ; Колір фону
	mov cx, 480
	marker_to_clear:
		call draw_to_video
		loop marker_to_clear
	ret
ENDP

; Процедура, яка знімає виділення
; Вхід: BX - адреса початку рядка 
proc unselect
	mov di, [bx]
	inc di
	mov dl, 080h ; Колір фону 
; Обрізаємо боки
	mov cx, 24
	sub cx, 2
	unselect_marker:
		mov [es:di], dl ; Змінюємо колір
		add di, 2 ; Переходимо до наступного кольору
		loop unselect_marker
	ret
ENDP


; Процедура для поміщення рядку у відеопамять
; Вхід: - DL - фон, SI - початок рядка, DI - зміщення в відеопамяті
PROC printSI
	mov dl, 070h
	read_str:
		mov dh, [si] ; Читаємо символ з SI
		cmp dh, 0 ; Рядки закуінчуються 0, якщо бачимо 0 - закінчуємо роботу
		jne draw_str
		ret
		
	draw_str:
		call draw_to_video 
		inc si
		jmp read_str		
	ret
ENDP

; Процедура для відображення числа в відеопамять
; Вхід:  - ax - число
PROC print_number
	cmp ax, 0
	jge positive ; Якщо число більше 0, не відображаємо "-" 
	mov dh, '-'
	call draw_to_video ; Виводимо мінус
	neg ax
	positive:    ; Виводимо число
		add ax, 30h
		mov dh, al
		call draw_to_video
		ret
ENDP

; Процедура для зчитування клавіші
; Вихід: ah - введена клавіш, al - ASCII код клавіші
PROC read_char
	mov ah, 0
	mov di, 3040
	int 16h
	ret	
ENDP

END Start