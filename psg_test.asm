;;
;; psg_test.asm
;;
;; NES PSG test tool. Expecting assembler is NESASM.
;;
VERSION .macro  ;; Time-stamp: <2014-02-24T18:14:40Z>
	.db "0.02"
	.endm
;;
;; License:
;;
;;   I in a provincial state made this program intended to be public-domain. 
;;   But it might be better for you like me to treat this program as such 
;;   under the (new) BSD-License or under the Artistic License.
;;
;;   Within three months after the release of this program, I
;;   especially admit responsibility of effort for rational request of
;;   correction to this program.
;;
;; Author's Link:
;;
;;   http://jrf.cocolog-nifty.com/software/
;;   (The page is written in Japanese.)
;;

;.utf8 ;; Japanese
;;
;; Thanks:
;;
;;   《MagicKit Homepage - NESASM》
;;   http://www.magicengine.com/mkit/
;;
;;   《NES研究室》
;;   http://hp.vector.co.jp/authors/VA042397/nes/index.html
;;
;;   《ｷﾞｺ猫でもわかるファミコンプログラミング》
;;   http://gikofami.fc2web.com/
;;	

        .inesprg    1
        .ineschr    1
        .inesmir    0	;; Horizontal Mirroring
        .inesmap    0
;; 定数
DebugLevel = 1
ClipX = 1
ClipY = 2
Col1 = ClipX
Col2 = ClipX + 16
Col1Num = 12

CursorSP = 1

LogoX = 28 * 8
LogoY = 24 * 8
LogoSP = 4
NameX = (LogoX / 8) - 3
NameY = (LogoY / 8) + 1
VersionX = (LogoX / 8) - 3
VersionY = (LogoY / 8) + 3

MessageY = 20

KeyStopUnit = 1
KeyStopLongUnit = 8
MenuItemStrLen = 12
MenuItemNum = 28

MD_NONE = 0
MD_INPUT = 1

;; マクロ
Debug	.macro
	if \?1 = 1
	if '\1' != 'a'
	t\1a
	endif
	else
	lda \1
	endif
	sta \2
	.endm

;; Usage: Debug [SRC], [DEST]

;; Debug はただのストアだが、<15 などにストアすれば VNES のメモリビュー
;; アでチェックしやすい。ただのストアよりエディタで検索しやすい。

;; "Debug" is mere "store".  Storing to <15 or else, you can inspect
;; it with Memory Viewer of VNES, and, more easily, can search the
;; string on your editor than "Store".


EnableNMI .macro
	lda #$80	;; スプライトと BG は同じパターン。
;	lda #$90
	sta $2000
	.endm

DisableNMI .macro
	lda #$00
;	lda #$10
	sta $2000
	.endm

EnableScreen .macro
	lda	#$1e
	sta	$2001
	.endm

DisableScreen .macro
	lda #$06	
	sta $2001
	.endm

WaitVWrite .macro
L\@:
	lda $2002
	and #$10
	bne L\@
	.endm


WaitVBlank .macro
L\@:
	lda $2002
	bpl L\@
	.endm

WaitVScan .macro
L\@:
	lda $2002
	bmi L\@
	.endm

WaitVBlankWithCheckKey .macro
L\@:
	jsr CheckKey
	lda $2002
	bpl L\@
	.endm

WaitVScanWithCheckKey .macro
L\@:
	jsr CheckKey
	lda $2002
	bmi L\@
	.endm

SetScroll .macro
	lda <ScrollX
	sta $2005
	lda <ScrollY
	sta $2005
	.endm

ToHexCharA .macro
	clc
	adc #'0'
	cmp #'0' + 10
	bcc L\@
	adc #'A' - '0' - 1 - 10
L\@:
	.endm


SetBitXA .macro
	lda <BitSetTable, x
	.endm

MaskBitXA .macro
	lda <BitMaskTable, x
	.endm


BitAddR0S .macro
	lda \1
	sta <R0
	.endm

BitAddR0 .macro
	asl <R0
	if \2 > 1
	asl <R0
	endif
	if \2 > 2
	asl <R0
	endif
	if \2 > 3
	asl <R0
	endif
	if \2 > 4
	asl <R0
	endif
	if \2 > 5
	asl <R0
	endif
	if \2 > 6
	asl <R0
	endif
	lda \1
	clc
	adc <R0
	sta <R0
	.endm


