; pasmo --tapbas stars.asm stars.tap

			org 32768

DEBUG		EQU	0

NUMSTARS	EQU 127
NUMLAYERS	EQU 4
SCREEN		EQU $4000
LASTK		EQU	23560

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
			
			ld		hl, LASTK		; reset LAST-K to 0
			xor		a
			ld		(hl), a			

keyloop:	cp		(hl)
			jr		z, keyloop
			
			ld		(hl), a
			
init:		ld		b, NUMSTARS		; loop counter
			ld		ix, STARS		; ix = speed, x, y
			
firstloop:	push	bc

layer:		call	rand
			cp		NUMLAYERS
			jr		nc, layer
			inc		a				; make sure speed isn't 0
			ld		(ix), a			; store speed
			ld		e, a
			
			call	rand
			ld		(ix+1), a		; x can be any byte, so just store
			ld		b, a
			ld		d, a			; cache x pos
			
ypos:		call	rand
			cp		192
			jr		nc, ypos
			ld		(ix+2), a		; store y
			ld		c, a
			
			call	plot
 
			ld		a, d
			sub		e				; sub speed - looping back to 255 is fine
			ld		(ix+1), a		; store new x pos
		   
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
			
			ld		b, NUMSTARS		; loop counter
			ld		ix, STARS
			
mainloop:	push	bc
			
			ld		e, (ix)			; get speed
			ld		b, (ix+1)		; get x pos
			ld		c, (ix+2)		; get y pos			   
			ld		d, b			; cache x pos
						
			call	plot
						
			ld		a, d			; reload x pos
			add		a, e			; previous x pos
			ld		b, a			; plot only clobbers b, so c is still y pos
			
			call	plot

			ld		a, d
			sub		e				; sub speed - looping back to 255 is fine
			ld		(ix+1), a		; store new x pos
		   
			inc		ix
			inc		ix
			inc		ix

			pop		bc
			djnz	mainloop
			
			IF DEBUG
				xor		a			; set border to black
				out		(254), a	; write to port 254
			ENDIF
			
			halt
			
			ld		a, (LASTK)		; test for keypress
			or		a			 
			
			jr		z, movestars	; loop if no key pressed

			ret						; return to BASIC		 
		
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

			
rand:		ld		hl, (seed)
			ld		a, r
			and		$3f				; make sure we don't get RAM location
			ld		h, a
			ld		a, (hl)			; put result in a
			inc		hl
			ld		(seed), hl
			
			ret
			
seed:		dw		0
			
STARS:		ds		NUMSTARS * 3	; NUMSTARS * SPEED + STAR.X + STAR.Y
			
end start