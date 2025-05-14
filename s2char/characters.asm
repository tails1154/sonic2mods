Obj4D:
	; a0=character
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.w	goto_obj01_normal			; if not, branch
	jmp	(DebugMode).l
goto_obj01_normal:
    lea (Obj01_Normal), a6
    jmp (a6)
Obj4C:
	; a0=character
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	lea (Obj01_Normal),a6
	beq.w	goto_obj01_normal			; if not, branch
	jmp	(DebugMode).l
