;###################################################################################
;#  йнмрпнккеп ябевемхъ дюкэмецн яберю я ьхл-пецскхпнбйни мюйюкю мю юбрн ATTINY13  #
;###################################################################################
.DEVICE ATtiny13
.INCLUDE "tn13def.inc"

;.list
.DEF	ST_FL = R20; 	пецхярп ткюцю янярнъмхи

;ST_FL	=	0b76543210     пецхярп ткюцю янярнъмхи
;   		  IIIIIIII__________FL_B 	ткюц опепшбюмхъ он янбоюдемхч B
;			  IIIIIII___________CNT_DELAY ткюц нйнмвюмхъ яверю				
;			  IIIIII____________? ткюц гюдепфйх опепшбюмхъ
;			  IIIII_____________? ткюц яверю мюпнярюмхъ ьхл
;			  IIII______________
;			  III_______________
;			  II________________
;			  I_________________

.EQU	FL_B		=	1	; 0001, 1- опепшбюмхе опнхгнькн. ме яапюяшбюеряъ юбрнлюрхвеяйх!
.EQU	FL_B_F		=	0 	; 321-0-, 0-ши ахр	
.EQU	CNT_DELAY	=	2 	; 0010, 1-явер нйнмвем. ме яапюяшбюеряъ юбрнлюрхвеяйх!
.EQU	CNT_DELAY_F	=	1 	; 32-1-0, 1-ши ахр


.EQU	COUNTER  =	155
.EQU    COUNTER1 = 75
.EQU    COUNTERL = 0X016D ;02FF

	
;	вюярнрю 1лцЖ
;=================================================
; яецлемр SRAM оюлърх
.DSEG	

FFLAG:	.BYTE 1

TTIMER:	.BYTE 2			
;=================================================
; яецлемр EEPROM оюлърх
.ESEG				
;=================================================
; яецлемр FLASH оюлърх
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
 TIM0_OVF: ;опепшбюмхе он оепеонкмемхч
    CLI
    SBR ST_FL, FL_B  ; сярюмюбкхбюер Ткюц яверю гюдепфйх
RETI	

;****** опепшбюмхе он янбоюдемхч   *******************************************************
TIM0_COMPB:
;CLI
;LDI R16, 75
;IN R17, OCR0B
;ADD R17, R16
;OUT OCR0B, R17
;IN R18,OCR0B

;SBR ST_FL, FL_B  ; сярюмюбкхбюер Ткюц опепшбюмхъ ;LDI R20, 1 ; бшярюбкъел рхою ткюц

RETI 
	
;******	хмхжхюкхгюжхъ ярейю		**************************************************
RESET:
		LDI		R16, 	RAMEND		; бшанп юдпеяю бепьхмш ярейю
		OUT		SPL,	R16 		; гюохяэ ецн б пецхярп ярейю
		

;*****	хмхжхюкхгюжхъ онпрнб	**************************************************
;	пецхярнп онпрю пб3 мю бунд, ондръцхбюел бмсрпеммхи пецхярп
	LDI R16, 1<<PB0 | 1<<PB1
	OUT DDRB, R16
	LDI R16, 0<<PB0 | 0<<PB1
	OUT PORTB, R16

;	LDI R16,  1<<PB3 
;	OUT DDRB, R16
;	LDI R16, 1<<PB3
;	OUT PORTB, R16
	
	
;*****	хмхжхюкхгюжхъ рюилепю	**************************************************
;TCCR0A	пефхл пюанрш рюилепю
;OCR0A - OUTPUT COMPARE REGISTER A  
	LDI R16, COUNTER ; бепумее гмювемхе явервхйю
	OUT OCR0A, R16
;OCR0B - OUTPUT COMPARE REGISTER A  
	LDI R16, COUNTER1 ; бепумее гмювемхе явервхйю
	OUT OCR0B, R16



	LDI	R16, 1<<COM0A1 | 0<<COM0A0 | 1<<WGM01 | 1<<WGM00 ;1<<COM0A1; 0<<COM0A0  сярюмнбйю 0 
							;мю бшбнде OC0A опх янбоюдемхх я A, сярюмнбйю 1 мю бшбнде OC0A 
							;опх намскемхх яв╗рвхйю (мехмбепямши пефхл)
							;1<<WGM01; 1<<WGM00 пефхл FAST PWM
	OUT	TCCR0A, R16
	
;TCCR0B пефхл пюанрш рюилепю
	LDI R16,  0<<CS02 | 1<<CS01 | 1<<CS00	;	опеяйюкеп 100 -256; 001 -0; 010 -8; 011 -64
	OUT TCCR0B, R16
	


;TIMSK0 
		LDI R16, 1<<TOIE0 | 1<<OCIE0B ; бепумее гмювемхе явервхйю
	OUT TIMSK0, R16

    CLR R16
    OUT TCNT0, R16
SEI
;*****	нямнбмюъ опнцпюллю	**************************************************
        CLR ST_FL
        SBR ST_FL, 4 ;сярюмнбхрэ бн ткюце 3-и ахр, дкъ нрякефхбюмхъ нркнфеммнцн бйкчвемхъ
        ldi 	ZL,low(COUNTERL)	; гЮЦПСГЙЮ Я ПЕЦХЯРП Z ЮДПЕЯЮ RAM, 
		ldi 	ZH,high(COUNTERL); ОН ЙНРНПНЛС МЮУНДХРЯЪ ХМТНПЛЮЖХЪ Н РЮИЛЕПЮУ
        
MAIN:
	SBRS ST_FL, 2 ; опнбепъел ахр нркнфеммнцн бйкчвемхъ
	RJMP MAIN
    SBRC ST_FL,0; FL_B_F ;оПНОСЯРХРЭ ЕЯКХ 0 АХР Б ПЕЦХЯРПЕ НВХЫЕМ	
    RJMP DELAY
	RJMP MAIN



DELAY:
	CBR ST_FL, FL_B  ; яапюяшбюел Ткюц опепшбюмхъ ;CLR R20
    SUBI ZL, 1
    SBCI ZH, 0
	BRCC MAIN	; 	оепеирх еякх оепемня нвхыем
    RJMP TREE_SEC

 
 TREE_SEC:
    LDI R16, 1<<PB1
	OUT PORTB, R16
    CBR ST_FL, 4 ;яапюяшбюер Ткюц гюдепфйх, гюдепфйх анкэье мер

   	RJMP MAIN   

