;###################################################################################
;#  ���������� �������� �������� ����� � ���-������������ ������ �� ���� ATTINY13  #
;###################################################################################
.DEVICE ATtiny13
.INCLUDE "tn13def.inc"

;.list
.DEF	ST_FL = R20; 	������� ����� ���������

;ST_FL	=	0b76543210     ������� ����� ���������
;   		  IIIIIIII__________FL_B 	���� ���������� �� ���������� B
;			  IIIIIII___________CNT_DELAY ���� ��������� �����				
;			  IIIIII____________? ���� �������� ����������
;			  IIIII_____________? ���� ����� ���������� ���
;			  IIII______________
;			  III_______________
;			  II________________
;			  I_________________

.EQU	FL_B		=	1	; 0001, 1- ���������� ���������. �� ������������ �������������!
.EQU	FL_B_F		=	0 	; 321-0-, 0-�� ���	
.EQU	CNT_DELAY	=	2 	; 0010, 1-���� �������. �� ������������ �������������!
.EQU	CNT_DELAY_F	=	1 	; 32-1-0, 1-�� ���


.EQU	COUNTER  =	155
.EQU    COUNTER1 = 75
.EQU    COUNTERL = 0X016D ;02FF

	
;	������� 1���
;=================================================
; ������� SRAM ������
.DSEG	

FFLAG:	.BYTE 1

TTIMER:	.BYTE 2			
;=================================================
; ������� EEPROM ������
.ESEG				
;=================================================
; ������� FLASH ������
.CSEG


;******	INTERRUPT VECTORS		**************************************************
.ORG $000 
	RJMP RESET ; Reset Handler
.ORG $001
	RETI					; EXT_INT0 ; IRQ0 Handler
.ORG $002 
	RETI					; PCINT0 ; PCINT0 Handler
.ORG $003 
	RJMP TIM0_OVF 			; Timer0 Overflow Handler
.ORG $004 
	RETI					; EE_RDY ; EEPROM Ready Handler
.ORG $005 
	RETI					; ANA_COMP ; Analog Comparator Handler
.ORG $006
	RETI					; TIM0_COMPA ; Timer0 CompareA Handler	
.ORG $007 
	RETI					; TIM0_COMPB ; Timer0 CompareB Handler
.ORG $008 
	RETI					; WATCHDOG ; Watchdog Interrupt Handler
.ORG $009 
	RETI					; ADC ; ADC Conversion Handler


;******	INTERRUPTS				**************************************************
;----------------------------------------------------------------------
 TIM0_OVF: ;���������� �� ������������
    CLI
    SBR ST_FL, FL_B  ; ������������� ���� ����� ��������
RETI	

;****** ���������� �� ����������   *******************************************************
TIM0_COMPB:
;CLI
;LDI R16, 75
;IN R17, OCR0B
;ADD R17, R16
;OUT OCR0B, R17
;IN R18,OCR0B

;SBR ST_FL, FL_B  ; ������������� ���� ���������� ;LDI R20, 1 ; ���������� ���� ����

RETI 
	
;******	������������� �����		**************************************************
RESET:
		LDI		R16, 	RAMEND		; ����� ������ ������� �����
		OUT		SPL,	R16 		; ������ ��� � ������� �����
		

;*****	������������� ������	**************************************************
;	�������� ����� ��3 �� ����, ����������� ���������� �������
	LDI R16, 1<<PB0 | 1<<PB1
	OUT DDRB, R16
	LDI R16, 0<<PB0 | 0<<PB1
	OUT PORTB, R16

;	LDI R16,  1<<PB3 
;	OUT DDRB, R16
;	LDI R16, 1<<PB3
;	OUT PORTB, R16
	
	
;*****	������������� �������	**************************************************
;TCCR0A	����� ������ �������
;OCR0A - OUTPUT COMPARE REGISTER A  
	LDI R16, COUNTER ; ������� �������� ��������
	OUT OCR0A, R16
;OCR0B - OUTPUT COMPARE REGISTER A  
	LDI R16, COUNTER1 ; ������� �������� ��������
	OUT OCR0B, R16



	LDI	R16, 1<<COM0A1 | 0<<COM0A0 | 1<<WGM01 | 1<<WGM00 ;1<<COM0A1; 0<<COM0A0  ��������� 0 
							;�� ������ OC0A ��� ���������� � A, ��������� 1 �� ������ OC0A 
							;��� ��������� �ר����� (����������� �����)
							;1<<WGM01; 1<<WGM00 ����� FAST PWM
	OUT	TCCR0A, R16
	
;TCCR0B ����� ������ �������
	LDI R16,  0<<CS02 | 1<<CS01 | 1<<CS00	;	��������� 100 -256; 001 -0; 010 -8; 011 -64
	OUT TCCR0B, R16
	


;TIMSK0 
		LDI R16, 1<<TOIE0 | 1<<OCIE0B ; ������� �������� ��������
	OUT TIMSK0, R16

    CLR R16
    OUT TCNT0, R16
SEI
;*****	�������� ���������	**************************************************
        CLR ST_FL
        SBR ST_FL, 4 ;���������� �� ����� 3-� ���, ��� ������������ ����������� ���������
        ldi 	ZL,low(COUNTERL)	; �������� � ������� Z ������ RAM, 
		ldi 	ZH,high(COUNTERL); �� �������� ��������� ���������� � ��������
        
MAIN:
	SBRS ST_FL, 2 ; ��������� ��� ����������� ���������
	RJMP MAIN
    SBRC ST_FL,0; FL_B_F ;���������� ���� 0 ��� � �������� ������	
    RJMP DELAY
	RJMP MAIN



DELAY:
	CBR ST_FL, FL_B  ; ���������� ���� ���������� ;CLR R20
    SUBI ZL, 1
    SBCI ZH, 0
	BRCC MAIN	; 	������� ���� ������� ������
    RJMP TREE_SEC

 
 TREE_SEC:
    LDI R16, 1<<PB1
	OUT PORTB, R16
    CBR ST_FL, 4 ;���������� ���� ��������, �������� ������ ���

   	RJMP MAIN   