SwitchA .macro
	asl a
	tax
	lda \1, x
	sta <R0
	lda \1 + 1, x
	sta <R1
	jmp [R0]
	.endm

;;  Interruption Entry
	.bank 1
	.org	$fffa
	.word	NMIHandler
	.word	Start
	.word	$0000

        .bank 0
	.org $0000
;; RAM
RamStart:
ZeroPage:
R0:	.ds 1 
R1:	.ds 1
R2:	.ds 1
R3:	.ds 1
R4:	.ds 1
R5:	.ds 1
R6:	.ds 1
R7:	.ds 1
R8:	.ds 1
R9:	.ds 1
R10:	.ds 1
R11:	.ds 1
R12:	.ds 1
R13:	.ds 1
R14:	.ds 1
R15:	.ds 1

VTime:	
	.ds 4
Key1Bit:	
	.ds 1
Key1:	
	.ds 1
Key1Cur:	
	.ds 1
Key1Time:
	.ds 1
MainMode:
	.ds 1
RefreshFlag:  ;; bits: 0-3:(Reserved), 4:BGCol, 5:Text, 6: Sprite DMA.
	.ds 1
ScrollX:
	.ds 1
ScrollY:
	.ds 1
Cursor:
	.ds 1
PSGParam:
;; Square Wave.
ChannelSW:
	.ds 1
DutyRatio:
	.ds 1
LenSW:
	.ds 1
DecaySW:
	.ds 1
DecayRatio:
	.ds 1
SweepSW:
	.ds 1
SweepRatio:
	.ds 1
SweepFlap:
	.ds 1
SweepLen:
	.ds 1
FreqL:
	.ds 1
FreqH:
	.ds 1
PlayLen:
	.ds 1
;; Triangle Wave.
TriangleSW:
	.ds 1
TCountSW:
	.ds 1
TLen:
	.ds 1
TFreqL:
	.ds 1
TFreqH:
	.ds 1
TPlayLen:
	.ds 1
;; Noise.
NoiseSW:
	.ds 1
NNone:
	.ds 1
NLenSW:
	.ds 1
NDecaySW
	.ds 1
NDecayRatio:
	.ds 1
NType:
	.ds 1
NNone2:
	.ds 1
NWaveLen:
	.ds 1
NNone3:
	.ds 1
NPlayLen:
	.ds 1

ZeroPageWithInitValue:
BitSetTable:
	.ds 8
BitMaskTable:
	.ds 8


Stack = $0100

	.org $0300
SpriteRamStart:
	.ds $100

	.org $0400
BGColBuf:
	.ds 64

        .org $8000
Start:  
	lda $2002  ;; VBlankが発生すると、$2002の7ビット目が1になる
	bpl Start  ;; bit7が0の間は、Startラベルの位置に飛んでループして待つ

	sei			; 割り込み不許可
	cld			; デシマルモードフラグクリア
	ldx	#$ff
	txs			; スタックポインタ初期化 
	inx
	txa
initZeroPage:
	sta <ZeroPage, x
	inx
	bne initZeroPage
	ldx #0
initZeroPage2:
	lda ZeroPageInitValue, x
	sta <ZeroPageWithInitValue,x
	inx
	cpx #ZeroPageInitValueEnd - ZeroPageInitValue
	bne initZeroPage2

	;; PPUコントロールレジスタ初期化
	DisableNMI
	DisableScreen	;; 初期化中はスプライトとBGを表示OFFにする

;; パレットテーブル初期化
	lda #$3f
	sta $2006
	lda #$00
	sta $2006
	ldx #$00
	ldy #$20
initPal:
	lda Palettes, x
	sta $2007
	inx
	dey
	bne initPal

	jsr Cls

	jsr InitTextArea
	jsr DrawLogo
	jsr DrawNum
	jsr ShowCursor
;	lda #%00001100
;	sta $4015

	lda #$70
	ora <RefreshFlag
	sta <RefreshFlag

;; スクリーンオン
	DisableNMI
	EnableScreen
	
	lda #0
	sta MainMode

	lda #0
	sta <Key1Bit

;; メイン
MainLoop:
	jsr CheckKey
	EnableNMI
	cli
	WaitVScan
	SetScroll
	sei
