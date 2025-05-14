; ===========================================================================
; ----------------------------------------------------------------------------
; Object 01 - webtv
; ----------------------------------------------------------------------------
; Sprite_19F50: Object_webtv:
Obj4C:
	; a0=character
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	Obj4C_Normal			; if not, branch
	jmp	(DebugMode).l
; ---------------------------------------------------------------------------
; loc_19F5C:
Obj4C_Normal:
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	Obj4C_Index(pc,d0.w),d1
	jmp	Obj4C_Index(pc,d1.w)
; ===========================================================================
; off_19F6A: Obj4C_States:
Obj4C_Index:	offsetTable
		offsetTableEntry.w Obj4C_Init		;  0
		offsetTableEntry.w Obj4C_Control	;  2
		offsetTableEntry.w Obj4C_Hurt		;  4
		offsetTableEntry.w Obj4C_Dead		;  6
		offsetTableEntry.w Obj4C_Gone		;  8
		offsetTableEntry.w Obj4C_Respawning	; $A
; ===========================================================================
; loc_19F76: Obj_01_Sub_0: Obj4C_Main:
Obj4C_Init:
	addq.b	#2,routine(a0)	; => Obj4C_Control
	move.b	#$13,y_radius(a0) ; this sets webtv's collision height (2*pixels)
	move.b	#9,x_radius(a0)
	move.l	#MapUnc_webtv,mappings(a0)
	move.b	#2,priority(a0)
	move.b	#$18,width_pixels(a0)
	move.b	#4,render_flags(a0)
	move.w	#$600,(webtv_top_speed).w	; set webtv's top speed
	move.w	#$C,(webtv_acceleration).w	; set webtv's acceleration
	move.w	#$80,(webtv_deceleration).w	; set webtv's deceleration
	tst.b	(Last_star_pole_hit).w
	bne.s	Obj4C_Init_Continued
	; only happens when not starting at a checkpoint:
	move.w	#make_art_tile(ArtTile_ArtUnc_webtv,0,0),art_tile(a0)
	bsr.w	Adjust2PArtPointer
	move.b	#$C,top_solid_bit(a0)
	move.b	#$D,lrb_solid_bit(a0)
	move.w	x_pos(a0),(Saved_x_pos).w
	move.w	y_pos(a0),(Saved_y_pos).w
	move.w	art_tile(a0),(Saved_art_tile).w
	move.w	top_solid_bit(a0),(Saved_Solid_bits).w

Obj4C_Init_Continued:
	move.b	#0,flips_remaining(a0)
	move.b	#4,flip_speed(a0)
	move.b	#0,(Super_webtv_flag).w
	move.b	#30,air_left(a0)
	subi.w	#$20,x_pos(a0)
	addi_.w	#4,y_pos(a0)
	move.w	#0,(webtv_Pos_Record_Index).w

	move.w	#$3F,d2
-	bsr.w	webtv_RecordPos
	subq.w	#4,a1
	move.l	#0,(a1)
	dbf	d2,-

	addi.w	#$20,x_pos(a0)
	subi_.w	#4,y_pos(a0)

; ---------------------------------------------------------------------------
; Normal state for webtv
; ---------------------------------------------------------------------------
; loc_1A030: Obj_01_Sub_2:
Obj4C_Control:
	tst.w	(Debug_mode_flag).w	; is debug cheat enabled?
	beq.s	+			; if not, branch
	btst	#button_B,(Ctrl_1_Press).w	; is button B pressed?
	beq.s	+			; if not, branch
	move.w	#1,(Debug_placement_mode).w	; change webtv into a ring/item
	clr.b	(Control_Locked).w		; unlock control
	rts
; -----------------------------------------------------------------------
+	tst.b	(Control_Locked).w	; are controls locked?
	bne.s	+			; if yes, branch
	move.w	(Ctrl_1).w,(Ctrl_1_Logical).w	; copy new held buttons, to enable joypad control
+
	btst	#0,obj_control(a0)	; is webtv interacting with another object that holds him in place or controls his movement somehow?
	bne.s	+			; if yes, branch to skip webtv's control
	moveq	#0,d0
	move.b	status(a0),d0
	andi.w	#6,d0	; %0000 %0110
	move.w	Obj4C_Modes(pc,d0.w),d1
	jsr	Obj4C_Modes(pc,d1.w)	; run webtv's movement control code
+
	cmpi.w	#-$100,(Camera_Min_Y_pos).w	; is vertical wrapping enabled?
	bne.s	+				; if not, branch
	andi.w	#$7FF,y_pos(a0) 		; perform wrapping of webtv's y position
+
	bsr.s	webtv_Display
	bsr.w	webtv_Super
	bsr.w	webtv_RecordPos
	bsr.w	webtv_Water
	move.b	(Primary_Angle).w,next_tilt(a0)
	move.b	(Secondary_Angle).w,tilt(a0)
	tst.b	(WindTunnel_flag).w
	beq.s	+
	tst.b	anim(a0)
	bne.s	+
	move.b	prev_anim(a0),anim(a0)
+
	bsr.w	webtv_Animate
	tst.b	obj_control(a0)
	bmi.s	+
	jsr	(TouchResponse).l
+
	bra.w	LoadwebtvDynPLC

; ===========================================================================
; secondary states under state Obj4C_Control
; off_1A0BE:
Obj4C_Modes:	offsetTable
		offsetTableEntry.w Obj4C_MdNormal_Checks	; 0 - not airborne or rolling
		offsetTableEntry.w Obj4C_MdAir			; 2 - airborne
		offsetTableEntry.w Obj4C_MdRoll			; 4 - rolling
		offsetTableEntry.w Obj4C_MdJump			; 6 - jumping
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A0C6:
webtv_Display:
	move.w	invulnerable_time(a0),d0
	beq.s	Obj4C_Display
	subq.w	#1,invulnerable_time(a0)
	lsr.w	#3,d0
	bcc.s	Obj4C_ChkInvin
; loc_1A0D4:
Obj4C_Display:
	jsr	(DisplaySprite).l
; loc_1A0DA:
Obj4C_ChkInvin:		; Checks if invincibility has expired and disables it if it has.
	btst	#status_sec_isInvincible,status_secondary(a0)
	beq.s	Obj4C_ChkShoes
	tst.w	invincibility_time(a0)
	beq.s	Obj4C_ChkShoes	; If there wasn't any time left, that means we're in Super webtv mode.
	subq.w	#1,invincibility_time(a0)
	bne.s	Obj4C_ChkShoes
	tst.b	(Current_Boss_ID).w	; Don't change music if in a boss fight
	bne.s	Obj4C_RmvInvin
	cmpi.b	#12,air_left(a0)	; Don't change music if drowning
	blo.s	Obj4C_RmvInvin
	move.w	(Level_Music).w,d0
	jsr	(PlayMusic).l
;loc_1A106:
Obj4C_RmvInvin:
	bclr	#status_sec_isInvincible,status_secondary(a0)
; loc_1A10C:
Obj4C_ChkShoes:		; Checks if Speed Shoes have expired and disables them if they have.
	btst	#status_sec_hasSpeedShoes,status_secondary(a0)
	beq.s	Obj4C_ExitChk
	tst.w	speedshoes_time(a0)
	beq.s	Obj4C_ExitChk
	subq.w	#1,speedshoes_time(a0)
	bne.s	Obj4C_ExitChk
	move.w	#$600,(webtv_top_speed).w
	move.w	#$C,(webtv_acceleration).w
	move.w	#$80,(webtv_deceleration).w
	tst.b	(Super_webtv_flag).w
	beq.s	Obj4C_RmvSpeed
	move.w	#$A00,(webtv_top_speed).w
	move.w	#$30,(webtv_acceleration).w
	move.w	#$100,(webtv_deceleration).w
; loc_1A14A:
Obj4C_RmvSpeed:
	bclr	#status_sec_hasSpeedShoes,status_secondary(a0)
	move.w	#MusID_SlowDown,d0	; Slow down tempo
	jmp	(PlayMusic).l
; ---------------------------------------------------------------------------
; return_1A15A:
Obj4C_ExitChk:
	rts
; End of subroutine webtv_Display

; ---------------------------------------------------------------------------
; Subroutine to record webtv's previous positions for invincibility stars
; and input/status flags for Tails' AI to follow
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A15C:
webtv_RecordPos:
	move.w	(webtv_Pos_Record_Index).w,d0
	lea	(webtv_Pos_Record_Buf).w,a1
	lea	(a1,d0.w),a1
	move.w	x_pos(a0),(a1)+
	move.w	y_pos(a0),(a1)+
	addq.b	#4,(webtv_Pos_Record_Index+1).w

	lea	(webtv_Stat_Record_Buf).w,a1
	lea	(a1,d0.w),a1
	move.w	(Ctrl_1_Logical).w,(a1)+
	move.w	status(a0),(a1)+

	rts
; End of subroutine webtv_RecordPos

; ---------------------------------------------------------------------------
; Subroutine for webtv when he's underwater
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

obj0a_character = objoff_3C

; loc_1A186:
webtv_Water:
	tst.b	(Water_flag).w	; does level have water?
	bne.s	Obj4C_InWater	; if yes, branch

return_1A18C:
	rts
; ---------------------------------------------------------------------------
; loc_1A18E:
Obj4C_InWater:
	move.w	(Water_Level_1).w,d0
	cmp.w	y_pos(a0),d0	; is webtv above the water?
	bge.s	Obj4C_OutWater	; if yes, branch

	bset	#6,status(a0)	; set underwater flag
	bne.s	return_1A18C	; if already underwater, branch

	movea.l	a0,a1
	bsr.w	ResumeMusic
	move.b	#ObjID_SmallBubbles,(webtv_BreathingBubbles+id).w ; load Obj0A (webtv's breathing bubbles) at $FFFFD080
	move.b	#$81,(webtv_BreathingBubbles+subtype).w
	move.l	a0,(webtv_BreathingBubbles+obj0a_character).w
	move.w	#$300,(webtv_top_speed).w
	move.w	#6,(webtv_acceleration).w
	move.w	#$40,(webtv_deceleration).w
	tst.b	(Super_webtv_flag).w
	beq.s	+
	move.w	#$500,(webtv_top_speed).w
	move.w	#$18,(webtv_acceleration).w
	move.w	#$80,(webtv_deceleration).w
+
	asr.w	x_vel(a0)
	asr.w	y_vel(a0)	; memory operands can only be shifted one bit at a time
	asr.w	y_vel(a0)
	beq.s	return_1A18C
	move.w	#(1<<8)|(0<<0),(webtv_Dust+anim).w	; splash animation
	move.w	#SndID_Splash,d0	; splash sound
	jmp	(PlaySound).l
; ---------------------------------------------------------------------------
; loc_1A1FE:
Obj4C_OutWater:
	bclr	#6,status(a0) ; unset underwater flag
	beq.s	return_1A18C ; if already above water, branch

	movea.l	a0,a1
	bsr.w	ResumeMusic
	move.w	#$600,(webtv_top_speed).w
	move.w	#$C,(webtv_acceleration).w
	move.w	#$80,(webtv_deceleration).w
	tst.b	(Super_webtv_flag).w
	beq.s	+
	move.w	#$A00,(webtv_top_speed).w
	move.w	#$30,(webtv_acceleration).w
	move.w	#$100,(webtv_deceleration).w
+
	cmpi.b	#4,routine(a0)	; is webtv falling back from getting hurt?
	beq.s	+		; if yes, branch
	asl	y_vel(a0)
+
	tst.w	y_vel(a0)
	beq.w	return_1A18C
	move.w	#(1<<8)|(0<<0),(webtv_Dust+anim).w	; splash animation
	movea.l	a0,a1
	bsr.w	ResumeMusic
	cmpi.w	#-$1000,y_vel(a0)
	bgt.s	+
	move.w	#-$1000,y_vel(a0)	; limit upward y velocity exiting the water
