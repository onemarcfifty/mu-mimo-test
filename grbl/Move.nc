; enable Homing cycle
$22=1
; enable soft switches
$20=1
; Home XY
$H
; disable Homing cycle
$22=0
; disable soft switches
$20=0
; Status Report Setting
$10=0
; Set Current Position as Zero
G92 X0 Y0
; First move one node slowly to the end of the axis
G1 X0 Y500 F500
; now the second node to the end
G1 X500 Y500 F500
; move the first node back to zero
G1 X500 Y0 F500
; and both back to zero
G1 X0 Y0 F500
; Now we do the same movement twice but faster
G1 X0 Y500 F2500
G1 X500 Y500 F2500
G1 X500 Y0 F2500
G1 X0 Y0 F2500
G1 X0 Y500 F2500
G1 X500 Y500 F2500
G1 X500 Y0 F2500
G1 X0 Y0 F2500
