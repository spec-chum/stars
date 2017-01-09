; pasmo --tapbas stars.asm stars.tap

            org 32768

NUMSTARS    EQU 50
NUMLAYERS   EQU 4
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
            
init:       ld      b, NUMSTARS     ; loop counter
            ld      ix, STARS       ; ix = speed, x, y
            
firstloop:  push    bc

layer:      call    rand
            cp      NUMLAYERS-1
            jr      nc, layer
            inc     a               ; make sure speed isn't 0
            ld      (ix), a         ; store speed
            ld      e, a
            
            call    rand
            ld      (ix+1), a       ; x can be any byte, so just store
            ld      b, a
            ld      d, a            ; cache x pos
            
ypos:       call    rand
            cp      192
            jr      nc, ypos
            ld      (ix+2), a       ; store y
            ld      c, a
            
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
                        
            call    plot
                        
            ld      a, d            ; reload x pos
            add     a, e            ; previous x pos
            ld      b, a            ; plot only clobbers b, so c is still y pos
            
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
            
plot:       ld      a, c            ; IN: B = X, C = Y OUT: HL = address, A=offset
            and     7
            ld      h, a
            
            ld      a, c
            rrca
            rrca
            rrca
            and     $18
            or      h
            or      $40
            ld      h, a
            
            ld      a, b
            rrca
            rrca
            rrca
            and     $1f
            ld      l, a
            
            ld      a, c
            rlca
            rlca
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
            
            xor     b
            ld      (hl), a

            ret
            
rand:       ld      hl, (seed)
            ld      a, h
            and     $1f             ; make sure we don't get RAM location
            ld      h, a
            ld      a, (hl)         ; put result in a
            inc     hl
            ld      (seed), hl
            
            ret
            
seed:       dw      0
            
STARS:      ds      NUMSTARS * 3    ; NUMSTARS * SPEED + STAR.X + STAR.Y
            
end start