+
	move.w	#SndID_Splash,d0	; splash sound
	jmp	(PlaySound).l
; End of subroutine webtv_Water

; ===========================================================================
; ---------------------------------------------------------------------------
; Start of subroutine Obj4C_MdNormal
; Called if webtv is neither airborne nor rolling this frame
; ---------------------------------------------------------------------------
; loc_1A26E:
Obj4C_MdNormal_Checks:
	; If webtv has been waiting for a while, and is tapping his foot
	; impatiently, then make him blink once the player starts moving
	; again. Likewise, if he's been waiting for so long that he's laying
	; down, then make him play an animation of standing up.
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	bne.s	Obj4C_MdNormal
	cmpi.b	#AniIDWebAni_Blink,anim(a0)
	beq.s	return_1A2DE
	cmpi.b	#AniIDWebAni_GetUp,anim(a0)
	beq.s	return_1A2DE
	cmpi.b	#AniIDWebAni_Wait,anim(a0)
	bne.s	Obj4C_MdNormal
	cmpi.b	#$1E,anim_frame(a0)
	blo.s	Obj4C_MdNormal
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_up_mask|button_down_mask|button_left_mask|button_right_mask|button_B_mask|button_C_mask|button_A_mask,d0
	beq.s	return_1A2DE
	move.b	#AniIDWebAni_Blink,anim(a0)
	cmpi.b	#$AC,anim_frame(a0)
	blo.s	return_1A2DE
	move.b	#AniIDWebAni_GetUp,anim(a0)
	bra.s	return_1A2DE
; ---------------------------------------------------------------------------
; loc_1A2B8:
Obj4C_MdNormal:
	bsr.w	webtv_CheckSpindash
	bsr.w	webtv_Jump
	bsr.w	webtv_SlopeResist
	bsr.w	webtv_Move
	bsr.w	webtv_Roll
	bsr.w	webtv_LevelBound
	jsr	(ObjectMove).l
	bsr.w	AnglePos
	bsr.w	webtv_SlopeRepel

return_1A2DE:
	rts
; End of subroutine Obj4C_MdNormal
; ===========================================================================
; Start of subroutine Obj4C_MdAir
; Called if webtv is airborne, but not in a ball (thus, probably not jumping)
; loc_1A2E0: Obj4C_MdJump
Obj4C_MdAir:
	bsr.w	webtv_JumpHeight
	bsr.w	webtv_ChgJumpDir
	bsr.w	webtv_LevelBound
	jsr	(ObjectMoveAndFall).l
	btst	#6,status(a0)	; is webtv underwater?
	beq.s	+		; if not, branch
	subi.w	#$28,y_vel(a0)	; reduce gravity by $28 ($38-$28=$10)
+
	bsr.w	webtv_JumpAngle
	bsr.w	webtv_DoLevelCollision
	rts
; End of subroutine Obj4C_MdAir
; ===========================================================================
; Start of subroutine Obj4C_MdRoll
; Called if webtv is in a ball, but not airborne (thus, probably rolling)
; loc_1A30A:
Obj4C_MdRoll:
	tst.b	pinball_mode(a0)
	bne.s	+
	bsr.w	webtv_Jump
+
	bsr.w	webtv_RollRepel
	bsr.w	webtv_RollSpeed
	bsr.w	webtv_LevelBound
	jsr	(ObjectMove).l
	bsr.w	AnglePos
	bsr.w	webtv_SlopeRepel
	rts
; End of subroutine Obj4C_MdRoll
; ===========================================================================
; Start of subroutine Obj4C_MdJump
; Called if webtv is in a ball and airborne (he could be jumping but not necessarily)
; Notes: This is identical to Obj4C_MdAir, at least at this outer level.
;        Why they gave it a separate copy of the code, I don't know.
; loc_1A330: Obj4C_MdJump2:
Obj4C_MdJump:
	bsr.w	webtv_JumpHeight
	bsr.w	webtv_ChgJumpDir
	bsr.w	webtv_LevelBound
	jsr	(ObjectMoveAndFall).l
	btst	#6,status(a0)	; is webtv underwater?
	beq.s	+		; if not, branch
	subi.w	#$28,y_vel(a0)	; reduce gravity by $28 ($38-$28=$10)
+
	bsr.w	webtv_JumpAngle
	bsr.w	webtv_DoLevelCollision
	rts
; End of subroutine Obj4C_MdJump

; ---------------------------------------------------------------------------
; Subroutine to make webtv walk/run
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A35A:
webtv_Move:
	move.w	(webtv_top_speed).w,d6
	move.w	(webtv_acceleration).w,d5
	move.w	(webtv_deceleration).w,d4
    if status_sec_isSliding = 7
	tst.b	status_secondary(a0)
	bmi.w	Obj4C_Traction
    else
	btst	#status_sec_isSliding,status_secondary(a0)
	bne.w	Obj4C_Traction
    endif
	tst.w	move_lock(a0)
	bne.w	Obj4C_ResetScr
	btst	#button_left,(Ctrl_1_Held_Logical).w	; is left being pressed?
	beq.s	Obj4C_NotLeft			; if not, branch
	bsr.w	webtv_MoveLeft
; loc_1A382:
Obj4C_NotLeft:
	btst	#button_right,(Ctrl_1_Held_Logical).w	; is right being pressed?
	beq.s	Obj4C_NotRight			; if not, branch
	bsr.w	webtv_MoveRight
; loc_1A38E:
Obj4C_NotRight:
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0		; is webtv on a slope?
	bne.w	Obj4C_ResetScr	; if yes, branch
	tst.w	inertia(a0)	; is webtv moving?
	bne.w	Obj4C_ResetScr	; if yes, branch
	bclr	#5,status(a0)
	move.b	#AniIDWebAni_Wait,anim(a0)	; use "standing" animation
	btst	#3,status(a0)
	beq.w	webtv_Balance
	moveq	#0,d0
	move.b	interact(a0),d0
    if object_size=$40
	lsl.w	#object_size_bits,d0
    else
	mulu.w	#object_size,d0
    endif
	lea	(Object_RAM).w,a1 ; a1=character
	lea	(a1,d0.w),a1 ; a1=object
	tst.b	status(a1)
	bmi.w	webtv_Lookup
	moveq	#0,d1
	move.b	width_pixels(a1),d1
	move.w	d1,d2
	add.w	d2,d2
	subq.w	#2,d2
	add.w	x_pos(a0),d1
	sub.w	x_pos(a1),d1
	tst.b	(Super_webtv_flag).w
	bne.w	Superwebtv_Balance
	cmpi.w	#2,d1
	blt.s	webtv_BalanceOnObjLeft
	cmp.w	d2,d1
	bge.s	webtv_BalanceOnObjRight
	bra.w	webtv_Lookup
; ---------------------------------------------------------------------------
; loc_1A3FE:
Superwebtv_Balance:
	cmpi.w	#2,d1
	blt.w	Superwebtv_BalanceOnObjLeft
	cmp.w	d2,d1
	bge.w	Superwebtv_BalanceOnObjRight
	bra.w	webtv_Lookup
; ---------------------------------------------------------------------------
; balancing checks for when you're on the right edge of an object
; loc_1A410:
webtv_BalanceOnObjRight:
	btst	#0,status(a0)
	bne.s	+
	move.b	#AniIDWebAni_Balance,anim(a0)
	addq.w	#6,d2
	cmp.w	d2,d1
	blt.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance2,anim(a0)
	bra.w	Obj4C_ResetScr
	; on right edge of object but facing left:
+	move.b	#AniIDWebAni_Balance3,anim(a0)
	addq.w	#6,d2
	cmp.w	d2,d1
	blt.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance4,anim(a0)
	bclr	#0,status(a0)
	bra.w	Obj4C_ResetScr
; ---------------------------------------------------------------------------
; balancing checks for when you're on the left edge of an object
; loc_1A44E:
webtv_BalanceOnObjLeft:
	btst	#0,status(a0)
	beq.s	+
	move.b	#AniIDWebAni_Balance,anim(a0)
	cmpi.w	#-4,d1
	bge.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance2,anim(a0)
	bra.w	Obj4C_ResetScr
	; on left edge of object but facing right:
+	move.b	#AniIDWebAni_Balance3,anim(a0)
	cmpi.w	#-4,d1
	bge.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance4,anim(a0)
	bset	#0,status(a0)
	bra.w	Obj4C_ResetScr
; ---------------------------------------------------------------------------
; balancing checks for when you're on the edge of part of the level
; loc_1A48C:
webtv_Balance:
	jsr	(ChkFloorEdge).l
	cmpi.w	#$C,d1
	blt.w	webtv_Lookup
	tst.b	(Super_webtv_flag).w
	bne.w	Superwebtv_Balance2
	cmpi.b	#3,next_tilt(a0)
	bne.s	webtv_BalanceLeft
	btst	#0,status(a0)
	bne.s	+
	move.b	#AniIDWebAni_Balance,anim(a0)
	move.w	x_pos(a0),d3
	subq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance2,anim(a0)
	bra.w	Obj4C_ResetScr
	; on right edge but facing left:
+	move.b	#AniIDWebAni_Balance3,anim(a0)
	move.w	x_pos(a0),d3
	subq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance4,anim(a0)
	bclr	#0,status(a0)
	bra.w	Obj4C_ResetScr
; ---------------------------------------------------------------------------
webtv_BalanceLeft:
	cmpi.b	#3,tilt(a0)
	bne.s	webtv_Lookup
	btst	#0,status(a0)
	beq.s	+
	move.b	#AniIDWebAni_Balance,anim(a0)
	move.w	x_pos(a0),d3
	addq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance2,anim(a0)
	bra.w	Obj4C_ResetScr
	; on left edge but facing right:
+	move.b	#AniIDWebAni_Balance3,anim(a0)
	move.w	x_pos(a0),d3
	addq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Obj4C_ResetScr
	move.b	#AniIDWebAni_Balance4,anim(a0)
	bset	#0,status(a0)
	bra.w	Obj4C_ResetScr
; ---------------------------------------------------------------------------
; loc_1A55E:
Superwebtv_Balance2:
	cmpi.b	#3,next_tilt(a0)
	bne.s	loc_1A56E

; loc_1A566:
Superwebtv_BalanceOnObjRight:
	bclr	#0,status(a0)
	bra.s	loc_1A57C
; ---------------------------------------------------------------------------
loc_1A56E:
	cmpi.b	#3,tilt(a0)
	bne.s	webtv_Lookup

; loc_1A576:
Superwebtv_BalanceOnObjLeft:
	bset	#0,status(a0)

loc_1A57C:
	move.b	#AniIDWebAni_Balance,anim(a0)
	bra.s	Obj4C_ResetScr
; ---------------------------------------------------------------------------
; loc_1A584:
webtv_Lookup:
	btst	#button_up,(Ctrl_1_Held_Logical).w	; is up being pressed?
	beq.s	webtv_Duck			; if not, branch
	move.b	#AniIDWebAni_LookUp,anim(a0)			; use "looking up" animation
	addq.w	#1,(webtv_Look_delay_counter).w
	cmpi.w	#$78,(webtv_Look_delay_counter).w
	blo.s	Obj4C_ResetScr_Part2
	move.w	#$78,(webtv_Look_delay_counter).w
	cmpi.w	#$C8,(Camera_Y_pos_bias).w
	beq.s	Obj4C_UpdateSpeedOnGround
	addq.w	#2,(Camera_Y_pos_bias).w
	bra.s	Obj4C_UpdateSpeedOnGround