;	DisableNMI
	jsr CheckKey
;	EnableNMI
	cli
	jsr ReadKey
	jsr ParseKey
	lda #0
	sta <Key1Bit
	WaitVBlank
	sei
	DisableNMI
	ldx MainMode
	beq MainLoop
	lda #0
	sta MainMode
	txa
	SwitchA ModeTable

Halt:
	jmp	Halt

MDInput:
	lda <Key1Cur
	ldx #-$10
	cmp #$80 + $00
	beq mdInputChange
	ldx #$10
	cmp #$80 + $10
	beq mdInputChange
	cmp #$80 + $20
	beq mdInputPage
	cmp #$80 + $30
	beq mdInputBeep
	cmp #$8 + $0
	beq mdInputDown
	ldx #$1
	cmp #$8 + $2
	beq mdInputChange
	cmp #$8 + $4
	beq mdInputUp
	ldx #-$1
	cmp #$8 + $6
	beq mdInputChange
	jmp MainLoop
mdInputBeep:
	jsr PSGBeep
	jmp MainLoop
mdInputPage:
	ldx #Col1Num
	lda <Cursor
	cmp #Col1Num
	bcc mdInputPage1
	ldx #0
mdInputPage1:
	txa
	sta <Cursor
	jmp mdInputUp1
mdInputUp:
	dec <Cursor
	lda #$ff
	cmp <Cursor
	bne mdInputUp1
	lda #MenuItemNum - 1
	sta <Cursor
mdInputUp1:
	jsr ShowCursor
	lda #$40
	ora <RefreshFlag
	sta <RefreshFlag
	jmp MainLoop
mdInputDown:
	inc <Cursor
	lda #MenuItemNum
	cmp <Cursor
	bne mdInputUp1
	lda #0
	sta <Cursor
	jmp mdInputUp1

mdInputChange:
	ldy <Cursor
	lda PSGParam, y
	sta <R0
	txa
	clc
	adc <R0
	sta <R0
	lda PSGParamBitLen, y
	tax
	dex
	MaskBitXA
	and <R0
	sta PSGParam, y
	lda #$20
	ora <RefreshFlag
	sta <RefreshFlag
	jmp MainLoop


NMIHandler:
	pha
	txa
	pha
	tya
	pha
	lda <R0
	pha
	lda <R1
	pha

	lda #1
	tax
	dex
	clc
	adc <VTime
	sta <VTime
	txa
	adc <VTime + 1
	sta <VTime + 1
	txa
	adc <VTime + 2
	sta <VTime + 2
	txa
	adc <VTime + 3
	sta <VTime + 3
	lda #$3f
	and VTime
	bne nmiHandler0
	lda SpriteRamStart + CursorSP * 4 + 1
	eor #$10
	sta SpriteRamStart + CursorSP * 4 + 1
	lda <RefreshFlag
	ora #$40
	sta <RefreshFlag
nmiHandler0:
	lda $2002
	SetScroll

	lda <RefreshFlag
	and #$40
	beq nmiHandler1
nmiHandler5:
;; スプライト DMA 設定
	lda	#$3
	sta	$4014
nmiHandler1:
	lda <RefreshFlag
	and #$30
	beq nmiHandler3
	DisableNMI
;	WaitVScan
;	SetScroll
;	jsr CheckKey
;	WaitVBlank
	lda <RefreshFlag
	and #$10
	beq nmiHandler2
	jsr RefreshBGCol
nmiHandler2:
	lda <RefreshFlag
	and #$20
	beq nmiHandler3
	jsr DrawNum
nmiHandler3:
	lda #0
	sta <RefreshFlag

	lda $2002
	SetScroll
	EnableNMI

	pla
	sta <R1
	pla
	sta <R0
	pla
	tay
	pla
	tax
	pla
	rti


CheckKey:
	lda #$01
	sta $4016
	lda #$00
	sta $4016

	txa
	pha
	lda <R0
	pha
	
	ldx #8
checkKey1:
	lda $4016
	lsr a
	rol <R0
	dex
	bne checkKey1
	lda <R0
	ora <Key1Bit
	sta <Key1Bit

	pla
	sta <R0
	pla
	tax
	rts


