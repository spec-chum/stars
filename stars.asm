; pasmo --tapbas stars.asm stars.tap

            org 32768

NUMSTARS    EQU 10
NUMLAYERS   EQU 4
WRITE       EQU $b0
ERASE       EQU $a8
SCREEN      EQU $4000

start:      xor     a               ; set up and clear screen to black
            out     ($fe), a
            ld      hl, SCREEN
            ld      de, SCREEN+1
            ld      bc, 6144
            ld      (hl), a
            ldir
            
            ld      bc, 768
            ld      a, 7            ; set PAPER 0 and INK 7
            ld      (hl), a
            ldir
            
            ld      b, NUMSTARS     ; loop counter
            ld      ix, STARS

firstloop:  push    bc
            
            ld      e, (ix)         ; get speed
            ld      b, (ix+1)       ; get x pos
            ld      c, (ix+2)       ; get y pos            
            ld      d, b            ; cache x pos
                        
            ld      a, WRITE        ; select OR (write pixel)
            call    plot
 
            ld      a, d
            sub     e               ; sub speed - looping back to 255 is fine
            ld      (ix+1), a       ; store new x pos
           
            inc     ix
            inc     ix
            inc     ix

            pop     bc
            djnz    firstloop
                             
movestars:  ld      b, NUMSTARS     ; loop counter
            ld      ix, STARS
            
mainloop:   push    bc
            
            ld      e, (ix)         ; get speed
            ld      b, (ix+1)       ; get x pos
            ld      c, (ix+2)       ; get y pos            
            ld      d, b            ; cache x pos
                        
            ld      a, WRITE        ; select OR (write pixel)
            call    plot
                        
            ld      a, d            ; reload x pos
            add     a, e            ; previous x pos
            ld      b, a            ; plot only clobbers b, so c is still y pos
            
            ld      a, ERASE        ; select XOR (erase pixel)
            call    plot

            ld      a, d
            sub     e               ; sub speed - looping back to 255 is fine
            ld      (ix+1), a       ; store new x pos
           
            inc     ix
            inc     ix
            inc     ix

            pop     bc
            djnz    mainloop
            
            halt
            
            jr      movestars 
            
plot:       ld      (op), a         ; write OR b ($b0) or XOR b ($a8)
            ld      a, c            ; IN: B = X, C = Y OUT: HL = address, A=offset
            and     7
            ld      h, a
            
            ld      a, c
            rra
            rra
            rra
            and     $18
            or      h
            or      $40
            ld      h, a
            
            ld      a, b
            rra
            rra
            rra
            and     $1f
            ld      l, a
            
            ld      a, c
            rla
            rla
            and     $e0
            or      l
            ld      l, a
            
            ld      a, b
            and     7
                 
            ld      b, a
            inc     b
            ld      a, 254
            
rotate:     rrca
            djnz    rotate
            ld      b, 255
            xor     b
            ld      b, a
            ld      a, (hl)
            
op:         nop                     ; placeholder for OR or XOR
            ld      (hl), a

            ret
            
STARS:      ;ds  NUMSTARS * 3       ; NUMSTARS * SPEED + STAR.Y + STAR.X
            db      3, 145, 2
            db      2, 56, 22
            db      4, 178,42
            db      2, 250, 62
            db      1, 98, 82
            db      2, 121, 102
            db      3, 61, 122
            db      4, 21, 142
            db      3, 81, 162
            db      3, 1, 182
            
end start