; ---------------------------------------------------------------------------
; loc_1A5B2:
webtv_Duck:
	btst	#button_down,(Ctrl_1_Held_Logical).w	; is down being pressed?
	beq.s	Obj4C_ResetScr			; if not, branch
	move.b	#AniIDWebAni_Duck,anim(a0)			; use "ducking" animation
	addq.w	#1,(webtv_Look_delay_counter).w
	cmpi.w	#$78,(webtv_Look_delay_counter).w
	blo.s	Obj4C_ResetScr_Part2
	move.w	#$78,(webtv_Look_delay_counter).w
	cmpi.w	#8,(Camera_Y_pos_bias).w
	beq.s	Obj4C_UpdateSpeedOnGround
	subq.w	#2,(Camera_Y_pos_bias).w
	bra.s	Obj4C_UpdateSpeedOnGround

; ===========================================================================
; moves the screen back to its normal position after looking up or down
; loc_1A5E0:
Obj4C_ResetScr:
	move.w	#0,(webtv_Look_delay_counter).w
; loc_1A5E6:
Obj4C_ResetScr_Part2:
	cmpi.w	#(224/2)-16,(Camera_Y_pos_bias).w	; is screen in its default position?
	beq.s	Obj4C_UpdateSpeedOnGround	; if yes, branch.
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias).w	; or subtract 2

; ---------------------------------------------------------------------------
; updates webtv's speed on the ground
; ---------------------------------------------------------------------------
; sub_1A5F8:
Obj4C_UpdateSpeedOnGround:
	tst.b	(Super_webtv_flag).w
	beq.w	+
	move.w	#$C,d5
+
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_left_mask|button_right_mask,d0 ; is left/right pressed?
	bne.s	Obj4C_Traction	; if yes, branch
	move.w	inertia(a0),d0
	beq.s	Obj4C_Traction
	bmi.s	Obj4C_SettleLeft

; slow down when facing right and not pressing a direction
; Obj4C_SettleRight:
	sub.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)
	bra.s	Obj4C_Traction
; ---------------------------------------------------------------------------
; slow down when facing left and not pressing a direction
; loc_1A624:
Obj4C_SettleLeft:
	add.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)

; increase or decrease speed on the ground
; loc_1A630:
Obj4C_Traction:
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	move.w	d1,x_vel(a0)
	muls.w	inertia(a0),d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)

; stops webtv from running through walls that meet the ground
; loc_1A64E:
Obj4C_CheckWallsOnGround:
	move.b	angle(a0),d0
	addi.b	#$40,d0
	bmi.s	return_1A6BE
	move.b	#$40,d1			; Rotate 90 degrees clockwise
	tst.w	inertia(a0)		; Check inertia
	beq.s	return_1A6BE	; If not moving, don't do anything
	bmi.s	+				; If negative, branch
	neg.w	d1				; Otherwise, we want to rotate counterclockwise
+
	move.b	angle(a0),d0
	add.b	d1,d0
	move.w	d0,-(sp)
	bsr.w	CalcRoomInFront
	move.w	(sp)+,d0
	tst.w	d1
	bpl.s	return_1A6BE
	asl.w	#8,d1
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	loc_1A6BA
	cmpi.b	#$40,d0
	beq.s	loc_1A6A8
	cmpi.b	#$80,d0
	beq.s	loc_1A6A2
	add.w	d1,x_vel(a0)
	bset	#5,status(a0)
	move.w	#0,inertia(a0)
	rts
; ---------------------------------------------------------------------------
loc_1A6A2:
	sub.w	d1,y_vel(a0)
	rts
; ---------------------------------------------------------------------------
loc_1A6A8:
	sub.w	d1,x_vel(a0)
	bset	#5,status(a0)
	move.w	#0,inertia(a0)
	rts
; ---------------------------------------------------------------------------
loc_1A6BA:
	add.w	d1,y_vel(a0)

return_1A6BE:
	rts
; End of subroutine webtv_Move


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A6C0:
webtv_MoveLeft:
	move.w	inertia(a0),d0
	beq.s	+
	bpl.s	webtv_TurnLeft ; if webtv is already moving to the right, branch
+
	bset	#0,status(a0)
	bne.s	+
	bclr	#5,status(a0)
	move.b	#AniIDWebAni_Run,prev_anim(a0)	; force walking animation to restart if it's already in-progress
+
	sub.w	d5,d0	; add acceleration to the left
	move.w	d6,d1
	neg.w	d1
	cmp.w	d1,d0	; compare new speed with top speed
	bgt.s	+	; if new speed is less than the maximum, branch
	add.w	d5,d0	; remove this frame's acceleration change
	cmp.w	d1,d0	; compare speed with top speed
	ble.s	+	; if speed was already greater than the maximum, branch
	move.w	d1,d0	; limit speed on ground going left
+
	move.w	d0,inertia(a0)
	move.b	#AniIDWebAni_Walk,anim(a0)	; use walking animation
	rts
; ---------------------------------------------------------------------------
; loc_1A6FA:
webtv_TurnLeft:
	sub.w	d4,d0
	bcc.s	+
	move.w	#-$80,d0
+
	move.w	d0,inertia(a0)
    if fixBugs
	move.b	angle(a0),d1
	addi.b	#$20,d1
	andi.b	#$C0,d1
    else
	; These three instructions partially overwrite the inertia value in
	; 'd0'! This causes the character to trigger their skidding
	; animation at different speeds depending on whether they're going
	; right or left. To fix this, make these instructions use 'd1'
	; instead.
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
    endif
	bne.s	return_1A744
	cmpi.w	#$400,d0
	blt.s	return_1A744
	move.b	#AniIDWebAni_Stop,anim(a0)	; use "stopping" animation
	bclr	#0,status(a0)
	move.w	#SndID_Skidding,d0
	jsr	(PlaySound).l
	cmpi.b	#12,air_left(a0)
	blo.s	return_1A744	; if he's drowning, branch to not make dust
	move.b	#6,(webtv_Dust+routine).w
	move.b	#$15,(webtv_Dust+mapping_frame).w

return_1A744:
	rts
; End of subroutine webtv_MoveLeft


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A746:
webtv_MoveRight:
	move.w	inertia(a0),d0
	bmi.s	webtv_TurnRight	; if webtv is already moving to the left, branch
	bclr	#0,status(a0)
	beq.s	+
	bclr	#5,status(a0)
	move.b	#AniIDWebAni_Run,prev_anim(a0)	; force walking animation to restart if it's already in-progress
+
	add.w	d5,d0	; add acceleration to the right
	cmp.w	d6,d0	; compare new speed with top speed
	blt.s	+	; if new speed is less than the maximum, branch
	sub.w	d5,d0	; remove this frame's acceleration change
	cmp.w	d6,d0	; compare speed with top speed
	bge.s	+	; if speed was already greater than the maximum, branch
	move.w	d6,d0	; limit speed on ground going right
+
	move.w	d0,inertia(a0)
	move.b	#AniIDWebAni_Walk,anim(a0)	; use walking animation
	rts
; ---------------------------------------------------------------------------
; loc_1A77A:
webtv_TurnRight:
	add.w	d4,d0
	bcc.s	+
	move.w	#$80,d0
+
	move.w	d0,inertia(a0)
    if fixBugs
	move.b	angle(a0),d1
	addi.b	#$20,d1
	andi.b	#$C0,d1
    else
	; These three instructions partially overwrite the inertia value in
	; 'd0'! This causes the character to trigger their skidding
	; animation at different speeds depending on whether they're going
	; right or left. To fix this, make these instructions use 'd1'
	; instead.
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
    endif
	bne.s	return_1A7C4
	cmpi.w	#-$400,d0
	bgt.s	return_1A7C4
	move.b	#AniIDWebAni_Stop,anim(a0)	; use "stopping" animation
	bset	#0,status(a0)
	move.w	#SndID_Skidding,d0	; use "stopping" sound
	jsr	(PlaySound).l
	cmpi.b	#12,air_left(a0)
	blo.s	return_1A7C4	; if he's drowning, branch to not make dust
	move.b	#6,(webtv_Dust+routine).w
	move.b	#$15,(webtv_Dust+mapping_frame).w

return_1A7C4:
	rts
; End of subroutine webtv_MoveRight

; ---------------------------------------------------------------------------
; Subroutine to change webtv's speed as he rolls
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A7C6:
webtv_RollSpeed:
	move.w	(webtv_top_speed).w,d6
	asl.w	#1,d6
	move.w	(webtv_acceleration).w,d5
	asr.w	#1,d5	; natural roll deceleration = 1/2 normal acceleration
	move.w	#$20,d4	; controlled roll deceleration... interestingly,
			; this should be webtv_deceleration/4 according to Tails_RollSpeed,
			; which means webtv is much better than Tails at slowing down his rolling when he's underwater
    if status_sec_isSliding = 7
	tst.b	status_secondary(a0)
	bmi.w	Obj4C_Roll_ResetScr
    else
	btst	#status_sec_isSliding,status_secondary(a0)
	bne.w	Obj4C_Roll_ResetScr
    endif
	tst.w	move_lock(a0)
	bne.s	webtv_ApplyRollSpeed
	btst	#button_left,(Ctrl_1_Held_Logical).w	; is left being pressed?
	beq.s	+				; if not, branch
	bsr.w	webtv_RollLeft
+
	btst	#button_right,(Ctrl_1_Held_Logical).w	; is right being pressed?
	beq.s	webtv_ApplyRollSpeed		; if not, branch
	bsr.w	webtv_RollRight

; loc_1A7FC:
webtv_ApplyRollSpeed:
	move.w	inertia(a0),d0
	beq.s	webtv_CheckRollStop
	bmi.s	webtv_ApplyRollSpeedLeft

; webtv_ApplyRollSpeedRight:
	sub.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)
	bra.s	webtv_CheckRollStop
; ---------------------------------------------------------------------------
; loc_1A812:
webtv_ApplyRollSpeedLeft:
	add.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)

; loc_1A81E:
webtv_CheckRollStop:
	tst.w	inertia(a0)
	bne.s	Obj4C_Roll_ResetScr
	tst.b	pinball_mode(a0) ; note: the spindash flag has a different meaning when webtv's already rolling -- it's used to mean he's not allowed to stop rolling
	bne.s	webtv_KeepRolling
	bclr	#2,status(a0)
	move.b	#$13,y_radius(a0)
	move.b	#9,x_radius(a0)
	move.b	#AniIDWebAni_Wait,anim(a0)
	subq.w	#5,y_pos(a0)
	bra.s	Obj4C_Roll_ResetScr

; ---------------------------------------------------------------------------
; magically gives webtv an extra push if he's going to stop rolling where it's not allowed
; (such as in an S-curve in HTZ or a stopper chamber in CNZ)
; loc_1A848:
webtv_KeepRolling:
	move.w	#$400,inertia(a0)
	btst	#0,status(a0)
	beq.s	Obj4C_Roll_ResetScr
	neg.w	inertia(a0)

; resets the screen to normal while rolling, like Obj4C_ResetScr
; loc_1A85A:
Obj4C_Roll_ResetScr:
	cmpi.w	#(224/2)-16,(Camera_Y_pos_bias).w	; is screen in its default position?
	beq.s	webtv_SetRollSpeeds		; if yes, branch
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias).w	; or subtract 2

; loc_1A86C:
webtv_SetRollSpeeds:
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)	; set y velocity based on $14 and angle
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	cmpi.w	#$1000,d1
	ble.s	+
	move.w	#$1000,d1	; limit webtv's speed rolling right
+
	cmpi.w	#-$1000,d1
	bge.s	+
	move.w	#-$1000,d1	; limit webtv's speed rolling left
+
	move.w	d1,x_vel(a0)	; set x velocity based on $14 and angle
	bra.w	Obj4C_CheckWallsOnGround
; End of function webtv_RollSpeed


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1A8A2:
webtv_RollLeft:
	move.w	inertia(a0),d0
	beq.s	+
	bpl.s	webtv_BrakeRollingRight
+
	bset	#0,status(a0)
	move.b	#AniIDWebAni_Roll,anim(a0)	; use "rolling" animation
	rts
; ---------------------------------------------------------------------------
; loc_1A8B8:
webtv_BrakeRollingRight:
	sub.w	d4,d0	; reduce rightward rolling speed
	bcc.s	+
	move.w	#-$80,d0