ReadKey:
	lda <Key1Bit
	sta <R0

	;; 十字キーを手旗符号に変換。
	lda <R0
	and #$f
	tax
	lda Key1FlagTable, x
	sta <Key1

	;; A B SELECT START は同時押しを認めない。
	lda <R0
	and #$f0
	sta <R2
	ldx #8
	lda #$10
readKey4:
	cmp <R2
	beq readKey5
	asl a
	inx
	cpx #8+4
	bne readKey4
	ldx #0
readKey5:
	txa
	asl a
	asl a
	asl a
	asl a
	ora <Key1
	sta <Key1

	rts


ParseKey:
parseKey1P:
	inc <Key1Time
	bne parseKey1Z
	dec <Key1Time
parseKey1Z:	
	lda <Key1
	cmp <Key1Cur
	beq parseKey2P
	lda #0
	sta <Key1Time
parseKey2P:
	lda <Key1Time
	cmp #KeyStopUnit
	bne parseKeyE
parseKeyI:
	lda #MD_INPUT
	sta MainMode
parseKeyE:
	lda <Key1Time
	cmp #KeyStopLongUnit
	bcc parseKeyNL
	lda #0
	sta <Key1Time
parseKeyNL:	
	lda <Key1
	sta <Key1Cur
	rts

InitTextArea:
	lda #0
	sta <R2 ;; Item Number
	lda #low(MenuItemStr)
	sta <R4
	lda #high(MenuItemStr)
	sta <R5
initTextArea1:
	lda <R2
	ldy #Col1
	cmp #Col1Num
	bcc initTextArea2
	sec
	sbc #Col1Num
	ldy #Col2
initTextArea2:
	clc
	adc #ClipY
	sta <R0
	lda #0
	sta <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	tya
	clc
	adc <R0
	sta <R0
	lda #0
	adc <R1
	sta <R1
	lda #$20
	clc
	adc <R1
	sta $2006
	lda <R0
	sta $2006
	ldy #0
initTextArea3:
	lda [R4], y
	beq initTextArea4
	sta $2007
	iny
	jmp initTextArea3
initTextArea4:
	iny
	tya
	clc
	adc <R4
	sta <R4
	lda #0
	adc <R5
	sta <R5
	inc <R2
	lda <R2
	cmp #MenuItemNum
	bne initTextArea1

	lda #high($2000 + 32 * MessageY)
	sta $2006
	lda #low($2000 + 32 * MessageY)
	sta $2006
	ldx #0
initTextArea5:
	lda Message, x
	beq initTextArea6
	sta $2007
	inx
	jmp initTextArea5
initTextArea6:

;	lda #240 - 1
;	sta <ScrollY

	rts

SetCursor:
	tya
	asl a
	asl a
	asl a
	sbc #0		;; SP はなぜか Y 軸に 1 ドットずれる。
	sta SpriteRamStart + CursorSP * 4 + 0
	txa
	asl a
	asl a
	asl a
	sta SpriteRamStart + CursorSP * 4 + 3
	lda #0
	sta SpriteRamStart + CursorSP * 4 + 2
	rts


ShowCursor:
	ldx #Col1 + MenuItemStrLen
	lda <Cursor
	cmp #Col1Num
	bcc showCursor1
	ldx #Col2 + MenuItemStrLen
	sec
	sbc #Col1Num
showCursor1:
	clc
	adc #ClipY
	tay
	inx
	jsr SetCursor
	rts


DrawNum:
	ldx #0  ;; Item Number
drawNum1:
	txa
	and $3
	bne drawNumV
	WaitVScan
	jsr CheckKey
	SetScroll
	WaitVBlank
drawNumV:
	txa
	ldy #Col1 + MenuItemStrLen
	cmp #Col1Num
	bcc drawNum2
	sec
	sbc #Col1Num
	ldy #Col2 + MenuItemStrLen
drawNum2:
	clc
	adc #ClipY
	sta <R0
	lda #0
	sta <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	asl <R0
	rol <R1
	tya
	clc
	adc <R0
	sta <R0
	lda #0
	adc <R1
	sta <R1
	lda #$20
	clc
	adc <R1
	sta $2006
	lda <R0
	sta $2006
	lda PSGParam, x
	sta <R3
	lsr a
	lsr a
	lsr a
	lsr a
	ToHexCharA
	sta $2007
	lda <R3
	and #$f
	ToHexCharA
	sta $2007
	inx
	cpx #MenuItemNum
	beq drawNumE
	jmp drawNum1
