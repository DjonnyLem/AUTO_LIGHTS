.DEVICE ATtiny13
.INCLUDE "tn13def.inc"


.DEF COUNTER	=	R16				; Счетчик (преимущественно используется для организации циклов)			;
.DEF	OSRG	=	R17
.DEF	TMP2	=	R18					;
.DEF	TMP3	=	R19					;
.DEF	TMP4	=	R20					; Некоторые переменные общего назначения
.DEF	FLAG_INER	=	R21
.DEF	FLAG_TIMERS	=	R22
.DEF	FLAG_ACTIONS	=	R23

.EQU	PWM_COUNTER  =	155		ЗНАЧЕНИЕ ШИМ
.EQU	TIMER_1	=	0X00	;(ЗАДЕРЖКА 0,5 СЕК)
.EQU    TIMER_2	=	0X24C	;Ob 0000 0010 0100 11000; 882 (ВРЕМЯ ПЛАВНОГО РОЗЖИГА 3 СЕК \ 882 ЦИКЛА СЧЕТЧИКА)
.EQU    TIMER_3	=	0X016D ;02FF (ЗАДЕРЖКА ВКЛЮЧЕНИЯ ДХО)

;============SSEG=============================================================
; СЕГМЕНТ SRAM ПАМЯТИ
			.DSEG
TIMERSPOOL1:
	.BUTE	=	2
TIMERSPOOL2:
	.BUTE	=	2
TIMERSPOOL3:
	.BUTE	=	2

;=================================================
; СЕГМЕНТ EEPROM ПАМЯТИ
.ESEG				
;=================================================
; СЕГМЕНТ FLASH ПАМЯТИ
.CSEG
;******	INTERRUPT VECTORS		**************************************************
.ORG $000 
	RJMP RESET ; Reset Handler
.ORG $001
	RJMP EXT_INT0			; EXT_INT0 ; IRQ0 Handler
.ORG $002 
	RJMP PCINT0				; PCINT0 ; PCINT0 Handler
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

;****** ВНЕШНЕЕ ПРЕРЫВАНИЕ **********************************
EXT_INT0:
	NOP
    RETI

;****** ПРЕРЫВАНИЕ ПО ВНЕШНЕМУ СОБЫТИЮ НА ПИНАХ **********************************
PCINT0:
	NOP
    RETI

;****** ПРЕРЫВАНИЕ ПО ПЕРПОЛНЕНИЮ ТАЙМЕРА ****************************************
TIM0_OVF: 
	NOP
	RETI	

;******	ИНИЦИАЛИЗАЦИЯ СТЕКА		**************************************************
RESET:
	LDI		TMP4, 	RAMEND		; ВЫБОР АДРЕСА ВЕРШИНЫ СТЕКА
	OUT		SPL,	TMP4 		; ЗАПИСЬ ЕГО В РЕГИСТР СТЕКА


		
;*****	ИНИЦИАЛИЗАЦИЯ ПОРТОВ	**************************************************
;	РЕГИСТОР ПОРТА РВ0 НА ВЫХОД, PB1-PB4 НА ВХОД С ПОДТЯЖКОЙ РЕГИСТРА
; PBO - ВЫХОД ШИМ, PB1 - СИГНАЛ С ТАХОМЕТРА, PB2- СИГНАЛ ВКЛЮЧЕНИЯ ГАБАРИТОВ, РВ3- СИГНАЛ С РУЧНИКА, РВ4 - СИГНАЛ С КНОПКИ
	LDI TMP4, 1<<PB0 | 0<<PB1 | 0<<PB2 | 0<<PB3 | 0<<PB4
	OUT DDRB, TMP4
	LDI TMP4, 0<<PB0 |1<<PB1 | 1<<PB2 | 1<<PB3 | 1<<PB4
	OUT PORTB, TMP4


