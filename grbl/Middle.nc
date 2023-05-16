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
; Move to the middle
G0 X350 Y350 F2500 