drawNumE:

	rts


Cls:
	lda	#$20
	sta	$2006
	lda	#$00
	sta	$2006
	lda	#0
	ldy	#30
cls0:
	ldx	#32
cls1:
	sta $2007
	dex
	bne cls1
	dey
	bne cls0
	ldx #0
	txa
cls2:
	sta SpriteRamStart, x
	inx
	bne cls2

	lda #0
	ldx #0
cls3:
	sta BGColBuf, x
	inx
	cpx #64
	bne cls3
	jsr RefreshBGCol

	rts


RefreshBGCol:
	lda #$23
	sta $2006
	lda #$c0
	sta $2006
	ldx #0
refreshBGCol0:
	lda BGColBuf, x
	sta $2007
	inx
	cpx #64
	bne refreshBGCol0
	rts

DrawBGChr:
	lda <R3
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc <R2
	php
	sta <R4
	lda <R3
	lsr a
	lsr a
	lsr a
	plp
	adc #$20
	sta <R5
	sta $2006
	lda <R4
	sta $2006
	ldy #1
	lda [R0], y
	sta $2007
	iny
	lda [R0], y
	sta $2007

	lda #$20
	clc
	adc <R4
	sta <R4
	lda #0
	adc <R5
	sta <R5
	sta $2006
	lda <R4
	sta $2006
	ldy #3
	lda [R0], y
	sta $2007
	iny
	lda [R0], y
	sta $2007

	ldy #0
	lda [R0], y
	sta <R4
	jsr SetBGColBuf
;	inc <R2
;	jsr SetBGColBuf
;	inc <R3
;	jsr SetBGColBuf
;	dec <R2
;	jsr SetBGColBuf
	rts

SetBGColBuf:
	lda <R3
;	lsr a
;	lsr a
;	asl a
;	asl a
	asl a
	and #$f8
	sta <R5
	lda <R2
	lsr a
	lsr a
	clc
	adc <R5
	sta <R5
	lda <R3
	lsr a
	and #1
	asl a
	sta <R6
	lda <R2
	lsr a
	and #1
	ora <R6
	sta <R6
	lda #$fc
	sta <R7
	lda <R4
	sta <R8
	lda <R6
	asl a
	beq setBGColBuf1
	tax
setBGColBuf0:
	sec
	rol <R7
	asl <R8
	dex
	bne setBGColBuf0
setBGColBuf1:
	ldx <R5
	lda BGColBuf, x
	and <R7
	ora <R8
	sta BGColBuf, x
	rts


DrawSPChr:
	dec <R3		;; SP はなぜか Y 軸に 1 ドットずれる。
	lda <R4
	asl a
	asl a
	tax
	lda <R3
	sta SpriteRamStart, x
	inx
	ldy #1
	lda [R0], y
	sta SpriteRamStart, x
	inx
	ldy #0
	lda [R0], y
	sta SpriteRamStart, x
	inx
	lda <R2
	sta SpriteRamStart, x

	inc <R4
	lda #8
	clc
	adc <R2
	sta <R2
	lda <R4
	asl a
	asl a
	tax
	lda <R3
	sta SpriteRamStart, x
	inx
	ldy #2
	lda [R0], y
	sta SpriteRamStart, x
	inx
	ldy #0
	lda [R0], y
	sta SpriteRamStart, x
	inx
	lda <R2
	sta SpriteRamStart, x

	inc <R4
	lda #8
	clc
	adc <R3
	sta <R3
	lda <R4
	asl a
	asl a
	tax
	lda <R3
	sta SpriteRamStart, x
	inx
	ldy #4
	lda [R0], y
	sta SpriteRamStart, x
	inx
	ldy #0
	lda [R0], y
	sta SpriteRamStart, x
	inx
	lda <R2
	sta SpriteRamStart, x

	inc <R4
	lda <R2
	sec
	sbc #8
	sta <R2
	lda <R4
	asl a
	asl a
	tax
	lda <R3
	sta SpriteRamStart, x
	inx
	ldy #3
	lda [R0], y
	sta SpriteRamStart, x
	inx
	ldy #0
	lda [R0], y
	sta SpriteRamStart, x

	inx
	lda <R2
	sta SpriteRamStart, x

	rts


