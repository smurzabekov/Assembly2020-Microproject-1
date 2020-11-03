format PE Console                            ; 32-��������� ���������� ��������� WINDOWS EXE
entry start                                  ; ����� �����

include 'include\win32a.inc'

section '.idata' import data readable        ; ������ ������������� �������

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

section '.data' data readable writeable      ; ������ ������
x1	dq ?		;��������� ��������
eps1	dd 0.0005	;�������� 0.05%
;���������
msg1	db 'Enter x (-1<=x<1): ',0
msg2	db 'Wrong number.',13,10,0
fmt1	db '%lf',0
msg3	db 'Teylor row = %lg',13,10,0
msg4	db 'Calculated ln(1-x) = %lg',13,10,0
buf	db 256 dup(0)
section '.code' code readable executable     ; ������ ����
start:                                       ; ����� ����� � ���������
	ccall [printf],msg1		;������� ���������
	ccall [gets],buf		;���� ������ � �������
	ccall [sscanf],buf,fmt1,x1	;��������������� ��������� ������ � �����
	cmp eax,1		;���� �������������� �������, 
	jz m1			;����������
	ccall [printf],msg2	;������� ��������� �� ������
	jmp start		;������ ������
m1:	fld [x1]		;x
	fld1			;1
	fcompp			;�������� 1 � ��������� ������
	fstsw	ax		;�������� ����� ������������ � ��
	sahf			;��������� �� � ����� ����������
	jbe start		;���� 1<=x, ������ ������
	fld [x1]		;x
	fld1			;1
	fchs			;-1
	fcompp			;�������� -1 � ��������� ������
	fstsw	ax		;�������� ����� ������������ � ��
	sahf			;��������� �� � ����� ����������
	ja start		;���� -1>x, ������ ������

	fld [eps1]		;�������� ����������
	sub esp,8		;�������� � ����� ����� ��� double
	fstp qword [esp]        ;�������� � ���� double �����     
	fld qword [x1]		;��������� ��������
	sub esp,8		;�������� � ����� ����� ��� double
	fstp qword [esp]        ;�������� � ���� double �����     
	call myln		;��������� myln(x,eps)
	add esp,16              ;������� ���������� ���������     

	sub esp,8		;�������� ����� ����
	fstp qword [esp]        ;������� ����� ����
	push msg3		;������ ���������
	call [printf]		;������������ ���������
	add esp,12		;��������� �����


	fld qword [x1]		;��������� ��������
	sub esp,8		;�������� � ����� ����� ��� double
	fstp qword [esp]        ;�������� � ���� double �����     
	call log		;��������� log(x)
	add esp,8		;������� ���������� ���������     

	sub esp,8		;�������� ������ �������� ���������
	fstp qword [esp]        ;������� ����� ����
	push msg4		;������ ���������
	call [printf]		;������������ ���������
	add esp,12		;��������� �����

	ccall [_getch]		;�������� ������� ����� �������
ex:	stdcall [ExitProcess], 0;�����

;double myln(double x,double eps)
;���������� ln(1-x) � ��������� eps
;���������� ������ cdecl
myln:
	push ebp		;������� ���� �����
	mov ebp,esp
	sub esp,14h		;�������� ��������� ����������
;��������� ����������
c	equ ebp-14h		;���������, �� ������� �����
p	equ ebp-10h		;������� �
a	equ ebp-8h		;�������� ���������� ���������� �����
;���������� ������� ���������
x	equ ebp+8h		
eps	equ ebp+10h
	fld1
	fstp qword [p]		;p = 1 
	mov dword [c],0		;c = 0
	fldz			;s=0
lp1:
;p *= x;
	fld qword [p]		;����������� ������� ����������
	fmul qword [x]
	fst qword [p]		
;c++
	inc dword [c]		;��������� ��������, �� ������� �����
;a = p / c 
	fidiv dword [c]		;�������� ��������� ���������
        fst qword [a]		;��������� ���
;s -= a;
	fsubp st1,st

	fld qword [a]		;a
	fabs			;|a|
	fcomp qword [eps]	;�������� |a| c eps
        fstsw ax		;��������� ����� ��������� � ��
        sahf			;������� ah � ����� ����������
	jnb lp1			;���� |a|>=eps, ���������� ����
	leave			;������ �������
	ret
;double log(double x)
;������ ���������� ln(x)
;���������� ������ cdecl
log:
	push ebp		;������� ���� �����
	mov ebp,esp
	fld1			;1
	fsub qword [ebp+8]	;1-x
	FLD1		;1
	fxch st1	;�������� ������� 1 � �
	FYL2X		;��������� 1*log2(x)
	FLDL2e		;��������� ��������� log2(e)
	fdivp st1,st	;log2(x)/log2(e)=ln(x)
	pop ebp			;������ �������
	ret