;*****	ИНИЦИАЛИЗАЦИЯ ТАЙМЕРА КАК ШИМ И ПО ПЕРЕПОЛНЕНИЮ	*******************************************

;*** TCCR0A	РЕЖИМ РАБОТЫ ТАЙМЕРА
;OCR0A - OUTPUT COMPARE REGISTER A  -регистр сравнения
	LDI TMP4, PWM_COUNTER 		; ВЕРХНЕЕ ЗНАЧЕНИЕ СЧЕТЧИКА
	OUT OCR0A, TMP4
;OCR0B - OUTPUT COMPARE REGISTER A  
;	LDI TMP4, COUNTER1 ; 
;	OUT OCR0B, TMP4

;*** TCCR0A Timer/Counter Control Register A  -конфигурационный регистр таймера-счетчика
	LDI	TMP4, 1<<COM0A1 | 0<<COM0A0 | 1<<WGM01 | 1<<WGM00 
;				|			|			|----------|----- 1<<WGM01; 1<<WGM00 РЕЖИМ FAST PWM
;				|-----------|---------------------------- 1<<COM0A1; 0<<COM0A0 Очистить OC0A при совпадении, 
														  установить OC0A после переполнения ПРИ ОБНУЛЕНИИ 
														  СЧЁТЧИКА (НЕИНВЕРСНЫЙ РЕЖИМ)
	OUT	TCCR0A, TMP4
	
;*** TCCR0B imer/Counter Control Register B  -конфигурационный регистр таймера-счетчика
	LDI TMP4,  0<<CS02 | 1<<CS01 | 1<<CS00	;	ПРЕСКАЛЕР 100 -256; 001 -0; 010 -8; 011 -64
	OUT TCCR0B, TMP4
	


;*** TIMSK0  (Timer/Counter Interrupt Mask Register)
	LDI TMP4, 1<<TOIE0 | 0<<OCIE0A | 0<<OCIE0B	; TOIE0 - 0-е значение бита запрещает прерывание по событию переполнение, 1 - разрешает. 
									  			; OCIE0 - 0-е значение запрещает прерывания по событию совпадение, а 1 разрешает.
	OUT TIMSK0, TMP4


;*** TCNT0  Timer/Counter Register. Это регистр таймера счетчика.
    CLR TMP4	;ОЧИЩАЕМ РЕГИСТР
    OUT TCNT0, TMP4 ;ЗАНОСИМ 0 В ТАЙМЕР-СЧЕТЧИК


;*****	ИНИЦИАЛИЗАЦИЯ ВНЕШНЕГО ПРЕРЫВАНИЯ	*******************************************
;*** MCUCR – MCU Control Register Внешний регистр управления прерываниями A содержит биты управления для контроля значения прерываний
    LDI TMP4, 0<<ISC01 | 1<<ISC00 	;00- прерывание по низкому уровню, 01- прерывание по логическому изменению, 10- прерывание по ниспадающему фронту, 11- прерывание по нарастающему фронту
    OUT MCUCR, TMP4
;*** GIMSK– General Interrupt Mask Register Реестр масок прерываний
    LDI TMP4, 0<<INT0 | 1<<PCIE ;- INT0: запрос внешнего прерывания 0 разрешен;- PCIE: разрешение прерывания при смене вывода
    OUT GIMSK, TMP4
;*** GIFR – General Interrupt Flag Register Общий регистр флагов прерываний
    LDI TMP4, 0<<INTF0 | 1<<PCIF ;INTF0: флаг внешнего прерывания;  - PCIF: флаг прерывания смены вывода
    OUT GIFR, TMP4
;*** PCMSK – Pin Change Mask Register
    LDI TMP4, 0<<PCINT5 | 1<<PCINT4 | 1<<PCINT3| 1<<PCINT2| 1<<PCINT1| 0<<PCINT0
    OUT PCMSK, TMP4
 

   SEI	; глобально разрешаем прерывания





MAIN:
	
    NOP
    RJMP MAIN