DrawLogo:
	lda #low(LogoBG)
	sta <R0
	lda #high(LogoBG)
	sta <R1
	lda #LogoX / 8
	sta <R2
	lda #LogoY / 8
	sta <R3
	jsr DrawBGChr

	lda #low(Logo)
	sta <R0
	lda #high(Logo)
	sta <R1
	lda #LogoX
	sta <R2
	lda #LogoY
	sta <R3
	lda #LogoSP
	sta <R4
	jsr DrawSPChr

	lda #high($2000 + NameX + NameY * 32)
	sta $2006
	lda #low($2000 + NameX + NameY * 32)
	sta $2006
	ldx #0
drawLogo1:
	lda NameStr, x
	beq drawLogo2
	sta $2007
	inx
	bne drawLogo1
drawLogo2:
	
	lda #high($2000 + VersionX + VersionY * 32)
	sta $2006
	lda #low($2000 + VersionX + VersionY * 32)
	sta $2006
	ldx #0
drawLogo3:
	lda VersionStr, x
	beq drawLogo4
	sta $2007
	inx
	bne drawLogo3
drawLogo4:

	rts


PSGBeep:
	lda <ChannelSW
	beq psgBeepT
	lda $4015
	ora #1
	sta $4015
	BitAddR0S <DutyRatio, 2
	BitAddR0 <LenSW, 1
	BitAddR0 <DecaySW, 1
	BitAddR0 <DecayRatio, 4
	lda <R0
	sta $4000
	BitAddR0S <SweepSW, 1
	BitAddR0 <SweepRatio, 3
	BitAddR0 <SweepFlap, 1
	BitAddR0 <SweepLen, 3
	lda <R0
	sta $4001
	lda <FreqL
	sta $4002
	BitAddR0S <PlayLen, 5
	BitAddR0 <FreqH, 3
	lda <R0
	sta $4003
psgBeepT:
	lda <TriangleSW
	beq psgBeepN
	lda $4015
	ora #4
	sta $4015
	BitAddR0S <TCountSW, 1
	BitAddR0 <TLen, 7
	lda <R0
;	lda #%11111111
	sta $4008
	lda <TFreqL
;	lda #$80
	sta $400A
	BitAddR0S <TPlayLen, 5
	BitAddR0 <TFreqH, 3
	lda <R0
;	lda #%11111001 
	sta $400B
psgBeepN:
	lda <NoiseSW
	beq psgBeepE
	lda $4015
	ora #8
	sta $4015
	BitAddR0S <NNone, 2
	BitAddR0 <NLenSW, 1
	BitAddR0 <NDecaySW, 1
	BitAddR0 <NDecayRatio, 4
	lda <R0
;	lda #%11101111
	sta $400C
	BitAddR0S <NType, 1
	BitAddR0 <NNone2, 3
	BitAddR0 <NWaveLen, 4
	lda <R0
;	lda <VTime
	sta $400E
	BitAddR0S <NPlayLen, 5
	BitAddR0 <NNone3, 3
	lda <R0
;	lda #%11111111
	sta $400F
psgBeepE:
	BitAddR0S <NoiseSW, 1
	BitAddR0 <TriangleSW, 1
	BitAddR0 <ChannelSW, 2
	lda $4015
	and #$f0
;	and #$fe
	ora <R0
	sta $4015

	rts
;;
CheckID:
NameStr:
	.db "JRF", $0
VersionStr:
	.db "v"
	VERSION
	.db $0

ModeTable:
	.dw Start
	.dw MDInput

Key1FlagTable:
	.db 0		;;     
	.db 8 + 6	;;    R
	.db 8 + 2	;;   L 
	.db 0		;;   LR
	.db 8 + 0	;;  D  
	.db 8 + 7	;;  D R
	.db 8 + 1	;;  DL 
	.db 0		;;  DLR
	.db 8 + 4	;; U   
	.db 8 + 5	;; U  R
	.db 8 + 3	;; U L 
	.db 0		;; U LR
	.db 0		;; UD  
	.db 0		;; UD R
	.db 0		;; UDL 
	.db 0		;; UDLR

