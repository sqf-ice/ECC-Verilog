


;; POINT_ADD requirements
; R23 <- 2 * d
;; pt1
; R24 <- X1
; R25 <- Y1
; R26 <- Z1
; R27 <- T1
;; pt2
; R28 <- X2
; R29 <- Y2
; R30 <- Z2
; R31 <- T2

; R8 <- A = ((Y1-X1)*(Y2-X2)) % q
POINT_ADD_SR ADD R0, R25, #0 ; R0 <- Y1, Need to do this move because of Proc
ADD R22, R7, #0 ; Save PC of RET
SUB R2, R0, R24 ; R2 <- Y1 - X1
ADD R0, R29, #0 ; R0 <- Y2, Need to do this because of Proc
SUB R3, R0, R28 ; R3 <- Y2 - X2
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R8, R0, #0  ; R8 <- A


; R9 <- B = ((Y1+X1)*(Y2+X2)) % q
ADD R0, R25, #0 ; R0 <- Y1, Need to do this move because of Proc
ADD R2, R0, R24 ; R2 <- Y1 - X1
ADD R0, R29, #0 ; R0 <- Y2, Need to do this because of Proc
ADD R3, R0, R28 ; R3 <- Y2 - X2
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R9, R0, #0  ; R9 <- B

; C = T1*(2*d)*T2 % q  # 255 bits
ADD R2, R27, #0 ; R2 <- T1
ADD R3, R23, #0 ; R3 <- 2*d
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R2, R0, #0  ; R2 <- R0
ADD R3, R21, #0 ; R3 <- T2
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R10, R0, #0 ; R10 <- C

; D = Z1*2*Z2 % q
SRL R2, R26, #1 ; R2 <- Z1 * 2 ;; BUG May not work with overflow
CONST R1, #0    ; R1 <- 0 for mod
JSR MOD_SR      ; Mod result in R0
ADD R2, R0, #0  ; R2 <- mod result
ADD R3, R30, #0 ; R3 <- Z2
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R11, R0, #0 ; R11 <- D

; E = (B-A) % q
ADD R0, R9, #0  ; R0 <- B
SUB R2, R0, R8  ; R2 <- B - A
CONST R1, #0    ; R1 <- 0 for mod
JSR MOD_SR      ; Mod result in R0
ADD R12, R0, #0 ; R12 <- E

; F = (D-C) % q
ADD R0, R11, #0 ; R0 <- D
SUB R2, R0, R10 ; R2 <- D - C
CONST R1, #0    ; R1 <- 0 for mod
JSR MOD_SR      ; Mod result in R0
ADD R13, R0, #0 ; R13 <- F

; G = (D+C) % q
ADD R0, R11, #0 ; R0 <- D
ADD R2, R0, R10 ; R2 <- D + C
CONST R1, #0    ; R1 <- 0 for mod
JSR MOD_SR      ; Mod result in R0
ADD R14, R0, #0 ; R14 <- G

; H = (B+A) % q
ADD R0, R9, #0  ; R0 <- B
ADD R2, R0, R8  ; R2 <- B - A
CONST R1, #0    ; R1 <- 0 for mod
JSR MOD_SR      ; Mod result in R0
ADD R15, R0, #0 ; R15 <- H

; X3 = (E*F) % q
ADD R2, R12, #0 ; R2 <- E
ADD R3, R13, #0 ; R2 <- F
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R24, R0, #0 ; X1 <- X3

; Y3 = (G*H) % q
ADD R2, R14, #0 ; R2 <- G
ADD R3, R15, #0 ; R2 <- H
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R25, R0, #0 ; Y1 <- Y3

; Z3 = (F*G) % q
ADD R2, R13, #0 ; R2 <- F
ADD R3, R14, #0 ; R2 <- G
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R26, R0, #0 ; Z1 <- Z3

; T3 = (E*H) % q
ADD R2, R12, #0 ; R2 <- E
ADD R3, R15, #0 ; R2 <- H
JSR MULT_SR     ; Mult result in R1, R2
JSR MOD_SR      ; Mod result in R0
ADD R27, R0, #0 ; T1 <- T3

ADD R7, R22, #0 ; Rest PC of RET

ADD R24, R24, #0 ; printing for debuging
ADD R25, R25, #0 ; printing for debuging
ADD R26, R26, #0 ; printing for debuging
ADD R27, R27, #0 ; printing for debuging
DONE            ; Return



;; NOTE assumes that R2 and R3 are populated with the x and y
;; computes x * y and puts the result in R1(MSB) and R2(LSB)
;; BUG Check if top bits are cleared out if no overflow
;; reference: http://users.utcluj.ro/~baruch/book_ssce/SSCE-Shift-Mult.pdf
; Check signs
; CHKH R2
; if R2 is neg:
;   TCS R2, R2
;   CHKH R3
;   if R3 is neg:
;     TCS R3, R3
;     CONST R6, #0
;   else:
;     CONST R6, #1
; else:
;   CHKH R3
;   if R3 is neg:
;     TCS R3, R3
;     CONST R6, #1
MULT_SR CONST R6, #0  ; R6 <- 0, Both P or Both N
CHKH R2               ; R2 zp
BRzp LBL_R3           ; if r2 is 0 or pos then branch
TCS R2, R2            ; R2 is negative so invert
CHKH R3               ; is R3 0 or pos
BRzp LBL_R2N          ; if R3 is 0 or pos then branch
TCS R3, R3            ; R3 is negative so invert
BRzp LBL_MULT         ; flipped both so can go straight to mult
LBL_R3 CHKH R3        ; R2 is pos, need to check R3
BRzp LBL_MULT         ; if r3 is also pos or 0
TCS R3, R3            ; r3 is negative so invert
LBL_R2N CONST R6, #1  ; need to set flag to invert at the end, only one was neg
; Do the actual Multiplication
LBL_MULT CONST R0, #255
ADD R0, R0, #1          ; N = 256
CONST R1, #0            ; A = 0;
CHECK_SR CHKL R2        ; Check lowest bit of Q
BRz LBL_F               ; Yes/No
ADD R1, R1, R3          ; A <- A + B
LBL_F SDRH R1, R1, R2   ; Shift A_Q right
SDRL R2, R1, R2         ; Shift A_Q right
ADD R0, R0, #-1         ; N <- N - 1
BRnp CHECK_SR           ; N == 0?
SDL R1, R1, R2          ; split into {257,255}
CHKL R6                 ; is R0 0 or 1
BRz LBL_END_MULT
TCS R2                  ; R2 is low bits
TCDH R1                 ; R1 is high bits
LBL_END_MULT RTI        ; Return


; Mod Step
MOD_SR CHKH R1               ; R1 zp
BRzp LBL_MOD
TCS R2
TCDH R1
CONST R4, #1  ; need to set flag to invert at the end, only one was neg
LBL_MOD SLL R2, R2, #1   
SRL R2, R2, #1 ; ^ and this clear out top bit
SLL R0, R1, #4  ; R5 <- p << 4
SLL R6, R1, #1  ; R6 <- p << 1
ADD R0, R0, R6  ; R0 <- p << 4 + p << 1
ADD R3, R1, #0  ; R3 <- R1
ADD R0, R0, R3  ; R5 <- p << 4 + p << 1 + p
ADD R0, R0, R2  ; R5 <- p << 4 + p << 1 + p + r
CHKL R4                 ; is R0 0 or 1
BRz LBL_END_MOD
ADD R2, R0, #0
ADD R1, R16, #0
SUB R0, R1, R2
LBL_END_MOD RTI ; Result placed in R0