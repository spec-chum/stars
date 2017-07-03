; pasmo --tapbas stars.asm stars.tap

			org 32768

DEBUG		EQU	1

NUMSTARS	EQU 136
NUMLAYERS	EQU 4
SCREEN		EQU $4000

start:		xor		a				; set up and clear screen to black
			out		(254), a
			ld		hl, SCREEN
			ld		de, SCREEN+1
			ld		bc, 6143
			ld		(hl), a
			ldir
			
			ld		bc, 767
			ld		a, 7			; set PAPER 0 and INK 7
			ld		(de), a
			inc		hl
			inc		de
			ldir
			
init:		ld		b, NUMSTARS		; loop counter
			ld		ix, STARS		; ix = speed, x, y
			
firstloop:	push	bc

layer:		call	rand
			cp		NUMLAYERS
			jr		nc, layer
			inc		a				; make sure speed isn't 0
			ld		(ix), a			; store speed
			
			call	rand
			ld		(ix+1), a		; x can be any byte, so just store
			ld		b, a
			
ypos:		call	rand
			cp		192
			jr		nc, ypos
			ld		(ix+2), a		; store y
			ld		c, a
			
			call	plot
		   
			inc		ix
			inc		ix
			inc		ix

			pop		bc
			djnz	firstloop
							 
movestars:	
			IF DEBUG
				ld		a, 5		; put border to cyan
				out		(254), a	; write to port 254
			ENDIF
			
			ld		d, NUMSTARS
			ld		ix, STARS
			
mainloop:	ld		b, (ix+1)		; get x pos
			ld		c, (ix+2)		; get y pos			   
						
			call	plot
			
			ld		a, b
			sub		(ix)
			ld		b, a
			ld		(ix+1), a
			
			call	plot
		   
			inc		ix
			inc		ix
			inc		ix
			
			dec		d
			jp		nz, mainloop
			
			IF DEBUG
				xor		a			; set border to black
				out		(254), a	; write to port 254
			ENDIF
			
			halt

			jp			movestars
		
plot:		ld		a, b			; use copy of x coord
			rrca					; divide by 8
			rrca
			rrca
			and		31				; mask rotated in bits
			ld		h, a			; store in h
			
			ld 		a, c			; get y
			rla						; rotate y3 to y5 into position
			rla
			and 	224				; and isolate
			or 		h				; merge x (copy)
			ld 		l, a			; store in l
			
			ld 		a, c			; get y
			rra						; rotate y7 and y6 into position-1
			rra
			or 		128				; bring in high bit
			rra						; rotate y7 and y6 into position
			xor 	c				; merge lower 3 bits of y for y0 to y2
			and 	248
			xor 	c
			ld 		h, a			; store in h
			
			ld		a, b			; get pixel position
			and		7

			exx						
			ld		de, BITS
			add		a, e
			ld		e, a
			ld		a, (de)
			exx
			
			xor		(hl)
			ld		(hl), a

			ret
			
BITS:		db		128, 64, 32, 16, 8, 4, 2, 1

rand:		ld		hl, $A280   	; yw -> zt
			ld		de, $C0DE   	; xz -> yw
			ld		(rand+4), hl  	; x = y,  z = w
			
			ld		a, l         	; w = w ^ ( w << 3 )
			add		a, a
			add		a, a
			add		a, a
			xor		l
			ld		l, a
			
			ld		a, d         	; t = x ^ (x << 1)
			add		a, a
			xor		d
			ld		h, a
			rra             		; t = t ^ (t >> 1) ^ w
			xor		h
			xor		l
			
			ld		h, e         	; y = z
			ld		l, a         	; w = t
			ld		(rand+1), hl

			ret
			
seed:		dw		0
			
STARS:		ds		NUMSTARS * 3	; NUMSTARS * SPEED + STAR.X + STAR.Y
			
end start