Key2FlagTable:
	.db 0		;;     
	.db 8 + 2	;;    R
	.db 8 + 6	;;   L 
	.db 0		;;   LR
	.db 8 + 0	;;  D  
	.db 8 + 1	;;  D R
	.db 8 + 7	;;  DL 
	.db 0		;;  DLR
	.db 8 + 4	;; U   
	.db 8 + 3	;; U  R
	.db 8 + 5	;; U L 
	.db 0		;; U LR
	.db 0		;; UD  
	.db 0		;; UD R
	.db 0		;; UDL 
	.db 0		;; UDLR

MenuItemStr:
	.db "ChannelSW:", $0
	.db "DutyRatio:", $0
	.db "LenSW:", $0
	.db "DecaySW:", $0
	.db "DecayRatio:", $0
	.db "SweepSW:", $0
	.db "SweepRatio:", $0
	.db "SweepFlap:", $0
	.db "SweepLen:", $0
	.db "FreqL:", $0
	.db "FreqH:", $0
	.db "PlayLen:", $0
	.db "TriangleSW:", $0
	.db "TCountSW:", $0
	.db "TLen:", $0
	.db "TFreqL:", $0
	.db "TFreqH:", $0
	.db "TPlayLen:", $0
	.db "NoiseSW:", $0
 	.db "NNone:", $0
	.db "NLenSW:", $0
	.db "NDecaySW:", $0
	.db "NDecayRatio:", $0
	.db "NType:", $0
	.db "NNone2:", $0
	.db "NWaveLen:", $0
	.db "NNone3:", $0
	.db "NPlayLen:", $0
	.db $00

PSGParamBitLen:
;; Square Wave.
;;ChannelSW:
	.db 1
;;DutyRatio:
	.db 2
;;LenSW:
	.db 1
;;DecaySW:
	.db 1
;;DecayRatio:
	.db 4
;;SweepSW:
	.db 1
;;SweepRatio:
	.db 3
;;SweepFlap:
	.db 1
;;SweepLen:
	.db 3
;;FreqL:
	.db 8
;;FreqH:
	.db 3
;;PlayLen:
	.db 5
;; Triangle Wave.
;;TriangleSW:
	.db 1
;;TCountSW:
	.db 1
;;TLen:
	.db 7
;;TFreqL:
	.db 8
;;TFreqH:
	.db 3
;;TPlayLen:
	.db 5
;; Noise.
;;NoiseSW:
	.db 1
;;NNone:
	.db 2
;;NLenSW:
	.db 1
;;NDecaySW:
	.db 1
;;NDecayRatio:
	.db 4
;;NType:
	.db 1
;;NNone2:
	.db 3
;;NWaveLen:
	.db 4
;;NNone3:
	.db 3
;;NPlayLen:
	.db 5

	
;; [FreqH][FreqL] = (1790000 / ([Hz] * 32)) - 1
;;
;; [TFreqH][TFreqL] = (1790000 / ([Hz] * 64)) - 1


;; パレットテーブル
Palettes:
	.incbin	"jrf_semaphore.dat"

;; キャラクター
Logo:	
	.db 0, $02, $03, $12, $13
LogoBG:	
	.db 2, $11, $11, $11, $11

;; パブリックドメインになった本の検印だからといって、誰もが使っていいわ
;; けではない。同様にこのロゴがどこかの画像に含まれていたからといって何
;; の問題もないが、それを「自分」の印として使うなら、その(宗教的な)意味
;; までよく考えほうがいい。

;; A seal or stamp on a page of public-domained books doesn't apply to
;; everybody's use.  Similarly, it is no problem for me to see this
;; logo anywhere else, but you had better to think its (religious)
;; meaning when using it as the seal of 'yourself'.

	
;; Help
Message:
	 ;;  0123456789ABCDEF0123456789ABCDEF
	.db "  U/D/B:Select   A:Play         "
	.db "  L/R/SELECT/START:Change       "
	.db $0

ZeroPageInitValue:
_BitSetTable:
	.db $01
	.db $02
	.db $04
	.db $08
	.db $10
	.db $20
	.db $40
	.db $80


_BitMaskTable:
	.db $01
	.db $03
	.db $07
	.db $0f
	.db $1f
	.db $3f
	.db $7f
	.db $ff

ZeroPageInitValueEnd:


;; パターンテーブル
	.bank 2
        .org    $0000
	.incbin	"jrf_semaphore.chr"
