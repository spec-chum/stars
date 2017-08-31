; pasmo --tapbas stars.asm stars.tap

			org 32768

DEBUG		EQU	1

NUMSTARS	EQU 208
NUMLAYERS	EQU 4
SCREEN		EQU $4000

ADDR		EQU 0
SPEED		EQU 2
XPOS		EQU	3

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
			ld		(ix+SPEED), a	; store speed
			
			call	rand
			ld		(ix+XPOS), a	; x can be any byte, so just store
			rrca
			rrca
			rrca					; divide by 8 to get x byte
			and		%00011111		; mask off rotated in bits
			ld		b, a			; store for later
			
ypos:		call	rand			; y must be < 192
			cp		192
			jr		nc, ypos
			
			call	getY			; get y address and store
			ld		(ix+ADDR), l
			ld		(ix+ADDR+1), h
			
			ld		a, l			; add x byte
			add		a, b
			ld		l, a
			
			ld		a, (ix+XPOS)	; get pixel from x pos
			and		7
			exx
			ld		de, BITS
			add		a, e
			ld		e, a
			ld		a, (de)
			exx
			
			ld		(hl), a			; plot to screen
			
			ld		bc, 4
			add		ix, bc

			pop		bc
			djnz	firstloop
							 
movestars:	
			IF DEBUG
				ld		a, 5		; put border to cyan
				out		(254), a	; write to port 254
			ENDIF
			
			ld		d, NUMSTARS
			ld		ix, STARS
			
mainloop:	ld		l, (ix+ADDR)	; get y address
			ld		h, (ix+ADDR+1)
			
			ld		a, (ix+XPOS)	; get x byte
			ld		b, a			; and store
			rrca
			rrca
			rrca
			and		%00011111		; 31		
			ld		c, a			; store for later

			add		a, l			; add x byte
			ld		l, a
			
			ld		a, b			; restore x byte
			and		7				; get pixel pos
			exx
			ld		e, LOW BITS
			add		a, e
			ld		e, a
			ld		a, (de)
			exx
			
			xor		(hl)
			ld		(hl), a			; delete old star
			
			ld		a, l			; bring hl back to start of line
			sub		c
			ld		l, a
			
			ld		a, b			; restore x byte
			sub		(ix+SPEED)		; star.xpos -= speed
			ld		(ix+XPOS), a
			ld		b, a
			rrca					; get x byte same as above
			rrca
			rrca
			and		%00011111		; 31
			add		a, l
			ld		l, a
			
			ld		a, b
			and		7
			exx
			ld		e, LOW BITS
			add		a, e
			ld		e, a
			ld		a, (de)
			exx
			
			xor		(hl)			; draw new star
			ld		(hl), a
			
			ld		bc, 4
			add		ix, bc
			
			dec		d
			jp		nz, mainloop
			
			IF DEBUG
				xor		a			; set border to black
				out		(254), a	; write to port 254
			ENDIF
			
			halt

			jp			movestars

getY:		ld 		c, a			; store y
			rla						; rotate y3 to y5 into position
			rla
			and 	224				; and isolate
			ld 		l, a			; store in l
			
			ld 		a, c			; get y back
			rra						; rotate y7 and y6 into position-1
			rra
			or 		128				; bring in high bit
			rra						; rotate y7 and y6 into position
			xor 	c				; merge lower 3 bits of y for y0 to y2
			and 	248
			xor 	c
			ld 		h, a			; store in h

			ret
			
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
			
BITS:		db		128, 64, 32, 16, 8, 4, 2, 1
			
STARS:		ds		NUMSTARS * 4	; NUMSTARS * yAddress + SPEED + STAR.X
			
end start