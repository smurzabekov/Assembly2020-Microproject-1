format PE Console                            ; 32-разрядная консольная программа WINDOWS EXE
entry start                                  ; точка входа

include 'include\win32a.inc'

section '.idata' import data readable        ; секция импортируемых функций

library kernel,'kernel32.dll',\
	user,'user32.dll',\
        msvcrt,'msvcrt.dll'

import  kernel,\
        ExitProcess,'ExitProcess'

import  msvcrt,\
	sscanf,'sscanf',\
	gets,'gets',\
	_getch,'_getch',\
	printf,'printf'

section '.data' data readable writeable      ; секция данных
x1	dq ?		;введенное значение
eps1	dd 0.0005	;точность 0.05%
;константы
msg1	db 'Enter x (-1<=x<1): ',0
msg2	db 'Wrong number.',13,10,0
fmt1	db '%lf',0
msg3	db 'Teylor row = %lg',13,10,0
msg4	db 'Calculated ln(1-x) = %lg',13,10,0
buf	db 256 dup(0)
section '.code' code readable executable     ; секция кода
start:                                       ; точка входа в программу
	ccall [printf],msg1		;вывести сообщение
	ccall [gets],buf		;ввод строки с консоли
	ccall [sscanf],buf,fmt1,x1	;преобразовываем введенную строку в число
	cmp eax,1		;если преобразование удалось, 
	jz m1			;продолжить
	ccall [printf],msg2	;вывести сообщение об ошибке
	jmp start		;начать заново
m1:	fld [x1]		;x
	fld1			;1
	fcompp			;сравнить 1 с введенным числом
	fstsw	ax		;записать флаги сопроцессора в ах
	sahf			;перенести их в флаги процессора
	jbe start		;если 1<=x, начать заново
	fld [x1]		;x
	fld1			;1
	fchs			;-1
	fcompp			;сравнить -1 с введенным числом
	fstsw	ax		;записать флаги сопроцессора в ах
	sahf			;перенести их в флаги процессора
	ja start		;если -1>x, начать заново

	fld [eps1]		;точность вычисления
	sub esp,8		;выделить в стеке место под double
	fstp qword [esp]        ;записать в стек double число     
	fld qword [x1]		;введенное значение
	sub esp,8		;выделить в стеке место под double
	fstp qword [esp]        ;записать в стек double число     
	call myln		;Вычислить myln(x,eps)
	add esp,16              ;удалить переданные параметры     

	sub esp,8		;передать сумму ряда
	fstp qword [esp]        ;функции через стек
	push msg3		;формат сообщения
	call [printf]		;сформировать результат
	add esp,12		;коррекция стека


	fld qword [x1]		;введенное значение
	sub esp,8		;выделить в стеке место под double
	fstp qword [esp]        ;записать в стек double число     
	call log		;Вычислить log(x)
	add esp,8		;удалить переданные параметры     

	sub esp,8		;передать точное значение логарифма
	fstp qword [esp]        ;функции через стек
	push msg4		;формат сообщения
	call [printf]		;сформировать результат
	add esp,12		;коррекция стека

	ccall [_getch]		;ожидание нажатия любой клавиши
ex:	stdcall [ExitProcess], 0;выход

;double myln(double x,double eps)
;вычисление ln(1-x) с точностью eps
;соглашение вызова cdecl
myln:
	push ebp		;создать кадр стека
	mov ebp,esp
	sub esp,14h		;создание локальных переменных
;локальные переменные
c	equ ebp-14h		;конствнта, на которую делим
p	equ ebp-10h		;степень х
a	equ ebp-8h		;значение очередного слагаемого суммы
;переданные функции параметры
x	equ ebp+8h		
eps	equ ebp+10h
	fld1
	fstp qword [p]		;p = 1 
	mov dword [c],0		;c = 0
	fldz			;s=0
lp1:
;p *= x;
	fld qword [p]		;накапливаем степень слагаемого
	fmul qword [x]
	fst qword [p]		
;c++
	inc dword [c]		;увеличить консанту, на которую делим
;a = p / c 
	fidiv dword [c]		;получили очередное слагаемое
        fst qword [a]		;сохранить его
;s -= a;
	fsubp st1,st

	fld qword [a]		;a
	fabs			;|a|
	fcomp qword [eps]	;сравнить |a| c eps
        fstsw ax		;перенести флаги сравнения в ах
        sahf			;занести ah в флаги процессора
	jnb lp1			;если |a|>=eps, продолжить цикл
	leave			;эпилог функции
	ret
;double log(double x)
;точное вычисление ln(x)
;соглашение вызова cdecl
log:
	push ebp		;создать кадр стека
	mov ebp,esp
	fld1			;1
	fsub qword [ebp+8]	;1-x
	FLD1		;1
	fxch st1	;поменять местами 1 и х
	FYL2X		;вычислить 1*log2(x)
	FLDL2e		;Загрузить константу log2(e)
	fdivp st1,st	;log2(x)/log2(e)=ln(x)
	pop ebp			;эпилог функции
	ret