+
	move.w	d0,inertia(a0)
	rts
; End of function webtv_RollLeft


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1A8C6:
webtv_RollRight:
	move.w	inertia(a0),d0
	bmi.s	webtv_BrakeRollingLeft
	bclr	#0,status(a0)
	move.b	#AniIDWebAni_Roll,anim(a0)	; use "rolling" animation
	rts
; ---------------------------------------------------------------------------
; loc_1A8DA:
webtv_BrakeRollingLeft:
	add.w	d4,d0	; reduce leftward rolling speed
	bcc.s	+
	move.w	#$80,d0
+
	move.w	d0,inertia(a0)
	rts
; End of subroutine webtv_RollRight


; ---------------------------------------------------------------------------
; Subroutine for moving webtv left or right when he's in the air
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A8E8:
webtv_ChgJumpDir:
	move.w	(webtv_top_speed).w,d6
	move.w	(webtv_acceleration).w,d5
	asl.w	#1,d5
	btst	#4,status(a0)		; did webtv jump from rolling?
	bne.s	Obj4C_Jump_ResetScr	; if yes, branch to skip midair control
	move.w	x_vel(a0),d0
	btst	#button_left,(Ctrl_1_Held_Logical).w
	beq.s	+	; if not holding left, branch

	bset	#0,status(a0)
	sub.w	d5,d0	; add acceleration to the left
	move.w	d6,d1
	neg.w	d1
	cmp.w	d1,d0	; compare new speed with top speed
	bgt.s	+	; if new speed is less than the maximum, branch
	move.w	d1,d0	; limit speed in air going left, even if webtv was already going faster (speed limit/cap)
+
	btst	#button_right,(Ctrl_1_Held_Logical).w
	beq.s	+	; if not holding right, branch

	bclr	#0,status(a0)
	add.w	d5,d0	; accelerate right in the air
	cmp.w	d6,d0	; compare new speed with top speed
	blt.s	+	; if new speed is less than the maximum, branch
	move.w	d6,d0	; limit speed in air going right, even if webtv was already going faster (speed limit/cap)
; Obj4C_JumpMove:
+	move.w	d0,x_vel(a0)

; loc_1A932: Obj4C_ResetScr2:
Obj4C_Jump_ResetScr:
	cmpi.w	#(224/2)-16,(Camera_Y_pos_bias).w	; is screen in its default position?
	beq.s	webtv_JumpPeakDecelerate	; if yes, branch
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias).w	; or subtract 2

; loc_1A944:
webtv_JumpPeakDecelerate:
	cmpi.w	#-$400,y_vel(a0)	; is webtv moving faster than -$400 upwards?
	blo.s	return_1A972		; if yes, return
	move.w	x_vel(a0),d0
	move.w	d0,d1
	asr.w	#5,d1		; d1 = x_velocity / 32
	beq.s	return_1A972	; return if d1 is 0
	bmi.s	webtv_JumpPeakDecelerateLeft	; branch if moving left

; webtv_JumpPeakDecelerateRight:
	sub.w	d1,d0	; reduce x velocity by d1
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,x_vel(a0)
	rts
;-------------------------------------------------------------
; loc_1A966:
webtv_JumpPeakDecelerateLeft:
	sub.w	d1,d0	; reduce x velocity by d1
	bcs.s	+
	move.w	#0,d0
+
	move.w	d0,x_vel(a0)

return_1A972:
	rts
; End of subroutine webtv_ChgJumpDir
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to prevent webtv from leaving the boundaries of a level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A974:
webtv_LevelBound:
	move.l	x_pos(a0),d1
	move.w	x_vel(a0),d0
	ext.l	d0
	asl.l	#8,d0
	add.l	d0,d1
	swap	d1
	move.w	(Camera_Min_X_pos).w,d0
	addi.w	#$10,d0
	cmp.w	d1,d0			; has webtv touched the left boundary?
	bhi.s	webtv_Boundary_Sides	; if yes, branch
	move.w	(Camera_Max_X_pos).w,d0
	addi.w	#320-24,d0		; screen width - webtv's width_pixels
	tst.b	(Current_Boss_ID).w
	bne.s	+
	addi.w	#$40,d0
+
	cmp.w	d1,d0			; has webtv touched the right boundary?
	bls.s	webtv_Boundary_Sides	; if yes, branch

; loc_1A9A6:
webtv_Boundary_CheckBottom:
	move.w	(Camera_Max_Y_pos).w,d0
    if fixBugs
	; The original code does not consider that the camera boundary
	; may be in the middle of lowering itself, which is why going
	; down the S-tunnel in Green Hill Zone Act 1 fast enough can
	; kill webtv.
	move.w	(Camera_Max_Y_pos_target).w,d1
	cmp.w	d0,d1
	blo.s	.skip
	move.w	d1,d0
.skip:
    endif
	addi.w	#224,d0
	cmp.w	y_pos(a0),d0		; has webtv touched the bottom boundary?
	blt.s	webtv_Boundary_Bottom	; if yes, branch
	rts
; ---------------------------------------------------------------------------
webtv_Boundary_Bottom: ;;
    if fixBugs
	; a2 needs to be set here, otherwise KillCharacter
	; will access a dangling pointer!
	movea.l	a0,a2
    endif
	jmpto	JmpTo_KillCharacter
; ===========================================================================

; loc_1A9BA:
webtv_Boundary_Sides:
	move.w	d0,x_pos(a0)
	move.w	#0,2+x_pos(a0) ; subpixel x
	move.w	#0,x_vel(a0)
	move.w	#0,inertia(a0)
	bra.s	webtv_Boundary_CheckBottom
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine allowing webtv to start rolling when he's moving
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A9D2:
webtv_Roll:
    if status_sec_isSliding = 7
	tst.b	status_secondary(a0)
	bmi.s	Obj4C_NoRoll
    else
	btst	#status_sec_isSliding,status_secondary(a0)
	bne.s	Obj4C_NoRoll
    endif
	mvabs.w	inertia(a0),d0
	cmpi.w	#$80,d0		; is webtv moving at $80 speed or faster?
	blo.s	Obj4C_NoRoll	; if not, branch
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_left_mask|button_right_mask,d0 ; is left/right being pressed?
	bne.s	Obj4C_NoRoll	; if yes, branch
	btst	#button_down,(Ctrl_1_Held_Logical).w ; is down being pressed?
	bne.s	Obj4C_ChkRoll			; if yes, branch
; return_1A9F8:
Obj4C_NoRoll:
	rts

; ---------------------------------------------------------------------------
; loc_1A9FA:
Obj4C_ChkRoll:
	btst	#2,status(a0)	; is webtv already rolling?
	beq.s	Obj4C_DoRoll	; if not, branch
	rts

; ---------------------------------------------------------------------------
; loc_1AA04:
Obj4C_DoRoll:
	bset	#2,status(a0)
	move.b	#$E,y_radius(a0)
	move.b	#7,x_radius(a0)
	move.b	#AniIDWebAni_Roll,anim(a0)	; use "rolling" animation
	addq.w	#5,y_pos(a0)
	move.w	#SndID_Roll,d0
	jsr	(PlaySound).l	; play rolling sound
	tst.w	inertia(a0)
	bne.s	return_1AA36
	move.w	#$200,inertia(a0)

return_1AA36:
	rts
; End of function webtv_Roll


; ---------------------------------------------------------------------------
; Subroutine allowing webtv to jump
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AA38:
webtv_Jump:
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0 ; is A, B or C pressed?
	beq.w	return_1AAE6	; if not, return
	moveq	#0,d0
	move.b	angle(a0),d0
	addi.b	#$80,d0
	bsr.w	CalcRoomOverHead
	cmpi.w	#6,d1			; does webtv have enough room to jump?
	blt.w	return_1AAE6		; if not, branch
	move.w	#$680,d2
	tst.b	(Super_webtv_flag).w
	beq.s	+
	move.w	#$800,d2	; set higher jump speed if super
+
	btst	#6,status(a0)	; Test if underwater
	beq.s	+
	move.w	#$380,d2	; set lower jump speed if underwater
+
	moveq	#0,d0
	move.b	angle(a0),d0
	subi.b	#$40,d0
	jsr	(CalcSine).l
	muls.w	d2,d1
	asr.l	#8,d1
	add.w	d1,x_vel(a0)	; make webtv jump (in X... this adds nothing on level ground)
	muls.w	d2,d0
	asr.l	#8,d0
	add.w	d0,y_vel(a0)	; make webtv jump (in Y)
	bset	#1,status(a0)
	bclr	#5,status(a0)
	addq.l	#4,sp
	move.b	#1,jumping(a0)
	clr.b	stick_to_convex(a0)
	move.w	#SndID_Jump,d0
	jsr	(PlaySound).l	; play jumping sound
	move.b	#$13,y_radius(a0)
	move.b	#9,x_radius(a0)
	btst	#2,status(a0)
	bne.s	webtv_RollJump
	move.b	#$E,y_radius(a0)
	move.b	#7,x_radius(a0)
	move.b	#AniIDWebAni_Roll,anim(a0)	; use "jumping" animation
	bset	#2,status(a0)
	addq.w	#5,y_pos(a0)

return_1AAE6:
	rts
; ---------------------------------------------------------------------------
; loc_1AAE8:
webtv_RollJump:
	bset	#4,status(a0)	; set the rolling+jumping flag
	rts
; End of function webtv_Jump


; ---------------------------------------------------------------------------
; Subroutine letting webtv control the height of the jump
; when the jump button is released
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; ===========================================================================
; loc_1AAF0:
webtv_JumpHeight:
	tst.b	jumping(a0)	; is webtv jumping?
	beq.s	webtv_UpVelCap	; if not, branch

	move.w	#-$400,d1
	btst	#6,status(a0)	; is webtv underwater?
	beq.s	+		; if not, branch
	move.w	#-$200,d1
+
	cmp.w	y_vel(a0),d1	; is webtv going up faster than d1?
	ble.s	+		; if not, branch
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0 ; is a jump button pressed?
	bne.s	+		; if yes, branch
	move.w	d1,y_vel(a0)	; immediately reduce webtv's upward speed to d1
+
	tst.b	y_vel(a0)		; is webtv exactly at the height of his jump?
	beq.s	webtv_CheckGoSuper	; if yes, test for turning into Super webtv
	rts
; ---------------------------------------------------------------------------
; loc_1AB22:
webtv_UpVelCap:
	tst.b	pinball_mode(a0)	; is webtv charging a spindash or in a rolling-only area?
	bne.s	return_1AB36		; if yes, return
	cmpi.w	#-$FC0,y_vel(a0)	; is webtv moving up really fast?
	bge.s	return_1AB36		; if not, return
	move.w	#-$FC0,y_vel(a0)	; cap upward speed

return_1AB36:
	rts
; End of subroutine webtv_JumpHeight

