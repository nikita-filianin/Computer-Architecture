IDEAL
MODEL small
stack 256

DATASEG
exCode db 0
message1 db "Team 6: Anton Chaban",10,13
message2 db "Hamad Emad",10,13
message3 db "Nickita Filianin",10,13,'$'

CODESEG
Start:
mov ax,@data ; mov приемник, источник
mov ds, ax
mov es, ax
mov dx, offset message1 ; передаємо адресу пам'яті на наш меседж, так як ми не використовували символ '$', передаємо лише 1 меседж
mov ah,09h ; AH = 09h - WRITE STRING TO STANDARD OUTPUT
int 21h 
;mov dx, offset message2
;mov ah,9
;int 21h
mov ah,01h ; AH = 01h - READ CHARACTER FROM STANDARD INPUT, WITH ECHO
int 21h
mov ah,4ch ;AH = 4Ch - "EXIT" - TERMINATE WITH RETURN CODE
mov al,[exCode]
int 21h
end Start