; ---------------------------------------------------------------------------
; Subroutine called at the peak of a jump that transforms webtv into Super webtv
; if he has enough rings and emeralds
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AB38: test_set_SS:
webtv_CheckGoSuper:
	tst.b	(Super_webtv_flag).w	; is webtv already Super?
	bne.s	return_1ABA4		; if yes, branch
	cmpi.b	#7,(Emerald_count).w	; does webtv have exactly 7 emeralds?
	bne.s	return_1ABA4		; if not, branch
	cmpi.w	#50,(Ring_count).w	; does webtv have at least 50 rings?
	blo.s	return_1ABA4		; if not, branch
    if gameRevision=2
	; fixes a bug where the player can get stuck if transforming at the end of a level
	tst.b	(Update_HUD_timer).w	; has webtv reached the end of the act?
	beq.s	return_1ABA4		; if yes, branch
    endif

    if fixBugs
	; If webtv was executing a roll-jump when he turned Super, then this
	; will remove him from that state. The original code forgot to do
	; this.
	andi.b	#~((1<<2)|(1<<4)),status(a0)	; Clear bits 2 and 4
	move.b	#$13,y_radius(a0)
	move.b	#9,x_radius(a0)
    endif
	move.b	#1,(Super_webtv_palette).w
	move.b	#$F,(Palette_timer).w
	move.b	#1,(Super_webtv_flag).w
	move.b	#$81,obj_control(a0)
	move.b	#AniIDSupWebAni_Transform,anim(a0)			; use transformation animation
	move.b	#ObjID_SuperwebtvStars,(SuperwebtvStars+id).w ; load Obj7E (Super webtv stars object) at $FFFFD040
	move.w	#$A00,(webtv_top_speed).w
	move.w	#$30,(webtv_acceleration).w
	move.w	#$100,(webtv_deceleration).w
	move.w	#0,invincibility_time(a0)
	bset	#status_sec_isInvincible,status_secondary(a0)	; make webtv invincible
	move.w	#SndID_SuperTransform,d0
	jsr	(PlaySound).l	; Play transformation sound effect.
	move.w	#MusID_Superwebtv,d0
	jmp	(PlayMusic).l	; load the Super webtv song and return

; ---------------------------------------------------------------------------
return_1ABA4:
	rts
; End of subroutine webtv_CheckGoSuper


; ---------------------------------------------------------------------------
; Subroutine doing the extra logic for Super webtv
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1ABA6:
webtv_Super:
	tst.b	(Super_webtv_flag).w	; Ignore all this code if not Super webtv
	beq.w	return_1AC3C
	tst.b	(Update_HUD_timer).w
	beq.s	webtv_RevertToNormal ; ?
	subq.w	#1,(Super_webtv_frame_count).w
	bpl.w	return_1AC3C
	move.w	#60,(Super_webtv_frame_count).w	; Reset frame counter to 60
	tst.w	(Ring_count).w
	beq.s	webtv_RevertToNormal
	ori.b	#1,(Update_HUD_rings).w
	cmpi.w	#1,(Ring_count).w
	beq.s	+
	cmpi.w	#10,(Ring_count).w
	beq.s	+
	cmpi.w	#100,(Ring_count).w
	bne.s	++
+
	ori.b	#$80,(Update_HUD_rings).w
+
	subq.w	#1,(Ring_count).w
	bne.s	return_1AC3C
; loc_1ABF2:
webtv_RevertToNormal:
	move.b	#2,(Super_webtv_palette).w	; Remove rotating palette
	move.w	#$28,(Palette_frame).w
	move.b	#0,(Super_webtv_flag).w
	move.b	#AniIDWebAni_Run,prev_anim(a0)	; Force webtv's animation to restart
	move.w	#1,invincibility_time(a0)	; Remove invincibility
	move.w	#$600,(webtv_top_speed).w
	move.w	#$C,(webtv_acceleration).w
	move.w	#$80,(webtv_deceleration).w
	btst	#6,status(a0)	; Check if underwater, return if not
	beq.s	return_1AC3C
	move.w	#$300,(webtv_top_speed).w
	move.w	#6,(webtv_acceleration).w
	move.w	#$40,(webtv_deceleration).w

return_1AC3C:
	rts
; End of subroutine webtv_Super

; ---------------------------------------------------------------------------
; Subroutine to check for starting to charge a spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AC3E:
webtv_CheckSpindash:
	tst.b	spindash_flag(a0)
	bne.s	webtv_UpdateSpindash
	cmpi.b	#AniIDWebAni_Duck,anim(a0)
	bne.s	return_1AC8C
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	return_1AC8C
	move.b	#AniIDWebAni_Spindash,anim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	addq.l	#4,sp
	move.b	#1,spindash_flag(a0)
	move.w	#0,spindash_counter(a0)
	cmpi.b	#12,air_left(a0)	; if he's drowning, branch to not make dust
	blo.s	+
	move.b	#2,(webtv_Dust+anim).w
+
	bsr.w	webtv_LevelBound
	bsr.w	AnglePos

return_1AC8C:
	rts
; End of subroutine webtv_CheckSpindash


; ---------------------------------------------------------------------------
; Subrouting to update an already-charging spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AC8E:
webtv_UpdateSpindash:
	move.b	(Ctrl_1_Held_Logical).w,d0
	btst	#button_down,d0
	bne.w	webtv_ChargingSpindash

	; unleash the charged spindash and start rolling quickly:
	move.b	#$E,y_radius(a0)
	move.b	#7,x_radius(a0)
	move.b	#AniIDWebAni_Roll,anim(a0)
	addq.w	#5,y_pos(a0)	; add the difference between webtv's rolling and standing heights
	move.b	#0,spindash_flag(a0)
	moveq	#0,d0
	move.b	spindash_counter(a0),d0
	add.w	d0,d0
	move.w	SpindashSpeeds(pc,d0.w),inertia(a0)
	tst.b	(Super_webtv_flag).w
	beq.s	+
	move.w	SpindashSpeedsSuper(pc,d0.w),inertia(a0)
+
	; Determine how long to lag the camera for.
	; Notably, the faster webtv goes, the less the camera lags.
	; This is seemingly to prevent webtv from going off-screen.
	move.w	inertia(a0),d0
	subi.w	#$800,d0 ; $800 is the lowest spin dash speed
    if fixBugs
	; To fix a bug in 'ScrollHoriz', we need an extra variable, so this
	; code has been modified to make the delay value only a single byte.
	; The lower byte has been repurposed to hold a copy of the position
	; array index at the time that the spin dash was released.
	; This is used by the fixed 'ScrollHoriz'.
	lsr.w	#7,d0
	neg.w	d0
	addi.w	#$20,d0
	move.b	d0,(Horiz_scroll_delay_val).w
	; Back up the position array index for later.
	move.b	(webtv_Pos_Record_Index+1).w,(Horiz_scroll_delay_val+1).w
    else
	add.w	d0,d0
	andi.w	#$1F00,d0 ; This line is not necessary, as none of the removed bits are ever set in the first place
	neg.w	d0
	addi.w	#$2000,d0
	move.w	d0,(Horiz_scroll_delay_val).w
    endif

	btst	#0,status(a0)
	beq.s	+
	neg.w	inertia(a0)
+
	bset	#2,status(a0)
	move.b	#0,(webtv_Dust+anim).w
	move.w	#SndID_SpindashRelease,d0	; spindash zoom sound
	jsr	(PlaySound).l
	bra.s	Obj4C_Spindash_ResetScr
; ===========================================================================
; word_1AD0C:
SpindashSpeeds:
	dc.w  $800	; 0
	dc.w  $880	; 1
	dc.w  $900	; 2
	dc.w  $980	; 3
	dc.w  $A00	; 4
	dc.w  $A80	; 5
	dc.w  $B00	; 6
	dc.w  $B80	; 7
	dc.w  $C00	; 8
; word_1AD1E:
SpindashSpeedsSuper:
	dc.w  $B00	; 0
	dc.w  $B80	; 1
	dc.w  $C00	; 2
	dc.w  $C80	; 3
	dc.w  $D00	; 4
	dc.w  $D80	; 5
	dc.w  $E00	; 6
	dc.w  $E80	; 7
	dc.w  $F00	; 8
; ===========================================================================
; loc_1AD30:
webtv_ChargingSpindash:			; If still charging the dash...
	tst.w	spindash_counter(a0)
	beq.s	+
	move.w	spindash_counter(a0),d0
	lsr.w	#5,d0
	sub.w	d0,spindash_counter(a0)
	bcc.s	+
	move.w	#0,spindash_counter(a0)
+
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	Obj4C_Spindash_ResetScr
	move.w	#(AniIDWebAni_Spindash<<8)|(AniIDWebAni_Walk<<0),anim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	addi.w	#$200,spindash_counter(a0)
	cmpi.w	#$800,spindash_counter(a0)
	blo.s	Obj4C_Spindash_ResetScr
	move.w	#$800,spindash_counter(a0)

; loc_1AD78:
Obj4C_Spindash_ResetScr:
	addq.l	#4,sp
	cmpi.w	#(224/2)-16,(Camera_Y_pos_bias).w
	beq.s	loc_1AD8C
	bhs.s	+
	addq.w	#4,(Camera_Y_pos_bias).w
+	subq.w	#2,(Camera_Y_pos_bias).w

loc_1AD8C:
	bsr.w	webtv_LevelBound
	bsr.w	AnglePos
	rts
; End of subroutine webtv_UpdateSpindash


; ---------------------------------------------------------------------------
; Subroutine to slow webtv walking up a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AD96:
webtv_SlopeResist:
	move.b	angle(a0),d0
	addi.b	#$60,d0
	cmpi.b	#$C0,d0
	bhs.s	return_1ADCA
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	#$20,d0
	asr.l	#8,d0
	tst.w	inertia(a0)
	beq.s	return_1ADCA
	bmi.s	loc_1ADC6
	tst.w	d0
	beq.s	+
	add.w	d0,inertia(a0)	; change webtv's $14
+
	rts
; ---------------------------------------------------------------------------

loc_1ADC6:
	add.w	d0,inertia(a0)

return_1ADCA:
	rts
; End of subroutine webtv_SlopeResist

; ---------------------------------------------------------------------------
; Subroutine to push webtv down a slope while he's rolling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1ADCC:
webtv_RollRepel:
	move.b	angle(a0),d0
	addi.b	#$60,d0
	cmpi.b	#$C0,d0
	bhs.s	return_1AE06
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	#$50,d0
	asr.l	#8,d0
	tst.w	inertia(a0)
	bmi.s	loc_1ADFC
	tst.w	d0
	bpl.s	loc_1ADF6
	asr.l	#2,d0

loc_1ADF6:
	add.w	d0,inertia(a0)
	rts
; ===========================================================================

loc_1ADFC:
	tst.w	d0
	bmi.s	loc_1AE02
	asr.l	#2,d0

loc_1AE02:
	add.w	d0,inertia(a0)

return_1AE06:
	rts
; End of function webtv_RollRepel

; ---------------------------------------------------------------------------
; Subroutine to push webtv down a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AE08:
webtv_SlopeRepel:
	nop
	tst.b	stick_to_convex(a0)
	bne.s	return_1AE42
	tst.w	move_lock(a0)
	bne.s	loc_1AE44
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	return_1AE42
	mvabs.w	inertia(a0),d0
	cmpi.w	#$280,d0
	bhs.s	return_1AE42
	clr.w	inertia(a0)
	bset	#1,status(a0)
	move.w	#$1E,move_lock(a0)

return_1AE42:
	rts
; ===========================================================================

loc_1AE44:
	subq.w	#1,move_lock(a0)
	rts
; End of function webtv_SlopeRepel

; ---------------------------------------------------------------------------
; Subroutine to return webtv's angle to 0 as he jumps
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AE4A:
webtv_JumpAngle:
	move.b	angle(a0),d0	; get webtv's angle
	beq.s	webtv_JumpFlip	; if already 0, branch
	bpl.s	loc_1AE5A	; if higher than 0, branch

	addq.b	#2,d0		; increase angle
	bcc.s	BranchTo_webtv_JumpAngleSet
	moveq	#0,d0

BranchTo_webtv_JumpAngleSet ; BranchTo
	bra.s	webtv_JumpAngleSet
; ===========================================================================

loc_1AE5A:
	subq.b	#2,d0		; decrease angle
	bcc.s	webtv_JumpAngleSet
	moveq	#0,d0

; loc_1AE60:
webtv_JumpAngleSet:
	move.b	d0,angle(a0)
; End of function webtv_JumpAngle
	; continue straight to webtv_JumpFlip

; ---------------------------------------------------------------------------
; Updates webtv's secondary angle if he's tumbling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AE64:
webtv_JumpFlip:
	move.b	flip_angle(a0),d0
	beq.s	return_1AEA8
	tst.w	inertia(a0)
	bmi.s	webtv_JumpLeftFlip
; loc_1AE70:
webtv_JumpRightFlip:
	move.b	flip_speed(a0),d1
	add.b	d1,d0
	bcc.s	BranchTo_webtv_JumpFlipSet
	subq.b	#1,flips_remaining(a0)
	bcc.s	BranchTo_webtv_JumpFlipSet
	move.b	#0,flips_remaining(a0)
	moveq	#0,d0

BranchTo_webtv_JumpFlipSet ; BranchTo
	bra.s	webtv_JumpFlipSet
; ===========================================================================
; loc_1AE88:
webtv_JumpLeftFlip:
	tst.b	flip_turned(a0)
	bne.s	webtv_JumpRightFlip
	move.b	flip_speed(a0),d1
	sub.b	d1,d0
	bcc.s	webtv_JumpFlipSet
	subq.b	#1,flips_remaining(a0)
	bcc.s	webtv_JumpFlipSet
	move.b	#0,flips_remaining(a0)
	moveq	#0,d0
; loc_1AEA4:
webtv_JumpFlipSet:
	move.b	d0,flip_angle(a0)

return_1AEA8:
	rts
; End of function webtv_JumpFlip

; ---------------------------------------------------------------------------
; Subroutine for webtv to interact with the floor and walls when he's in the air
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AEAA: webtv_Floor:
webtv_DoLevelCollision:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,top_solid_bit(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	lrb_solid_bit(a0),d5
	move.w	x_vel(a0),d1
	move.w	y_vel(a0),d2
	jsr	(CalcAngle).l
	subi.b	#$20,d0
	andi.b	#$C0,d0
	cmpi.b	#$40,d0
	beq.w	webtv_HitLeftWall
	cmpi.b	#$80,d0
	beq.w	webtv_HitCeilingAndWalls
	cmpi.b	#$C0,d0
	beq.w	webtv_HitRightWall
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop webtv since he hit a wall
+
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop webtv since he hit a wall
+
	bsr.w	webtv_CheckFloor
	tst.w	d1
	bpl.s	return_1AF8A
	move.b	y_vel(a0),d2
	addq.b	#8,d2
	neg.b	d2
	cmp.b	d2,d1
	bge.s	+
	cmp.b	d2,d0
	blt.s	return_1AF8A
+
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	webtv_ResetOnFloor
	move.b	d3,d0
	addi.b	#$20,d0
	andi.b	#$40,d0
	bne.s	loc_1AF68
	move.b	d3,d0
	addi.b	#$10,d0
	andi.b	#$20,d0
	beq.s	loc_1AF5A
	asr	y_vel(a0)
	bra.s	loc_1AF7C
; ===========================================================================

loc_1AF5A:
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
	rts
; ===========================================================================

loc_1AF68:
	move.w	#0,x_vel(a0) ; stop webtv since he hit a wall
	cmpi.w	#$FC0,y_vel(a0)
	ble.s	loc_1AF7C
	move.w	#$FC0,y_vel(a0)

loc_1AF7C:
	move.w	y_vel(a0),inertia(a0)
	tst.b	d3
	bpl.s	return_1AF8A
	neg.w	inertia(a0)

return_1AF8A:
	rts
; ===========================================================================
; loc_1AF8C:
webtv_HitLeftWall:
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	webtv_HitCeiling ; branch if distance is positive (not inside wall)
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop webtv since he hit a wall
	move.w	y_vel(a0),inertia(a0)
	rts
; ===========================================================================
; loc_1AFA6:
webtv_HitCeiling:
	bsr.w	webtv_CheckCeiling
	tst.w	d1
	bpl.s	webtv_HitFloor ; branch if distance is positive (not inside ceiling)
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	return_1AFBE
	move.w	#0,y_vel(a0) ; stop webtv in y since he hit a ceiling

return_1AFBE:
	rts
; ===========================================================================
; loc_1AFC0:
webtv_HitFloor:
	tst.w	y_vel(a0)
	bmi.s	return_1AFE6
	bsr.w	webtv_CheckFloor
	tst.w	d1
	bpl.s	return_1AFE6
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	webtv_ResetOnFloor
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)

return_1AFE6:
	rts
; ===========================================================================
; loc_1AFE8:
webtv_HitCeilingAndWalls:
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop webtv since he hit a wall
+
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop webtv since he hit a wall
+
	bsr.w	webtv_CheckCeiling
	tst.w	d1
	bpl.s	return_1B042
	sub.w	d1,y_pos(a0)
	move.b	d3,d0
	addi.b	#$20,d0
	andi.b	#$40,d0
	bne.s	loc_1B02C
	move.w	#0,y_vel(a0) ; stop webtv in y since he hit a ceiling
	rts
; ===========================================================================

loc_1B02C:
	move.b	d3,angle(a0)
	bsr.w	webtv_ResetOnFloor
	move.w	y_vel(a0),inertia(a0)
	tst.b	d3
	bpl.s	return_1B042
	neg.w	inertia(a0)

return_1B042:
	rts
; ===========================================================================
; loc_1B044:
webtv_HitRightWall:
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	webtv_HitCeiling2
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop webtv since he hit a wall
	move.w	y_vel(a0),inertia(a0)
	rts
; ===========================================================================
; identical to webtv_HitCeiling...
; loc_1B05E:
webtv_HitCeiling2:
	bsr.w	webtv_CheckCeiling
	tst.w	d1
	bpl.s	webtv_HitFloor2
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	return_1B076
	move.w	#0,y_vel(a0) ; stop webtv in y since he hit a ceiling

return_1B076:
	rts
; ===========================================================================
; identical to webtv_HitFloor...
; loc_1B078:
webtv_HitFloor2:
	tst.w	y_vel(a0)
	bmi.s	return_1B09E
	bsr.w	webtv_CheckFloor
	tst.w	d1
	bpl.s	return_1B09E
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	webtv_ResetOnFloor
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)

return_1B09E:
	rts
; End of function webtv_DoLevelCollision



; ---------------------------------------------------------------------------
; Subroutine to reset webtv's mode when he lands on the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B0A0:
webtv_ResetOnFloor:
	tst.b	pinball_mode(a0)
	bne.s	webtv_ResetOnFloor_Part3
	move.b	#AniIDWebAni_Walk,anim(a0)
; loc_1B0AC:
webtv_ResetOnFloor_Part2:
	; some routines outside of Tails' code can call webtv_ResetOnFloor_Part2
	; when they mean to call Tails_ResetOnFloor_Part2, so fix that here
	_cmpi.b	#ObjID_webtv,id(a0)	; is this object ID webtv (obj01)?
	bne.w	Tails_ResetOnFloor_Part2	; if not, branch to the Tails version of this code

	btst	#2,status(a0)
	beq.s	webtv_ResetOnFloor_Part3
	bclr	#2,status(a0)
	move.b	#$13,y_radius(a0) ; this increases webtv's collision height to standing
	move.b	#9,x_radius(a0)
	move.b	#AniIDWebAni_Walk,anim(a0)	; use running/walking/standing animation
	subq.w	#5,y_pos(a0)	; move webtv up 5 pixels so the increased height doesn't push him into the ground
; loc_1B0DA:
webtv_ResetOnFloor_Part3:
	bclr	#1,status(a0)
	bclr	#5,status(a0)
	bclr	#4,status(a0)
	move.b	#0,jumping(a0)
	move.w	#0,(Chain_Bonus_counter).w
	move.b	#0,flip_angle(a0)
	move.b	#0,flip_turned(a0)
	move.b	#0,flips_remaining(a0)
	move.w	#0,(webtv_Look_delay_counter).w
	cmpi.b	#AniIDWebAni_Hang2,anim(a0)
	bne.s	return_1B11E
	move.b	#AniIDWebAni_Walk,anim(a0)

return_1B11E:
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; webtv when he gets hurt
; ---------------------------------------------------------------------------
; loc_1B120: Obj_01_Sub_4:
Obj4C_Hurt:
	tst.w	(Debug_mode_flag).w
	beq.s	Obj4C_Hurt_Normal
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	Obj4C_Hurt_Normal
	move.w	#1,(Debug_placement_mode).w
	clr.b	(Control_Locked).w
	rts
; ---------------------------------------------------------------------------
; loc_1B13A:
Obj4C_Hurt_Normal:
	tst.b	routine_secondary(a0)
	bmi.w	webtv_HurtInstantRecover
	jsr	(ObjectMove).l
	addi.w	#$30,y_vel(a0)
	btst	#6,status(a0)
	beq.s	+
	subi.w	#$20,y_vel(a0)
+
	cmpi.w	#-$100,(Camera_Min_Y_pos).w
	bne.s	+
	andi.w	#$7FF,y_pos(a0)
+
	bsr.w	webtv_HurtStop
	bsr.w	webtv_LevelBound
	bsr.w	webtv_RecordPos
	bsr.w	webtv_Animate
	bsr.w	LoadwebtvDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================
; loc_1B184:
webtv_HurtStop:
    if fixBugs
	; a2 needs to be set here, otherwise KillCharacter
	; will access a dangling pointer!
	movea.l	a0,a2
    endif
	move.w	(Camera_Max_Y_pos).w,d0
    if fixBugs
	; The original code does not consider that the camera boundary
	; may be in the middle of lowering itself, which is why going
	; down the S-tunnel in Green Hill Zone Act 1 fast enough can
	; kill webtv.
	move.w	(Camera_Max_Y_pos_target).w,d1
	cmp.w	d0,d1
	blo.s	.skip
	move.w	d1,d0
.skip:
    endif
	addi.w	#224,d0
	cmp.w	y_pos(a0),d0
	blt.w	JmpTo_KillCharacter
	bsr.w	webtv_DoLevelCollision
	btst	#1,status(a0)
	bne.s	return_1B1C8
	moveq	#0,d0
	move.w	d0,y_vel(a0)
	move.w	d0,x_vel(a0)
	move.w	d0,inertia(a0)
	move.b	d0,obj_control(a0)
	move.b	#AniIDWebAni_Walk,anim(a0)
	subq.b	#2,routine(a0)	; => Obj4C_Control
	move.w	#$78,invulnerable_time(a0)
	move.b	#0,spindash_flag(a0)

return_1B1C8:
	rts
; ===========================================================================
; makes webtv recover control after being hurt before landing
; seems to be unused
; loc_1B1CA:
webtv_HurtInstantRecover:
	subq.b	#2,routine(a0)	; => Obj4C_Control
	move.b	#0,routine_secondary(a0)
	bsr.w	webtv_RecordPos
	bsr.w	webtv_Animate
	bsr.w	LoadwebtvDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================

; ---------------------------------------------------------------------------
; webtv when he dies
; ...poor webtv
; ---------------------------------------------------------------------------

; loc_1B1E6: Obj_01_Sub_6:
Obj4C_Dead:
	tst.w	(Debug_mode_flag).w
	beq.s	+
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	+
	move.w	#1,(Debug_placement_mode).w
	clr.b	(Control_Locked).w
	rts
+
	bsr.w	CheckGameOver
	jsr	(ObjectMoveAndFall).l
	bsr.w	webtv_RecordPos
	bsr.w	webtv_Animate
	bsr.w	LoadwebtvDynPLC
	jmp	(DisplaySprite).l

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B21C:
CheckGameOver:
	move.b	#1,(Scroll_lock).w
	move.b	#0,spindash_flag(a0)
	move.w	(Camera_Max_Y_pos).w,d0
	addi.w	#$100,d0
	cmp.w	y_pos(a0),d0
	bge.w	return_1B31A
	move.b	#8,routine(a0)	; => Obj4C_Gone
	move.w	#60,restart_countdown(a0)
	addq.b	#1,(Update_HUD_lives).w	; update lives counter
	subq.b	#1,(Life_count).w	; subtract 1 from number of lives
	bne.s	Obj4C_ResetLevel	; if it's not a game over, branch
	move.w	#0,restart_countdown(a0)
	move.b	#ObjID_GameOver,(GameOver_GameText+id).w ; load Obj39 (game over text)
	move.b	#ObjID_GameOver,(GameOver_OverText+id).w ; load Obj39 (game over text)
	move.b	#1,(GameOver_OverText+mapping_frame).w
	move.w	a0,(GameOver_GameText+parent).w
	clr.b	(Time_Over_flag).w
; loc_1B26E:
Obj4C_Finished:
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	move.b	#8,routine(a0)	; => Obj4C_Gone
	move.w	#MusID_GameOver,d0
	jsr	(PlayMusic).l
	moveq	#PLCID_GameOver,d0
	jmp	(LoadPLC).l
; End of function CheckGameOver

; ===========================================================================
; ---------------------------------------------------------------------------
; webtv when the level is restarted
; ---------------------------------------------------------------------------
; loc_1B28E:
Obj4C_ResetLevel:
	tst.b	(Time_Over_flag).w
	beq.s	Obj4C_ResetLevel_Part2
	move.w	#0,restart_countdown(a0)
	move.b	#ObjID_TimeOver,(TimeOver_TimeText+id).w ; load Obj39
	move.b	#ObjID_TimeOver,(TimeOver_OverText+id).w ; load Obj39
	move.b	#2,(TimeOver_TimeText+mapping_frame).w
	move.b	#3,(TimeOver_OverText+mapping_frame).w
	move.w	a0,(TimeOver_TimeText+parent).w
	bra.s	Obj4C_Finished
; ---------------------------------------------------------------------------
Obj4C_ResetLevel_Part2:
	tst.w	(Two_player_mode).w
	beq.s	return_1B31A
	move.b	#0,(Scroll_lock).w
	move.b	#$A,routine(a0)	; => Obj4C_Respawning
	move.w	(Saved_x_pos).w,x_pos(a0)
	move.w	(Saved_y_pos).w,y_pos(a0)
	move.w	(Saved_art_tile).w,art_tile(a0)
	move.w	(Saved_Solid_bits).w,top_solid_bit(a0)
	clr.w	(Ring_count).w
	clr.b	(Extra_life_flags).w
	move.b	#0,obj_control(a0)
	move.b	#5,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#2,status(a0)
	move.w	#0,move_lock(a0)
	move.w	#0,restart_countdown(a0)

return_1B31A:
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; webtv when he's offscreen and waiting for the level to restart
; ---------------------------------------------------------------------------
; loc_1B31C: Obj_01_Sub_8:
Obj4C_Gone:
	tst.w	restart_countdown(a0)
	beq.s	+
	subq.w	#1,restart_countdown(a0)
	bne.s	+
	move.w	#1,(Level_Inactive_flag).w
+
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; webtv when he's waiting for the camera to scroll back to where he respawned
; ---------------------------------------------------------------------------
; loc_1B330: Obj_01_Sub_A:
Obj4C_Respawning:
	tst.w	(Camera_X_pos_diff).w
	bne.s	+
	tst.w	(Camera_Y_pos_diff).w
	bne.s	+
	move.b	#2,routine(a0)	; => Obj4C_Control
+
	bsr.w	webtv_Animate
	bsr.w	LoadwebtvDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to animate webtv's sprites
; See also: AnimateSprite
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B350:
webtv_Animate:
	lea	(webtvAniData).l,a1
	tst.b	(Super_webtv_flag).w
	beq.s	+
	lea	(SuperwebtvAniData).l,a1
+
	moveq	#0,d0
	move.b	anim(a0),d0
	cmp.b	prev_anim(a0),d0	; has animation changed?
	beq.s	SAnim_Do		; if not, branch
	move.b	d0,prev_anim(a0)	; set previous animation
	move.b	#0,anim_frame(a0)	; reset animation frame
	move.b	#0,anim_frame_duration(a0)	; reset frame duration
	bclr	#5,status(a0)
; loc_1B384:
SAnim_Do:
	add.w	d0,d0
	adda.w	(a1,d0.w),a1	; calculate address of appropriate animation script
	move.b	(a1),d0
	bmi.s	SAnim_WalkRun	; if animation is walk/run/roll/jump, branch
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.s	SAnim_Delay			; if time remains, branch
	move.b	d0,anim_frame_duration(a0)	; load frame duration
; loc_1B3AA:
SAnim_Do2:
	moveq	#0,d1
	move.b	anim_frame(a0),d1	; load current frame number
	move.b	1(a1,d1.w),d0		; read sprite number from script
	cmpi.b	#$F0,d0
	bhs.s	SAnim_End_FF		; if animation is complete, branch
; loc_1B3BA:
SAnim_Next:
	move.b	d0,mapping_frame(a0)	; load sprite number
	addq.b	#1,anim_frame(a0)	; go to next frame
; return_1B3C2:
SAnim_Delay:
	rts
; ===========================================================================
; loc_1B3C4:
SAnim_End_FF:
	addq.b	#1,d0		; is the end flag = $FF?
	bne.s	SAnim_End_FE	; if not, branch
	move.b	#0,anim_frame(a0)	; restart the animation
	move.b	1(a1),d0	; read sprite number
	bra.s	SAnim_Next
; ===========================================================================
; loc_1B3D4:
SAnim_End_FE:
	addq.b	#1,d0		; is the end flag = $FE?
	bne.s	SAnim_End_FD	; if not, branch
	move.b	2(a1,d1.w),d0	; read the next byte in the script
	sub.b	d0,anim_frame(a0)	; jump back d0 bytes in the script
	sub.b	d0,d1
	move.b	1(a1,d1.w),d0	; read sprite number
	bra.s	SAnim_Next
; ===========================================================================
; loc_1B3E8:
SAnim_End_FD:
	addq.b	#1,d0			; is the end flag = $FD?
	bne.s	SAnim_End		; if not, branch
	move.b	2(a1,d1.w),anim(a0)	; read next byte, run that animation
; return_1B3F2:
SAnim_End:
	rts
; ===========================================================================
; loc_1B3F4:
SAnim_WalkRun:
	addq.b	#1,d0		; is the start flag = $FF?
	bne.w	SAnim_Roll	; if not, branch
	moveq	#0,d0		; is animation walking/running?
	move.b	flip_angle(a0),d0	; if not, branch
	bne.w	SAnim_Tumble
	moveq	#0,d1
	move.b	angle(a0),d0	; get webtv's angle
	bmi.s	+
	beq.s	+
	subq.b	#1,d0
+
	move.b	status(a0),d2
	andi.b	#1,d2		; is webtv mirrored horizontally?
	bne.s	+		; if yes, branch
	not.b	d0		; reverse angle
+
	addi.b	#$10,d0		; add $10 to angle
	bpl.s	+		; if angle is $0-$7F, branch
	moveq	#3,d1
+
	andi.b	#$FC,render_flags(a0)
	eor.b	d1,d2
	or.b	d2,render_flags(a0)
	btst	#5,status(a0)
	bne.w	SAnim_Push
	lsr.b	#4,d0		; divide angle by 16
	andi.b	#6,d0		; angle must be 0, 2, 4 or 6
	mvabs.w	inertia(a0),d2	; get webtv's "speed" for animation purposes
    if status_sec_isSliding = 7
	tst.b	status_secondary(a0)
	bpl.w	+
    else
	btst	#status_sec_isSliding,status_secondary(a0)
	beq.w	+
    endif
	add.w	d2,d2
+
	tst.b	(Super_webtv_flag).w
	bne.s	SAnim_Super
	lea	(WebAni_Run).l,a1	; use running animation
	cmpi.w	#$600,d2		; is webtv at running speed?
	bhs.s	+			; use running animation
	lea	(WebAni_Walk).l,a1	; if yes, branch
	add.b	d0,d0
+
	add.b	d0,d0
	move.b	d0,d3
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	1(a1,d1.w),d0
	cmpi.b	#-1,d0
	bne.s	+
	move.b	#0,anim_frame(a0)
	move.b	1(a1),d0
+
	move.b	d0,mapping_frame(a0)
	add.b	d3,mapping_frame(a0)
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	return_1B4AC
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)	; modify frame duration
	addq.b	#1,anim_frame(a0)		; modify frame number

return_1B4AC:
	rts
; ===========================================================================
; loc_1B4AE:
SAnim_Super:
	lea	(SupWebAni_Run).l,a1	; use fast animation
	cmpi.w	#$800,d2		; is webtv moving fast?
	bhs.s	SAnim_SuperRun		; if yes, branch
	lea	(SupWebAni_Walk).l,a1	; use slower animation
	add.b	d0,d0
	add.b	d0,d0
	bra.s	SAnim_SuperWalk
; ---------------------------------------------------------------------------
; loc_1B4C6:
SAnim_SuperRun:
	lsr.b	#1,d0
; loc_1B4C8:
SAnim_SuperWalk:
	move.b	d0,d3
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	1(a1,d1.w),d0
	cmpi.b	#-1,d0
	bne.s	+
	move.b	#0,anim_frame(a0)
	move.b	1(a1),d0
+
	move.b	d0,mapping_frame(a0)
	add.b	d3,mapping_frame(a0)
	move.b	(Level_frame_counter+1).w,d1
	andi.b	#3,d1
	bne.s	+
	cmpi.b	#$B5,mapping_frame(a0)
	bhs.s	+
	addi.b	#$20,mapping_frame(a0)
+
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	return_1B51E
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)
	addq.b	#1,anim_frame(a0)

return_1B51E:
	rts
; ===========================================================================
; loc_1B520:
SAnim_Tumble:
	move.b	flip_angle(a0),d0
	moveq	#0,d1
	move.b	status(a0),d2
	andi.b	#1,d2
	bne.s	SAnim_Tumble_Left

	andi.b	#$FC,render_flags(a0)
	addi.b	#$B,d0
	divu.w	#$16,d0
	addi.b	#$5F,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================
; loc_1B54E:
SAnim_Tumble_Left:
	andi.b	#$FC,render_flags(a0)
	tst.b	flip_turned(a0)
	beq.s	loc_1B566
	ori.b	#1,render_flags(a0)
	addi.b	#$B,d0
	bra.s	loc_1B572
; ===========================================================================

loc_1B566:
	ori.b	#3,render_flags(a0)
	neg.b	d0
	addi.b	#$8F,d0

loc_1B572:
	divu.w	#$16,d0
	addi.b	#$5F,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================
; loc_1B586:
SAnim_Roll:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.w	SAnim_Delay			; if time remains, branch
	addq.b	#1,d0		; is the start flag = $FE?
	bne.s	SAnim_Push	; if not, branch
	mvabs.w	inertia(a0),d2
	lea	(WebAni_Roll2).l,a1
	cmpi.w	#$600,d2
	bhs.s	+
	lea	(WebAni_Roll).l,a1
+
	neg.w	d2
	addi.w	#$400,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	SAnim_Do2
; ===========================================================================

SAnim_Push:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.w	SAnim_Delay			; if time remains, branch
	move.w	inertia(a0),d2
	bmi.s	+
	neg.w	d2
+
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#6,d2
	move.b	d2,anim_frame_duration(a0)
	lea	(WebAni_Push).l,a1
	tst.b	(Super_webtv_flag).w
	beq.s	+
	lea	(SupWebAni_Push).l,a1
+
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	SAnim_Do2
; ===========================================================================

; ---------------------------------------------------------------------------
; Animation script - webtv
; ---------------------------------------------------------------------------
; off_1B618:
webtvAniData:			offsetTable
WebAni_Walk_ptr:		offsetTableEntry.w WebAni_Walk		;  0 ;   0
WebAni_Run_ptr:			offsetTableEntry.w WebAni_Run		;  1 ;   1
WebAni_Roll_ptr:		offsetTableEntry.w WebAni_Roll		;  2 ;   2
WebAni_Roll2_ptr:		offsetTableEntry.w WebAni_Roll2		;  3 ;   3
WebAni_Push_ptr:		offsetTableEntry.w WebAni_Push		;  4 ;   4
WebAni_Wait_ptr:		offsetTableEntry.w WebAni_Wait		;  5 ;   5
WebAni_Balance_ptr:		offsetTableEntry.w WebAni_Balance	;  6 ;   6
WebAni_LookUp_ptr:		offsetTableEntry.w WebAni_LookUp	;  7 ;   7
WebAni_Duck_ptr:		offsetTableEntry.w WebAni_Duck		;  8 ;   8
WebAni_Spindash_ptr:		offsetTableEntry.w WebAni_Spindash	;  9 ;   9
WebAni_Blink_ptr:		offsetTableEntry.w WebAni_Blink		; 10 ;  $A
WebAni_GetUp_ptr:		offsetTableEntry.w WebAni_GetUp		; 11 ;  $B
WebAni_Balance2_ptr:		offsetTableEntry.w WebAni_Balance2	; 12 ;  $C
WebAni_Stop_ptr:		offsetTableEntry.w WebAni_Stop		; 13 ;  $D
WebAni_Float_ptr:		offsetTableEntry.w WebAni_Float		; 14 ;  $E
WebAni_Float2_ptr:		offsetTableEntry.w WebAni_Float2	; 15 ;  $F
WebAni_Spring_ptr:		offsetTableEntry.w WebAni_Spring	; 16 ; $10
WebAni_Hang_ptr:		offsetTableEntry.w WebAni_Hang		; 17 ; $11
WebAni_Dash2_ptr:		offsetTableEntry.w WebAni_Dash2		; 18 ; $12
WebAni_Dash3_ptr:		offsetTableEntry.w WebAni_Dash3		; 19 ; $13
WebAni_Hang2_ptr:		offsetTableEntry.w WebAni_Hang2		; 20 ; $14
WebAni_Bubble_ptr:		offsetTableEntry.w WebAni_Bubble	; 21 ; $15
WebAni_DeathBW_ptr:		offsetTableEntry.w WebAni_DeathBW	; 22 ; $16
WebAni_Drown_ptr:		offsetTableEntry.w WebAni_Drown		; 23 ; $17
WebAni_Death_ptr:		offsetTableEntry.w WebAni_Death		; 24 ; $18
WebAni_Hurt_ptr:		offsetTableEntry.w WebAni_Hurt		; 25 ; $19
WebAni_Hurt2_ptr:		offsetTableEntry.w WebAni_Hurt		; 26 ; $1A
WebAni_Slide_ptr:		offsetTableEntry.w WebAni_Slide		; 27 ; $1B
WebAni_Blank_ptr:		offsetTableEntry.w WebAni_Blank		; 28 ; $1C
WebAni_Balance3_ptr:		offsetTableEntry.w WebAni_Balance3	; 29 ; $1D
WebAni_Balance4_ptr:		offsetTableEntry.w WebAni_Balance4	; 30 ; $1E
SupWebAni_Transform_ptr:	offsetTableEntry.w SupWebAni_Transform	; 31 ; $1F
WebAni_Lying_ptr:		offsetTableEntry.w WebAni_Lying		; 32 ; $20
WebAni_LieDown_ptr:		offsetTableEntry.w WebAni_LieDown	; 33 ; $21

WebAni_Walk:	dc.b $FF, $F,$10,$11,$12,$13,$14, $D, $E,$FF
	rev02even
WebAni_Run:	dc.b $FF,$2D,$2E,$2F,$30,$FF,$FF,$FF,$FF,$FF
	rev02even
WebAni_Roll:	dc.b $FE,$3D,$41,$3E,$41,$3F,$41,$40,$41,$FF
	rev02even
WebAni_Roll2:	dc.b $FE,$3D,$41,$3E,$41,$3F,$41,$40,$41,$FF
	rev02even
WebAni_Push:	dc.b $FD,$48,$49,$4A,$4B,$FF,$FF,$FF,$FF,$FF
	rev02even
WebAni_Wait:
	dc.b   5,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1
	dc.b   1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  2
	dc.b   3,  3,  3,  3,  3,  4,  4,  4,  5,  5,  5,  4,  4,  4,  5,  5
	dc.b   5,  4,  4,  4,  5,  5,  5,  4,  4,  4,  5,  5,  5,  6,  6,  6
	dc.b   6,  6,  6,  6,  6,  6,  6,  4,  4,  4,  5,  5,  5,  4,  4,  4
	dc.b   5,  5,  5,  4,  4,  4,  5,  5,  5,  4,  4,  4,  5,  5,  5,  6
	dc.b   6,  6,  6,  6,  6,  6,  6,  6,  6,  4,  4,  4,  5,  5,  5,  4
	dc.b   4,  4,  5,  5,  5,  4,  4,  4,  5,  5,  5,  4,  4,  4,  5,  5
	dc.b   5,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  4,  4,  4,  5,  5
	dc.b   5,  4,  4,  4,  5,  5,  5,  4,  4,  4,  5,  5,  5,  4,  4,  4
	dc.b   5,  5,  5,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  7,  8,  8
	dc.b   8,  9,  9,  9,$FE,  6
	rev02even
WebAni_Balance:	dc.b   9,$CC,$CD,$CE,$CD,$FF
	rev02even
WebAni_LookUp:	dc.b   5, $B, $C,$FE,  1
	rev02even
WebAni_Duck:	dc.b   5,$4C,$4D,$FE,  1
	rev02even
WebAni_Spindash:dc.b   0,$42,$43,$42,$44,$42,$45,$42,$46,$42,$47,$FF
	rev02even
WebAni_Blink:	dc.b   1,  2,$FD,  0
	rev02even
WebAni_GetUp:	dc.b   3, $A,$FD,  0
	rev02even
WebAni_Balance2:dc.b   3,$C8,$C9,$CA,$CB,$FF
	rev02even
WebAni_Stop:	dc.b   5,$D2,$D3,$D4,$D5,$FD,  0 ; halt/skidding animation
	rev02even
WebAni_Float:	dc.b   7,$54,$59,$FF
	rev02even
WebAni_Float2:	dc.b   7,$54,$55,$56,$57,$58,$FF
	rev02even
WebAni_Spring:	dc.b $2F,$5B,$FD,  0
	rev02even
WebAni_Hang:	dc.b   1,$50,$51,$FF
	rev02even
WebAni_Dash2:	dc.b  $F,$43,$43,$43,$FE,  1
	rev02even
WebAni_Dash3:	dc.b  $F,$43,$44,$FE,  1
	rev02even
WebAni_Hang2:	dc.b $13,$6B,$6C,$FF
	rev02even
WebAni_Bubble:	dc.b  $B,$5A,$5A,$11,$12,$FD,  0 ; breathe
	rev02even
WebAni_DeathBW:	dc.b $20,$5E,$FF
	rev02even
WebAni_Drown:	dc.b $20,$5D,$FF
	rev02even
WebAni_Death:	dc.b $20,$5C,$FF
	rev02even
WebAni_Hurt:	dc.b $40,$4E,$FF
	rev02even
WebAni_Slide:	dc.b   9,$4E,$4F,$FF
	rev02even
WebAni_Blank:	dc.b $77,  0,$FD,  0
	rev02even
WebAni_Balance3:dc.b $13,$D0,$D1,$FF
	rev02even
WebAni_Balance4:dc.b   3,$CF,$C8,$C9,$CA,$CB,$FE,  4
	rev02even
WebAni_Lying:	dc.b   9,  8,  9,$FF
	rev02even
WebAni_LieDown:	dc.b   3,  7,$FD,  0
	even

; ---------------------------------------------------------------------------
; Animation script - Super webtv
; (many of these point to the data above this)
; ---------------------------------------------------------------------------
SuperwebtvAniData: offsetTable
	offsetTableEntry.w SupWebAni_Walk	;  0 ;   0
	offsetTableEntry.w SupWebAni_Run	;  1 ;   1
	offsetTableEntry.w WebAni_Roll		;  2 ;   2
	offsetTableEntry.w WebAni_Roll2		;  3 ;   3
	offsetTableEntry.w SupWebAni_Push	;  4 ;   4
	offsetTableEntry.w SupWebAni_Stand	;  5 ;   5
	offsetTableEntry.w SupWebAni_Balance	;  6 ;   6
	offsetTableEntry.w WebAni_LookUp	;  7 ;   7
	offsetTableEntry.w SupWebAni_Duck	;  8 ;   8
	offsetTableEntry.w WebAni_Spindash	;  9 ;   9
	offsetTableEntry.w WebAni_Blink		; 10 ;  $A
	offsetTableEntry.w WebAni_GetUp		; 11 ;  $B
	offsetTableEntry.w WebAni_Balance2	; 12 ;  $C
	offsetTableEntry.w WebAni_Stop		; 13 ;  $D
	offsetTableEntry.w WebAni_Float		; 14 ;  $E
	offsetTableEntry.w WebAni_Float2	; 15 ;  $F
	offsetTableEntry.w WebAni_Spring	; 16 ; $10
	offsetTableEntry.w WebAni_Hang		; 17 ; $11
	offsetTableEntry.w WebAni_Dash2		; 18 ; $12
	offsetTableEntry.w WebAni_Dash3		; 19 ; $13
	offsetTableEntry.w WebAni_Hang2		; 20 ; $14
	offsetTableEntry.w WebAni_Bubble	; 21 ; $15
	offsetTableEntry.w WebAni_DeathBW	; 22 ; $16
	offsetTableEntry.w WebAni_Drown		; 23 ; $17
	offsetTableEntry.w WebAni_Death		; 24 ; $18
	offsetTableEntry.w WebAni_Hurt		; 25 ; $19
	offsetTableEntry.w WebAni_Hurt		; 26 ; $1A
	offsetTableEntry.w WebAni_Slide		; 27 ; $1B
	offsetTableEntry.w WebAni_Blank		; 28 ; $1C
	offsetTableEntry.w WebAni_Balance3	; 29 ; $1D
	offsetTableEntry.w WebAni_Balance4	; 30 ; $1E
	offsetTableEntry.w SupWebAni_Transform	; 31 ; $1F

SupWebAni_Walk:		dc.b $FF,$77,$78,$79,$7A,$7B,$7C,$75,$76,$FF
	rev02even
SupWebAni_Run:		dc.b $FF,$B5,$B9,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	rev02even
SupWebAni_Push:		dc.b $FD,$BD,$BE,$BF,$C0,$FF,$FF,$FF,$FF,$FF
	rev02even
SupWebAni_Stand:	dc.b   7,$72,$73,$74,$73,$FF
	rev02even
SupWebAni_Balance:	dc.b   9,$C2,$C3,$C4,$C3,$C5,$C6,$C7,$C6,$FF
	rev02even
SupWebAni_Duck:		dc.b   5,$C1,$FF
	rev02even
SupWebAni_Transform:	dc.b   2,$6D,$6D,$6E,$6E,$6F,$70,$71,$70,$71,$70,$71,$70,$71,$FD,  0
	even

; ---------------------------------------------------------------------------
; webtv pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B848:
LoadwebtvDynPLC:

	moveq	#0,d0
	move.b	mapping_frame(a0),d0	; load frame number
; loc_1B84E:
LoadwebtvDynPLC_Part2:
	cmp.b	(webtv_LastLoadedDPLC).w,d0
	beq.s	return_1B89A
	move.b	d0,(webtv_LastLoadedDPLC).w
	lea	(MapRUnc_webtv).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1B89A
	move.w	#tiles_to_bytes(ArtTile_ArtUnc_webtv),d4
; loc_1B86E:
SPLC_ReadEntry:
	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#ArtUnc_webtv,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,SPLC_ReadEntry	; repeat for number of entries

return_1B89A:
	rts
; ===========================================================================

JmpTo_KillCharacter ; JmpTo
	jmp	(KillCharacter).l

	jmpTos0 ; Empty



