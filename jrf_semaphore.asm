;;
;; jrf_semaphore.asm
;;
;; Flag Semaphore for NES ROM. Expecting assembler is NESASM.
;;
JRF_VERSION .macro  ;; Time-stamp: <2017-04-28T06:06:14Z>
	\1 "0.08"
	.endm
;;
;; License:
;;
;;   The author is a Japanese.
;;
;;   I intended this program to be public-domain, but you can treat
;;   this program under the (new) BSD-License or under the Artistic
;;   License, if it is convenient for you.
;;
;;   Within three months after the release of this program, I
;;   especially admit responsibility of efforts for rational requests
;;   of correction to this program.
;;
;;   I often have bouts of schizophrenia, but I believe that my
;;   intention is legitimately fulfilled.
;;
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

;; システムスイッチ
  .ifndef DebugLevel
DebugLevel = 0
  .endif
  .ifndef UseFont8x16
UseFont8x16 = 0			;; The bit:0 of SystemSwitch.
  .endif
  .ifndef UseToPrintable
UseToPrintable = 1		;; The bit:1 of SystemSwitch.
  .endif
  .ifndef UseRightToLeft
UseRightToLeft = 0		;; The bit:2 of SystemSwitch.
  .endif
  .ifndef UseMapper3
UseMapper3 = 1			;; The bit:4-5 of SystemSwitch.
  .endif
	
FontNameRes .macro
  .if \2 = 0
	\1 "jrf_semaphore.chr"
  .endif
  .if \2 = 1
	\1 "jrf_semaphore16a.chr"
  .endif
  .if \2 = 2
	\1 "jrf_semaphore_l1.chr"
  .endif
  .if \2 = 3
	\1 "jrf_semaphore16p.chr"
  .endif
  .if \2 = 4
	\1 "jrf_semaphore.chr"
  .endif
  .if \2 = 5
	\1 "jrf_semaphore16a.chr"
  .endif
  .if \2 = 6
	\1 "jrf_semaphore.chr"
  .endif
  .if \2 = 7
	\1 "jrf_semaphore16b.chr"
  .endif
  .if \2 > 7
	fail "There doesn't exists such a Font Name Resource."
  .endif
	.endm

        .inesprg    1
        .ineschr    4
;        .inesmir    2	;; Horizontal Mirroring + Battery ON
        .inesmir    3	;; Vertical Mirroring + Battery ON
  .if UseMapper3
        .inesmap    3	;; Mapper 3 only makes sense when using this
			;; as a text viewer with injection of saves.
  .else
	.inesmap    0   ;; No probrem with Mapper 0 in usual use.
  .endif


;; 定数
ClipX = 2
ClipY = 2
ClipCols = 22
;ClipRows = 14 * 2
MorseCodeLine = 13 * 2

CursorSP = 1

LogoX = 28 * 8
LogoY = 24 * 8
LogoSP = 4
NameX = (LogoX / 8) - 3
NameY = (LogoY / 8) + 1
VersionX = (LogoX / 8) - 3
VersionY = (LogoY / 8) + 3
Name8x16X = (LogoX / 8) - 3
Name8x16Y = (LogoY / 8) + 0
Version8x16X = (LogoX / 8) - 3
Version8x16Y = (LogoY / 8) + 2

SailorX = 26 * 8
SailorY = 12 * 8
FlagLSP = 8
FlagRSP = 12
SailorAnimUnit = 30

MPlayWait = 18
MPlayDot = 3

KeyStopUnit = 6
KeyLongUnit = KeyStopUnit * 4
KeyWaveUnit = KeyStopUnit * 3

MD_NONE = 0
MD_REINIT = 1
MD_INPUT = 2
MD_REPLAY = 3
MD_MORSEDOT = 4
MD_SHORTCANCEL = 5

CHR_NULL = $00
CHR_NULL2 = $03
CHR_REPLAY_NUM = $01
CHR_ACK = $06
CHR_REST = ' '
CHR_CANCEL = $08
CHR_ERROR = $18
CHR_START = $01
CHR_LETTER = $02
CHR_TERM = $04
;  if UseFont8x16
CHR_MORSE_DOT = '.'
CHR_MORSE_DASH = $2d
CHR_MORSE_SPC = '#'
CHR_MORSE_UBAR = '_'
CHR_MORSE_AMP = '&'
CHR_MORSE_DOL = '$'
;  else
;CHR_MORSE_DOT = $A4
;CHR_MORSE_DASH = $2d
;CHR_MORSE_SPC = $10
;CHR_MORSE_UBAR = '_'
;CHR_MORSE_AMP = '&'
;CHR_MORSE_DOL = '$'
;  endif

FlagInvNull = $00 + $88
FlagInvDot = $04 + $88
FlagInvDash = $06 + $88
FlagInvSpace = $77 + $88
FlagInvCancel = $31 + $88
FlagInvNumStart = $43 + $88
FlagInvLetterStart = $42 + $88
FlagInvAck = $30 + $88

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


Halt	.macro
L\@:
	jmp L\@
	.endm


EnableNMI .macro
	lda <SystemSwitch
	ror a
	lda #$80	;; スプライトと BG は同じパターン。
	bcc L\@
	lda #$90	;; スプライトと BG は別。
L\@	
	sta $2000
	.endm

DisableNMI .macro
	lda <SystemSwitch
	ror a
	lda #$00
	bcc L\@
	lda #$10
L\@	
;	lda #$00
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

SetScroll .macro
	lda <ScrollX
	sta $2005
	lda <ScrollY
	sta $2005
	.endm


ToUpperCase .macro
	cmp #'a'
	bcc L\@
	cmp #'z' + 1
	bcs L\@
	clc
	adc #'A' - 'a'
L\@:
	.endm


ToLowerCase .macro
	cmp #'A'
	bcc L\@
	cmp #'Z' + 1
	bcs L\@
	clc
	adc #'a' - 'A'
L\@:
	.endm


ToHexCharA .macro
	clc
	adc #'0'
	cmp #'0' + 10
	bcc L\@
	adc #'A' - '0' - 1 - 10
L\@:
	.endm


ToNumCode .macro
;	ToLowerCase
	cmp #'k'
	bne L1\@
	lda #'0'
	sec
	jmp L\@
L1\@:
	cmp #'a'
	bcc L2\@
	cmp #'i' + 1
	bcs L2\@
	clc
	adc #'1' - 'a'
	bcs L\@
L2\@:
	clc
L\@:
	.endm


ToPrintableA .macro
	cmp <ToPrintableFirst
	bcc L\@
	cmp <ToPrintableLast
	bcc L1\@
	beq L1\@
L\@:
	lda <ToPrintableChrNon
L1\@:
	.endm


SetBitXA .macro
	lda <BitSetTable, x
	.endm

MaskBitXA .macro
	lda <BitMaskTable, x
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

SetTextRefresh .macro
	lda <RefreshFlag
	ora #$20
	sta <RefreshFlag
	.endm


	.list
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
Key1Now:
	.ds 1
Key1Push:
	.ds 1
Key1Release:
	.ds 1
Key2Now:
	.ds 1
Key2Push:
	.ds 1
Key2Release:
	.ds 1
KeyD:		;; Direction Key
	.ds 1
KeyC:		;; Command Key
	.ds 1
KeyDCur:
	.ds 1
KeyCCur:
	.ds 1
KeyDTime:
	.ds 1
KeyCTime:
	.ds 1

MainMode:
	.ds 1
RefreshFlag:  ;; bits: 0-3:(Reserved), 4:BGCol, 5:Text, 6: Sprite DMA.
	.ds 1
ScrollX:
	.ds 1
ScrollY:
	.ds 1
Key1Wave:
	.ds 1
Key1WaveTime:
	.ds 1
Key2Wave:
	.ds 1
Key2WaveTime:
	.ds 1
TextLen:
	.ds 1
SailorFont:
	.ds 1
SailorColor:
	.ds 1
SailorAnimCount:
	.ds 1
SailorAnimTime:
	.ds 1
SailorAnimLen = 9 + 1
SailorAnim:
	.ds SailorAnimLen
FontColorBuf:
	.ds 1
NumCodeBufLen = 4 + 1
NumCodeBuf:
	.ds NumCodeBufLen
MorseCodeBufLen = 9 + 1
MorseCodeBuf:
	.ds MorseCodeBufLen
LineBuf
	.ds ClipCols
ReplayCursor:
	.ds 1
MPlayTime:
	.ds 1
MPlayCount:
	.ds 1
MPlayBufLen = 8 + 1 + 8 + 1 + 1
MPlayBuf:
	.ds MPlayBufLen
ReplayInitialCount:
	.ds 1
ReplayTerminalCount:
	.ds 1
LoadedSwitch:
	.ds 1
SaveWait:
	.ds 1
BitsPoint:
	.ds 2
BitsMark:
	.ds 2
ToPrintableFirst:
	.ds 1
ToPrintableLast:
	.ds 1
ToPrintableChrNon:
	.ds 1


ZeroPageWithInitValue:
SystemSwitch:
	.ds 1
BankMask:
	.ds 1
RandPrime:
	.ds 1
LoadCost:
	.ds 1
UBarMorseCodeLen:
	.ds 1
DisplayChr:
	.ds 6
ChrMorseDot = DisplayChr + 0
ChrMorseDash = DisplayChr + 1
ChrMorseSpc = DisplayChr + 2
ChrMorseUBar = DisplayChr + 3
ChrMorseAmp = DisplayChr + 4
ChrMorseDol = DisplayChr + 5

BitSetTable:
	.ds 8
BitMaskTable:
	.ds 8
ZeroPageEnd:
  .if ZeroPageEnd >= $100
	fail "ZeroPage must be < $100."
  .endif


Stack = $0100

	org $0200
UserRamStart:

	.org $0300
SpriteRamStart:
	.ds $100

	.org $0400
TextBuf:
	.ds $100
BitsBuf:
	.ds $100
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
	lda <SystemSwitch
	and #%11101111
	sta <SystemSwitch

	;; おまじない。
;	lda #$40
;	sta $4017

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
	lda Palette, x
	sta $2007
	inx
	dey
	bne initPal

	jsr SetBank
	jsr SetScrollY
	jsr InitBuf
	jsr Cls
	jsr InitTextArea

  if DebugLevel > 0
;; ネームテーブルへ転送(画面の中央付近) # for Debug
	lda #$21
	sta $2006
	lda #$c9
	sta $2006
	ldx #$00
	ldy #$0d		;; 13文字表示
	sty <TextLen
copyMap:
	lda HELLO_STRING, x
	sta $2007
	sta TextBuf, x
	inx
	dey
	bne copyMap
  endif

	jsr DrawLogo
	jsr DrawSailor
	lda #FlagInvAck
	sta <SailorAnim
	lda #CHR_TERM
	sta <SailorAnim + 1
	lda #SailorAnimUnit
	sta <SailorAnimTime
	lda #0
	sta <SailorAnimCount
	jsr ShowFlag
	jsr ShowCursor

	lda #$50
	ora <RefreshFlag
	sta <RefreshFlag

;; スクリーンオン
	DisableNMI
	EnableScreen
	
	lda #0
	sta MainMode

	lda #0
	sta <Key1Push
	sta <Key2Push
	lda #$ff
	sta <Key1Release
	sta <Key2Release

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
	jsr GetKey
	WaitVBlank
	sei
	DisableNMI
	ldx MainMode
	beq MainLoop
	lda #0
	sta MainMode
	txa
	SwitchA ModeTable

GetKey:
	jsr ReadKey
	lda <KeyC
	beq getKey2
	cmp <KeyCCur
	bne getKeyN
getKey2:
	lda <KeyD
	beq getKey3
	cmp <KeyDCur
	bne getKeyN
getKey3:
	lda <Key1Release
	sta <Key1Push
	lda <Key2Release
	sta <Key2Push
	jsr ReadKey
getKeyN:
	jsr ParseKey
	lda <Key1Now
	sta <Key1Release
	lda <Key2Now
	sta <Key2Release
	lda #0
	sta <Key1Push
	sta <Key2Push
	rts

MDReplay:
	jsr FlagBeep
	lda <LoadCost
	pha
	sta <SaveWait
	bmi mdReplayS1
	jsr SaveBackUp
mdReplayS1:
	jsr Replay
	pla
	bpl mdReplayS2
	jsr SaveBackUp
mdReplayS2:
	SetTextRefresh
	lda #0
	sta <MainMode
	jmp MainLoop


replayLoopE:
	lda #$88
	sta <SailorAnim
	lda #FlagInvAck
	sta <SailorAnim + 1
	lda #CHR_TERM
	sta <SailorAnim + 2
	lda #SailorAnimUnit
	sta <SailorAnimTime
	lda #0
	sta <SailorAnimCount
	sta <MorseCodeBuf
	sta <NumCodeBuf
	jsr ShowFlag
	jsr ShowCursor
	jsr MorseBeepOff
	rts

Replay:
	lda #0
	sta <MainMode
	sta <MorseCodeBuf
	sta <NumCodeBuf
	sta <MPlayTime
	sta <ReplayCursor
	sta <ReplayInitialCount
	sta <ReplayTerminalCount
	sta <SailorAnimTime
	sta <Key1Push
	sta <Key2Push
	lda #$ff
	sta <Key1Release
	sta <Key2Release
	jsr RefreshText
	lda <TextLen
	pha
	lda <ReplayCursor
	sta <TextLen
	jsr ShowCursor
	pla
	sta <TextLen

replayLoop:
	jsr CheckKey
	WaitVScan
	SetScroll
	jsr CheckKey
	lda #MD_REPLAY
	sta <MainMode
	jsr GetKey
	lda <KeyD
	ora <KeyC
	beq replayLoopNK
	lda <MainMode
	cmp #MD_INPUT
	bne replayLoopNK
	ldx <ReplayInitialCount
	lda ReplayInitial, x
	bne replayLoopNKE
	lda <SaveWait
	bne replayLoopNKE
	jmp replayLoopE
replayLoopNKE:
	jsr ErrorBeep
replayLoopNK:
	WaitVBlank

	lda #1
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
	and <VTime
	bne replayLoopVE
	lda SpriteRamStart + CursorSP * 4 + 1
	eor #$10
	sta SpriteRamStart + CursorSP * 4 + 1
replayLoopVE:
	lda	#$3	;; スプライト DMA 設定
	sta	$4014
	
;	jsr RefreshText ;; debug

	ldy #0
	lda <MPlayTime
	beq replayLoopM0
	dec <MPlayTime
	bne replayLoopM1
	ldx <MPlayCount
	lda <MPlayBuf, x
	bne replayLoopM2
replayLoopM0:
	iny
	jmp replayLoopM1
replayLoopM2:
	inc <MPlayCount
	tya
	pha
	ldx <MPlayCount
	lda <MPlayBuf, x
	beq replayLoopM4
	cmp #' '
	beq replayLoopM3
	jsr MorseBeepOn
replayLoopM3:
	lda #MPlayWait
	sta <MPlayTime
replayLoopM4:
	pla
	tay
	jmp replayLoopM6
replayLoopM1:
	ldx <MPlayCount
	lda <MPlayBuf, x
	tax
	lda <MPlayTime
	cpx #'.'
	bne replayLoopM5
	cmp #MPlayWait - MPlayDot
	beq replayLoopMOFF
	bne replayLoopM6
replayLoopM5:
	cpx #'_'
	bne replayLoopM6
	cmp #MPlayDot
	bne replayLoopM6
replayLoopMOFF:
	jsr MorseBeepOff
replayLoopM6:

	iny
	lda <SailorAnimTime
	beq replayLoopAE
	dey
	dec <SailorAnimTime
	bne replayLoopAE
	iny
	ldx <SailorAnimCount
	lda <SailorAnim, x
	beq replayLoopAE
	cmp #CHR_TERM
	beq replayLoopAE
	inc <SailorAnimCount
	ldx <SailorAnimCount
	lda <SailorAnim, x
	beq replayLoopAE
	cmp #CHR_TERM
	beq replayLoopAE
	dey
	lda #SailorAnimUnit
	sta <SailorAnimTime
	jsr ShowFlag
replayLoopAE:

	cpy #2
	beq replayLoopMain
	jmp replayLoop
replayLoopMainE:
	lda #1
	sta <LoadCost
	jmp replayLoopE

replayLoopTerm:	
	lda <ReplayTerminalCount
	bne replayLoopMainE
	inc <ReplayTerminalCount
	lda #0
	sta <R2
	lda #%000101	;; CHR_TERM
	ldy #6
	jsr SetMorseCodePlay
	lda #$00 + $88
	sta <SailorAnim
	lda #$44 + $88
	sta <SailorAnim + 1
	lda #$0
	sta <SailorAnim + 2
	ldx #LogoX / 8
	ldy #LogoY / 8
	jsr SetCursor
	jmp replayLoopMainICE	

replayLoopMain:
	lda <SaveWait
	beq replayLoopMainNSW
	bmi replayLoopMainSW1
	dec <SaveWait
	jmp replayLoopMainNSW
replayLoopMainSW1:
	inc <SaveWait
replayLoopMainNSW:

	ldx <ReplayInitialCount
	lda ReplayInitial, x
	beq replayLoopMainNI
	sta <R0
	inc <ReplayInitialCount
	ldx #LogoX / 8
	ldy #LogoY / 8
	jsr SetCursor
	jmp replayLoopMainIC
	
replayLoopMainNI:
	lda <ReplayCursor
	cmp <TextLen
	beq replayLoopTerm

	lda <TextLen
	pha
	lda <ReplayCursor
	sta <TextLen
	jsr ShowCursor
	pla
	sta <TextLen
	inc <ReplayCursor

	ldx <ReplayCursor
	dex
	lda TextBuf, x
	sta <R0

replayLoopMainIC:
	jsr ReplayLoopM
	ldx #0
	jsr ReplayLoopF
	lda #0
	sta <LineBuf, x
	jsr ReplayLoopT

replayLoopMainICE:
	lda #SailorAnimUnit
	sta <SailorAnimTime
	lda #MPlayWait
	sta <MPlayTime
	lda #0
	sta <SailorAnimCount
	sta <MPlayCount
	jsr ShowFlag
	lda <MPlayBuf
	cmp #' '
	beq replayLoopNBE
	jsr MorseBeepOn
replayLoopNBE:
	jmp replayLoop


ReplayLoopF:
	lda <R0
	cmp #'a'
	bcc replayLoopFNL
	cmp #'z' + 1
	bcs replayLoopFNL
	lda <NumCodeBuf
	cmp <ChrMorseDol
	bne replayLoopFL1
	lda #'j'
	sta <LineBuf, x
	inx
	lda #0
	sta <NumCodeBuf
replayLoopFL1:
	lda <R0
	sta <LineBuf, x
	inx
	rts

replayLoopFNL:
	cmp #'A'
	bcc replayLoopFNU
	cmp #'Z' + 1
	bcs replayLoopFNU
	lda <NumCodeBuf
	cmp <ChrMorseDol
	bne replayLoopFU1
	lda #'j'
	sta <LineBuf, x
	inx
	lda #0
	sta <NumCodeBuf
replayLoopFU1:
	lda #'_'
	sta <LineBuf, x
	inx
	lda <R0
	ToLowerCase
	sta <LineBuf, x
	inx
	rts

replayLoopFNU:
	cmp #'.'
	beq replayLoopFP1
	cmp #','
	bne replayLoopFNP
replayLoopFCM:
	lda #'_'
	sta <LineBuf, x
	inx
	lda #' '
	sta <LineBuf, x
	inx
	rts
replayLoopFP1:
	lda #'_'
	sta <LineBuf, x
	inx
	lda #'.'
	sta <LineBuf, x
	inx
	rts

replayLoopFNP:
	cmp #'0'
	bcc replayLoopFNN
	cmp #'9' + 1
	bcs replayLoopFNN
	lda <NumCodeBuf
	cmp <ChrMorseDol
	beq replayLoopFN1
	lda #'$'
	sta <LineBuf, x
	inx
	lda <ChrMorseDol
	sta <NumCodeBuf
	lda #0
	sta <NumCodeBuf + 1
replayLoopFN1:
	lda #'_'
	sta <LineBuf, x
	inx
	lda <R0
	clc
	adc #'a' - '1'
	cmp #'a' - '1' + '0'
	bne replayLoopFN2
	lda #'k'
replayLoopFN2:
	sta <LineBuf, x
	inx
	rts

replayLoopFNN:
	cmp #' '
	bne replayLoopFNS
	sta <LineBuf, x
	inx
	rts

replayLoopFNS:
	lda <NumCodeBuf
	cmp <ChrMorseDol
	beq replayLoopFC1
	lda #'$'
	sta <LineBuf, x
	inx
	lda <ChrMorseDol
	sta <NumCodeBuf
	lda #0
	sta <NumCodeBuf + 1
replayLoopFC1:
	lda #CHR_REPLAY_NUM
	sta <LineBuf, x
	inx
	lda <R0
	sta <LineBuf, x
	inx
	rts


SetSailorAnim .macro
	;; stack <- string ends $0, R1 <- SailorAnimLen, R3 <- Prev
	ldx <R1
L1\@:
	pla
	beq LE\@
	cmp <R3
	bne L2\@
	pha
	lda #$88
	sta <SailorAnim, x
	inx
	pla
L2\@:
	sta <SailorAnim, x
	sta <R3
	inx
	jmp L1\@
LE\@:
	stx <R1
	lda #0
	sta <SailorAnim, x
	.endm


ReplayLoopT:
	lda #0
	tay
	sta <R1
	ldx <SailorAnimCount
	dex
	lda <SailorAnim, x
	sta <R3
replayLoopTLP:
	lda LineBuf, y
	bne replayLoopTNE
	rts
replayLoopTNE:
	iny
	sta <R0
	cmp #CHR_REPLAY_NUM
	beq replayLoopTA
	jmp replayLoopTNA
replayLoopTA:
	lda #0
	 pha
	lda LineBuf, y
	iny
	sta <R0
	and #$7
	tax
	lda FlagInvNum, x
	 pha
	lda <R0
	ldx #'8'
	cmp #$40
	beq replayLoopTA2
	cmp #$58
	bcc replayLoopTA3
	cmp #$5f + 1
	bcs replayLoopTA2
replayLoopTA3:
	ldx #'9'
	cmp #$60
	beq replayLoopTA2
	cmp #$78
	bcc replayLoopTA4
	cmp #$7f + 1
	bcs replayLoopTA2
replayLoopTA4:
	lsr a
	lsr a
	lsr a
	clc
	adc #'4' - 4
	tax
	lda <R0
	cmp #$30
	bcc replayLoopTA5
	cmp #$77 + 1
	bcs replayLoopTA2
replayLoopTA5:
	and #%00111000
	lsr a
	lsr a
	lsr a
	tax
	lda FlagInvNum, x
	 pha
	lda <R0
	and #%11000000
	clc
	rol a
	rol a
	rol a
	tax
	lda FlagInvNum, x
	 pha
	jmp replayLoopTAE
replayLoopTA2:
	txa
	sec
	sbc #'0'
	tax
	lda FlagInvNum, x
	 pha
replayLoopTAE:
	SetSailorAnim
	jmp replayLoopTLP

replayLoopTNA:
	ldx #$77 + $88
	cmp #' '
	beq replayLoopTI
	ldx #$06 + $88
	cmp #'_'
	beq replayLoopTI
	ldx #$43 + $88
	cmp #'$'
	beq replayLoopTI
	ldx #$60 + $88
	cmp #'&'
	beq replayLoopTI
	ldx #$04 + $88
	cmp #'.'
	beq replayLoopTI
	cmp #'0'
	bcc replayLoopTE
	cmp #'9' + 1
	bcc replayLoopTN
	cmp #'a'
	bcc replayLoopTE
	cmp #'z' + 1
	bcc replayLoopTL
replayLoopTE:
	ldx <R1
	lda #$88
	sta <SailorAnim, x
	inx
	lda #$99
	sta <SailorAnim, x
	inx
	lda #$aa
	sta <SailorAnim, x
	inx
	lda #$99
	sta <SailorAnim, x
	inx
	lda #$88
	sta <SailorAnim, x
	inx
	lda #$99
	sta <SailorAnim, x
	inx
	lda #$aa
	sta <SailorAnim, x
	inx
	lda #$0
	sta <SailorAnim, x
	stx <R1
	jmp replayLoopTLP
replayLoopTI:
	lda #0
	pha
	txa
	pha
	SetSailorAnim
	jmp replayLoopTLP
replayLoopTN:
	sec
	sbc #'0'
	tax
	lda FlagInvNum, x
	tax
	jmp replayLoopTI
replayLoopTL:
	sec
	sbc #'a'
	tax
	lda FlagInvLetter, x
	tax
	jmp replayLoopTI


SetMorseCodePlay:
	;; a <- bits, y <- length, R2 <- MPlayLen
	tax
	lda <R0
	pha

	stx <R0
	tya
	sec
	adc <R2
	sta <R2
	ldx <R2
	lda #0
	sta <MPlayBuf, x
	lda #' '
	sta <MPlayBuf - 1, x
	dex
.L0:
	lsr <R0
	bcc .L1
	lda #'_'
	sta <MPlayBuf - 1, x
	dex
	dey
	bne .L0
	beq .L2
.L1:
	lda #'.'
	sta <MPlayBuf - 1, x
	dex
	dey
	bne .L0
.L2:

	pla
	sta <R0
	rts


ReplayLoopM:
	lda #0
	sta <R2

	lda <R0
	ldx #0
replayLoopMUB0:
	cmp UBarMorseCodeT, x
	beq replayLoopMUB1
	inx
	cpx <UBarMorseCodeLen
	bne replayLoopMUB0
	beq replayLoopMUB2
replayLoopMUB1:
	lda UBarMorseCode, x
	tax
	jmp replayLoopMUB
replayLoopMUB2

	cmp #'a'
	bcc replayLoopMU
	cmp #'z' + 1
	bcs replayLoopMU
	clc
	adc #'A' - 'a'
	jmp replayLoopMNU
replayLoopMU:
	cmp #'A'
	bcc replayLoopMNU
	cmp #'Z' + 1
	bcs replayLoopMNU
	tax
replayLoopMUB:
	txa
	pha
	lda #%001101	;; Morse Code of '_'
	ldy #6
	jsr SetMorseCodePlay
	pla
replayLoopMNU:
	cmp #$20
	beq replayLoopMS
	cmp #$20
	bcc replayLoopMB
	cmp #$5f + 1
	bcs replayLoopMB
	sec
	sbc #$20
	asl a
	tax
	lda MorseCodeLetterTable, x
	beq replayLoopME
	tay
	lda MorseCodeLetterTable + 1, x
	jsr SetMorseCodePlay
	rts

replayLoopME:
	jsr ErrorBeep		;; Why?!
	rts

replayLoopMS:
	lda #' '
	ldx <R2
	sta <MPlayBuf, x
	sta <MPlayBuf + 1, x
	sta <MPlayBuf + 2, x
	lda #$0
	sta <MPlayBuf + 3, x
	lda <R2
	clc
	adc #3
	sta <R2
	rts

replayLoopMB:
	ldy #5
	lda #%01000
	jsr SetMorseCodePlay
	lda <R0
	ldy #8
	jsr SetMorseCodePlay
	rts



MDReinit:
	WaitVScan
	SetScroll
	jsr CheckKey
	WaitVBlank
	jsr DrawSailor
	lda #FlagInvAck
	sta <SailorAnim
	lda #CHR_TERM
	sta <SailorAnim + 1
	lda #SailorAnimUnit
	sta <SailorAnimTime
	lda #0
	sta <SailorAnimCount
	jsr ShowFlag
	jsr ShowCursor

	WaitVScan
	SetScroll
	jsr CheckKey

	lda #$70
;	lda #$50
	ora <RefreshFlag
	sta <RefreshFlag
	lda #0
	sta MainMode
	jmp MainLoop

MDInput:
	lda <KeyCCur
	and #$80
	beq mdInput1
	lda <KeyCCur
	and #$30
	lsr a
	lsr a
	lsr a
	lsr a
	jmp mdInput2
mdInput1:
	lda <KeyCCur
	and #$08
	beq mdInput3
	lda <KeyCCur
	and #$03
	ora #$04
mdInput2:
	SwitchA SpecialKeyTable
mdInput3:
	
	ldy #0
	lda <Key1Wave
	beq mdInput3KW1
	and #%11100000
	bne mdInput3KW1
	iny
mdInput3KW1:
	lda <Key2Wave
	beq mdInput3KW2
	and #%11100000
	bne mdInput3KW2
	iny
mdInput3KW2:
	cpy #2
	bne mdInput3NW
	lda #CHR_ERROR
	jmp mdInputCtrl
mdInput3NW:
	tya
	beq mdInputK
	jmp MainLoop

mdInputK:
	lda <KeyDCur
	and #$7
	sta <R0
	lda <KeyDCur
	and #$70
	lsr a
	ora <R0
	sta <R0

	pha
	jsr mdInputBits
	pla

	tax
	lda FlagCode, x
	ToLowerCase
	sta <R0
	ldy <NumCodeBuf
	cmp #'.'
	beq mdInputNum0D
	cpy <ChrMorseDot
	bne mdInputNum0NM
	ldx <ChrMorseDash
	cmp #'_'
	beq mdInputNum0MI
	cmp #'f'
	beq mdInputNum0MI
	cmp #$00
	bne mdInputNum0NMD
	jsr MorseBeepDot
	lda <ChrMorseDot
	bne mdInputNum0MI1
mdInputNum0MI:
	jsr MorseBeepDash
	lda <ChrMorseDash
mdInputNum0MI1:
	jsr InputMorse
	lda #0
	sta <NumCodeBuf
	jmp MainLoop
mdInputNum0D:
	cpy <ChrMorseUBar
	beq mdInputNum0N
	ldx <NumCodeBuf
	beq mdInputNum0DNN
	ldx <NumCodeBuf + 1
	cpx <ChrMorseUBar
	beq mdInputNum0NM
mdInputNum0DNN:
	cpy <ChrMorseDot
	bne mdInputNum0DM
	lda <ChrMorseDot
	jsr InputMorse
	jsr MorseBeepDot
mdInputNum0DM:
	lda <ChrMorseDot
	sta <NumCodeBuf
	lda #0
	sta <NumCodeBuf + 1
	SetTextRefresh
	jsr FlagBeep
	jmp MainLoop
mdInputNum0NMD:
	lda <ChrMorseDot
	jsr InputMorse
	jsr MorseBeepDot
mdInputNum0NM:
	pha
	jsr CheckMorseCodeBuf
	pla
	sta <R0
	ldy <NumCodeBuf
	cmp #$20
	bcc mdInputNum0
	cmp #'?'
	beq mdInputNum0E
	cpy <ChrMorseAmp
	beq mdInputNum1
	cpy <ChrMorseDol
	bne mdInputNum0N
	cmp #'j'
	bne mdInputNum1
	lda #CHR_LETTER
mdInputNum0:
	jmp mdInputCtrl
mdInputNum0N:
	jmp mdInputNNum
mdInputNum0E:
	jmp mdInputErr
mdInputNum1:
	ldy <NumCodeBuf + 1
	cpy <ChrMorseUBar
	bne mdInputNum1NU
	ldx #'.'
	cmp #'.'
	beq mdInputNum1Let
	ldx #','
	cmp #' '
	beq mdInputNum1Let
	ToNumCode
	bcc mdInputNum0E
	tax
mdInputNum1Let:
	lda #0
	sta <NumCodeBuf + 1
	lda <NumCodeBuf
	cmp <ChrMorseDol
	beq mdInputNum1Let2
	lda #0
	sta <NumCodeBuf
mdInputNum1Let2:
	txa
	jmp mdInputChr
mdInputNum1NU:
	cmp #'_'
	bne mdInputNum2
	lda <NumCodeBuf + 1
	bne mdInputNum0E
mdInputNum3:
	lda <ChrMorseUBar
	sta <NumCodeBuf + 1
	lda #0
	sta <NumCodeBuf + 2
	SetTextRefresh
	jmp MainLoop
mdInputNum2:
	cmp #' '
	bne mdInputNum5
	ldx #' '
	cpy #0
	beq mdInputNum1Let
mdInputNum5E:
	jmp mdInputErr
mdInputNum5:
	ToNumCode
	bcc mdInputNum5E
	sta <R0
	lda <NumCodeBuf + 1
	bne mdInputNum4
	lda <R0
	sta <NumCodeBuf + 1
	lda #0
	sta <NumCodeBuf + 2
	SetTextRefresh
	jmp MainLoop
mdInputNum4:
	cmp #'4'
	bcc mdInputNumL
	sbc #'0'
	cmp #8
	bcc mdInputNum7
	sta <R1
	lda #'0'
	sbc <R0
	beq mdInputNum8
	lda #$3
mdInputNum8:
	ora <R1
mdInputNum7:
	asl a
	asl a
	asl a
	sta <R1
	lda #0
	sta <NumCodeBuf + 1
	lda <NumCodeBuf
	cmp <ChrMorseDol
	beq mdInputNum7D
	lda #0
	sta <NumCodeBuf
mdInputNum7D:	
	lda <R0
	sec
	sbc #'0'
	clc
	adc <R1
	jmp mdInputChr
mdInputNumL:
	lda <NumCodeBuf + 2
	bne mdInputNumL1
	lda <R0
	sta <NumCodeBuf + 2
	lda #0
	sta <NumCodeBuf + 3
	SetTextRefresh
	jmp MainLoop
mdInputNumL1:
	lda <NumCodeBuf + 1
	sec
	sbc #'0'
	asl a
	asl a
	asl a
	sta <R1
	lda <NumCodeBuf + 2
	sec
	sbc #'0'
	clc
	adc <R1
	asl a
	asl a
	asl a
	sta <R1
	lda #0
	sta <NumCodeBuf + 1
	lda <NumCodeBuf
	cmp <ChrMorseDol
	beq mdInputNumL1D
	lda #0
	sta <NumCodeBuf
mdInputNumL1D:	
	lda <R0
	sec
	sbc #'0'
	clc
	adc <R1
	jmp mdInputChr

mdInputNNum:
	cmp #'$'
	bne mdInputNNum1
	cpy <ChrMorseUBar
	beq mdInputNNum1
	jmp mdInputCtrlNum
mdInputNNum1:
	cmp #'&'
	bne mdInputNNum2
	cpy <ChrMorseUBar
	beq mdInputNNum2
	jmp mdInputCtrlAmp
mdInputNNum2:
	cmp #'_'
	bne mdInputLet
	cpy #0
	bne mdInputLet
	lda <ChrMorseUBar
	sta <NumCodeBuf
	lda #0
	sta <NumCodeBuf + 1
	SetTextRefresh
	jsr FlagBeep
	jmp MainLoop
mdInputLet:
	cpy <ChrMorseUBar
	bne mdInputChr
	ldx #0
	stx <NumCodeBuf
	ToUpperCase
	cmp #' '
	bne mdInputChr
	lda #','
mdInputChr:
	jsr InsertText
	SetTextRefresh
	jsr ShowCursor
	jsr FlagBeep
	jmp MainLoop

mdInputCtrl:
	tax
	bne mdInputCtrl1
	lda #$88
	sta <SailorAnim
	lda #CHR_TERM
	sta <SailorAnim + 1
	lda #0
	sta <SailorAnimCount
	lda #SailorAnimUnit
	sta <SailorAnimTime
	jsr ShowFlag
	lda <RefreshFlag
	ora #$40
	sta <RefreshFlag
	jmp MainLoop

mdInputCtrl1:
	cmp #CHR_ERROR
	bne mdInputCtrl2
	SetTextRefresh
	jsr FlagBeep
	lda <NumCodeBuf
	beq mdInputCtrl1A
	lda #0
	sta <NumCodeBuf
	jmp MainLoop
mdInputCtrl1A:
	jsr DeleteWordText
	jsr ShowCursor
	jmp MainLoop

mdInputCtrl2:	
	cmp #CHR_LETTER
	bne mdInputCtrl4
	lda #0
	sta <NumCodeBuf
	SetTextRefresh
	jsr FlagBeep
	jmp MainLoop

;mdInputCtrl3:	
;	cmp #'$'
;	bne mdInputCtrl4
mdInputCtrlNum:
	lda <ChrMorseDol
	sta <NumCodeBuf
	lda #0
	sta <NumCodeBuf + 1
	SetTextRefresh
	jsr FlagBeep
	jmp MainLoop

mdInputCtrlAmp:
	lda <ChrMorseAmp
	sta <NumCodeBuf
	lda #0
	sta <NumCodeBuf + 1
	SetTextRefresh
	jsr FlagBeep
	jmp MainLoop
	
mdInputCtrl4:	
	cmp #CHR_CANCEL
	bne mdInputCtrl5
	SetTextRefresh
	jsr FlagBeep
	lda <NumCodeBuf
	bne mdInputCtrl4A
	lda <MorseCodeBuf
	bne mdInputCtrl4A
	jsr BackspaceText
	jsr ShowCursor
	jmp MainLoop
mdInputCtrl4A:
	lda #0
	sta <NumCodeBuf
	lda #0
	sta <MorseCodeBuf
	jmp MainLoop

mdInputCtrl5:
	cmp #CHR_NULL2
	bne mdInputCtrl6
	ldx #0
mdInputCtrl5A:	
	lda <MorseCodeBuf, x
	beq mdInputCtrl5B
	cmp <ChrMorseSpc
	bne mdInputCtrl5C
	lda #0
	sta <MorseCodeBuf, x
	SetTextRefresh
mdInputCtrl5B:	
	jmp MainLoop
mdInputCtrl5C:	
	inx
	cpx #MorseCodeBufLen
	beq mdInputCtrl5B
	jmp mdInputCtrl5A

mdInputCtrl6:
mdInputErr:
	jsr ErrorBeep
	jmp MainLoop

InputMorse:
	pha
	lda <MorseCodeBuf
	beq mdInputMorse1
	cmp <ChrMorseDot
	beq mdInputMorse1
	cmp <ChrMorseDash
	beq mdInputMorse1
	cmp <ChrMorseSpc
	bne mdInputMorse1S
	lda #0
	sta <MorseCodeBuf
mdInputMorse1S:
	lda <MorseCodeBuf + 1
	cmp <ChrMorseSpc
	bne mdInputMorse1
	ldy #$20
	lda <MorseCodeBuf
	beq mdInputMorse1I
	ldy #'&'
	cmp <ChrMorseAmp
	beq mdInputMorse1I
	ldy #'_'
	cmp <ChrMorseUBar
	beq mdInputMorse1I
	ldy #$0
mdInputMorse1I:
	tya
	jsr InsertText
	SetTextRefresh
	jsr ShowCursor
	lda #0
	sta <MorseCodeBuf
mdInputMorse1:
	ldx #0
mdInputMorse2:
	lda <MorseCodeBuf, x
	beq mdInputMorse3
	inx
	cpx #MorseCodeBufLen - 1
	bne mdInputMorse2
	lda #$0
	sta <MorseCodeBuf
	SetTextRefresh
	jsr ErrorBeep
	pla
	rts
mdInputMorse3:
	pla
	sta <MorseCodeBuf, x
	lda #0
	sta <MorseCodeBuf + 1, x
	SetTextRefresh
	rts

CheckMorseCodeBuf:
	;; 前がモールス信号だったら、バッファの最初が ' ' のはず。
	;; その後モールス信号の入力がないとバッファに３つまで ' ' を挿入。
	lda <MorseCodeBuf
	beq mdInput3NM
	cmp <ChrMorseDash
	beq mdInput3M
	cmp <ChrMorseDot
	beq mdInput3M
	ldx #$1
	lda <MorseCodeBuf, x
	beq mdInput3MS
	cmp <ChrMorseDash
	beq mdInput3M
	cmp <ChrMorseDot
	beq mdInput3M
	ldx #$2
	lda <MorseCodeBuf, x
	beq mdInput3MS
	bne mdInput3NM
mdInput3M:
	jsr ParseMorseCode
	ldx #$0
	lda <MorseCodeBuf
	bne mdInput3NM
mdInput3MS:
	lda <ChrMorseSpc
	sta <MorseCodeBuf, x
	lda #$00
	sta <MorseCodeBuf + 1, x
	sta <MorseCodeBuf + 2, x
	SetTextRefresh
mdInput3NM:
	rts

mdInputBits:
	sta <R0
	ldy <NumCodeBuf
	cpy <ChrMorseAmp
	bne mdInputBitsNA
	cmp #%00000111
	bne mdInputBitsA1
	lda #$8
	ora <BitsPoint
	sta <BitsPoint
	and #$7
	bne mdInputBitsAE
	jsr ShotBeep
mdInputBitsAE:
mdInputBitsM:
	lda <BitsPoint
	and #7
	cmp <BitsMark
	bne mdInputBitsM1
	lda <BitsPoint + 1
	cmp <BitsMark + 1
	bne mdInputBitsM1
	jsr RingBeep
mdInputBitsM1:
	jmp mdInputBitsE
mdInputBitsA1:
	cmp #%00111000
	bne mdInputBitsM1
	lda #$F7
	and <BitsPoint
	sta <BitsPoint
	jsr FlagBeep
	jmp mdInputBitsE

mdInputBitsNA:
	lda <BitsPoint
	and #$8
	beq mdInputBitsZ
mdInputBitsO:
	lda <R0
	cmp #%00111111
	bne mdInputBitsO1
	lda <BitsPoint
	and #$7
	tax
	SetBitXA
	sta <R0
	ldx <BitsPoint + 1
	eor BitsBuf, x
	sta BitsBuf, x
	and <R0
	beq mdInputBitsODot
	jsr MorseBeepDash
	jmp mdInputBitsE
mdInputBitsODot:
	jsr MorseBeepDot
	jmp mdInputBitsE
mdInputBitsO1:
	cmp #%00000111
	bne mdInputBitsO2
	inc <BitsPoint
	lda #$7
	and <BitsPoint
	ora #$8
	sta <BitsPoint
	and #$7
	bne mdInputBitsM
	inc <BitsPoint + 1
	jsr ShotBeep
	jmp mdInputBitsM
mdInputBitsO2:
	cmp #%00111000
	bne mdInputBitsE
	dec <BitsPoint
	lda #$7
	and <BitsPoint
	ora #$8
	sta <BitsPoint
	and #$7
	bne mdInputBitsM
	dec <BitsPoint + 1
	jsr ShotBeep
	jmp mdInputBitsM

mdInputBitsZ:
	lda <R0
	cmp #%00111111
	bne mdInputBitsZ1
	lda <BitsPoint
	sta <BitsMark
	lda <BitsPoint + 1
	sta <BitsMark + 1
	jmp mdInputBitsE
mdInputBitsZ1:
	cmp #%00000111
	bne mdInputBitsZ2
	ldx <BitsPoint
	SetBitXA
	eor #$FF
	ldx <BitsPoint + 1
	and BitsBuf, x
	sta BitsBuf, x
	jmp mdInputBitsZ3
mdInputBitsZ2:
	cmp #%00111000
	bne mdInputBitsE
	ldx <BitsPoint
	SetBitXA
	ldx <BitsPoint + 1
	ora BitsBuf, x
	sta BitsBuf, x
mdInputBitsZ3:
	inc <BitsPoint
	lda #7
	and <BitsPoint
	sta <BitsPoint
	bne mdInputBitsE
	inc <BitsPoint + 1
;	jsr ShotBeep
mdInputBitsE:
	rts


SwapBitsText:
	ldy <BitsMark + 1
	ldx #0
swapBitsTextL:
	lda BitsBuf, y
	sta <R0
	lda TextBuf, x
	sta BitsBuf, y
	lda <R0
	sta TextBuf, x
	iny
	inx
	bne swapBitsTextL
	rts


InsertText:
	tay
	lda <TextLen
	cmp #$ff
	bne insertText1
	ldx #$0
insertText2:	
	lda TextBuf + ClipCols, x
	sta TextBuf, x
	inx
	cpx #256 - ClipCols
	bne insertText2
	lda #$0
insertText3:
	sta TextBuf, x
	inx
	bne insertText3
	lda #256 - ClipCols -1
insertText1:
	tax
	tya
	sta TextBuf, x
	inx
	stx <TextLen
	rts

BackspaceText:
	ldx <TextLen
	beq backspaceTextE
	lda #0
	sta TextBuf - 1, x
	dex
	stx <TextLen
backspaceTextE:
	rts

DeleteWordText:
	ldx <TextLen
	beq deleteWordTextE
	ldy #2
deleteWordText1:
	lda TextBuf - 1, x
	cpy #2
	bne deleteWordText2
	cmp #$20
	beq deleteWordText3
deleteWordText2:	
	ldy #1
	cmp #'0'
	bcc deleteWordText2D
	cmp #'9'+ 1
	bcc deleteWordText3
	cmp #'A'
	bcc deleteWordText2D
	cmp #'Z'+ 1
	bcc deleteWordText3
	cmp #'a'
	bcc deleteWordText2D
	cmp #'z'+ 1
	bcc deleteWordText3
deleteWordText2D:
	cpx <TextLen
	bne deleteWordTextE
	ldy #0
deleteWordText3:
	lda #0
	sta TextBuf - 1, x
	dex
	beq deleteWordTextE
	tya
	bne deleteWordText1

deleteWordTextE:
	stx <TextLen
	rts


SKeyStart:
	jmp MDReplay

SKeySelect:
	jsr FlagBeep

	jsr LoadBackUp
	tax
	bne skeySelectLNE
	jsr ErrorBeep
	ldx #0
skeySelectLE1:
	lda LoadErrorMessage, x
	beq skeySelectLE2
	sta TextBuf, x
	inx
	jmp skeySelectLE1
skeySelectLE2:
	stx <TextLen
skeySelectLNE:
	SetTextRefresh

	lda <KeyDCur
	and #$8
	beq skeySelectNB
	lda <KeyDCur
	and #$3
	asl a
	asl a
	asl a
	asl a
	sta <R0
	lda <LoadedSwitch
	and #%11001111
	ora <R0
	sta <LoadedSwitch
	lda <KeyDCur
	and #$4
	beq skeySelectNB
	jsr SwapBitsText
skeySelectNB:
	lda <KeyDCur
	and #$80
	beq skeySelect1
	lda <KeyDCur
	and #$70
	clc
	rol a
	rol a
	rol a
	rol a
	sta <R0
	bcc skeySelect2
	ora #$4
	sta <R0
skeySelect2
	lda <LoadedSwitch
	and #$f8
	ora <R0
	sta <LoadedSwitch
skeySelect1:
	Debug <LoadedSwitch, <R15
	lda <LoadedSwitch
	cmp <SystemSwitch
	beq skeySelectE
	sta <SystemSwitch
	WaitVBlank
	DisableScreen
	jsr SetBank
	jsr SetScrollY
	jsr Cls
	jsr InitTextArea
	jsr DrawLogo
	EnableScreen	
	WaitVScan
	SetScroll
skeySelectE:

	jmp MDReinit

SKey1B:
	lda #CHR_ERROR
	jmp mdInputCtrl

SKey1A:
;	jsr FlagBeep ;; debug
	lda <ChrMorseDash
	jsr InputMorse
	jmp MainLoop

SKey2B:
	lda <KeyDCur
	and #$8
	bne skey2B1
	lda #0
	sta <MainMode
	jmp MainLoop
skey2B1:
	lda <KeyDCur
	and #7
	sta <SailorFont
	lda #MD_REINIT
	sta <MainMode
	jmp MDReinit
	
SKey2A:
	lda <KeyDCur
	and #$8
	bne skey2A1
	lda #0
	sta <MainMode
	jmp MainLoop
skey2A1:
	lda <KeyDCur
	and #7
	sta <SailorColor
	lda #MD_REINIT
	sta <MainMode
	jmp MDReinit

MDMorseDot:
;	jsr ErrorBeep ;; debug
	lda <ChrMorseDot
	jsr InputMorse
	jmp MainLoop

MDShortCancel:
	lda #CHR_CANCEL
	jmp mdInputCtrl

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
	and <VTime
	bne nmiHandler0
	lda SpriteRamStart + CursorSP * 4 + 1
	eor #$10
	sta SpriteRamStart + CursorSP * 4 + 1
	lda <RefreshFlag
	ora #$40
	sta <RefreshFlag
nmiHandler0:
; スクロール
	lda $2002
	SetScroll

	dec <SailorAnimTime
	bne nmiHandler4
	inc <SailorAnimCount
	ldx <SailorAnimCount
	lda <SailorAnim, x
	bne nmiHandler6
	lda #0
	sta <SailorAnimCount
	jmp nmiHandler7
nmiHandler6:
	cmp #CHR_TERM
	bne nmiHandler7
	dec <SailorAnimCount
nmiHandler7:
	lda <R2
	pha
	lda <R3
	pha
	lda <R4
	pha
	jsr ShowFlag
	pla
	sta <R4
	pla
	sta <R3
	pla
	sta <R2
	lda #SailorAnimUnit
	sta <SailorAnimTime
	jmp nmiHandler5
nmiHandler4:

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
	WaitVScan
	SetScroll
	jsr CheckKey
	WaitVBlank
	lda <RefreshFlag
	and #$10
	beq nmiHandler2
	jsr RefreshBGCol
nmiHandler2:
	lda <RefreshFlag
	and #$20
	beq nmiHandler3
	jsr RefreshText
nmiHandler3:
	lda #0
	sta <RefreshFlag
;; スクロール
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
;; violates: a
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
	sta <Key1Now
	ora <Key1Push
	sta <Key1Push
	lda <R0
	and <Key1Release
	sta <Key1Release
	ldx #8
checkKey2:
	lda $4017
	lsr a
	rol <R0
	dex
	bne checkKey2
	lda <R0
	sta <Key2Now
	ora <Key2Push
	sta <Key2Push
	lda <R0
	and <Key2Release
	sta <Key2Release

	pla
	sta <R0
	pla
	tax
	rts


ReadKey:
;; violates: a, x, R0, R1, R2
	lda <Key1Push
	sta <R0
	lda <Key2Push
	sta <R1

	;; 十字キーを手旗符号に変換。
	;; Translate CROSS button to flag direction.
	lda <R0
	and #$f
	tax
	lda Key1FlagTable, x
	asl a
	asl a
	asl a
	asl a
	sta <KeyD
	lda <R1
	and #$f
	tax
	lda Key2FlagTable, x
	ora <KeyD
	sta <KeyD

	;; A B SELECT START は同時押しを認めないが、同時押しがあったこ
	;; とは検出。
	;; Translate some simultaneous pushs of A B SELECT START to #1.

	lda #0
	sta <KeyC
	lda <R0
	and #$f0
	sta <R2
	beq readKeyC2
	ldx #8
	lda #$10
readKey4:
	cmp <R2
	beq readKey5
	asl a
	inx
	cpx #8+4
	bne readKey4
	lda #1
	sta <KeyC
	bne readKeyE
readKey5:
	txa
	asl a
	asl a
	asl a
	asl a
	sta <KeyC

readKeyC2:
	lda <R1
	and #$f0
	sta <R2
	beq readKeyE
	ldx #8
	lda #$10
readKey6:
	cmp <R2
	beq readKey7
	asl a
	inx
	cpx #8+4
	bne readKey6
	lda #1
	sta <KeyC
	bne readKeyE
readKey7:
	txa
	ora <KeyC
	sta <KeyC
	and #$80
	beq readKeyE
	lda #1
	sta <KeyC
readKeyE:
	rts


ParseKey:
;; violates: a, x
	lda <MainMode
	cmp #MD_REPLAY
	beq parseKey1P

	lda <KeyC
	cmp #$80 + $30		;; モールス信号とキャンセルは優先特殊処理。
	beq parseKeyM0
	jsr MorseBeepOff
	jmp parseKey1P
parseKeyM0:
	jsr MorseBeepOn

parseKey1P:
	inc <KeyDTime
	bne parseKey1Z
	dec <KeyDTime
parseKey1Z:	
	lda <KeyD
	cmp <KeyDCur
	beq parseKey2P
	lda #0
	sta <KeyDTime

parseKey2P:
	inc <KeyCTime
	bne parseKey2Z
	dec <KeyCTime
parseKey2Z:	
	lda <KeyCCur
	cmp <KeyC
	beq parseKey3
	ldx #MD_MORSEDOT
	cmp #$80 + $30
	beq parseKeyM2
	ldx #MD_SHORTCANCEL
	cmp #$80 + $20
	bne parseKeyM1
parseKeyM2:
	;; 同時押しであれば、モールスやキャンセルの短信も無効。	
	lda <KeyC
	cmp #1
	beq parseKeyM1
	lda <KeyCTime
	cmp #KeyStopUnit + 1
	bcs parseKeyM1
	txa
	sta <MainMode
	;; 短信が成立すれば、方向キーは無効。
	lda #0
	sta <KeyD
	sta <KeyDTime
parseKeyM1:
	lda #0
	sta <KeyCTime

parseKey3:
	inc <Key1WaveTime
	inc <Key2WaveTime
parseKey3NL:
	lda <KeyCTime
	cmp #KeyStopUnit
	bcc parseKey3NS
	lda <KeyC
	and #$a0
	bne parseKey3MC
	lda <KeyDTime
	cmp #KeyStopUnit
	bcc parseKey3NS
	lda #0
	sta <Key1Wave
	sta <Key1WaveTime
	sta <Key2Wave
	sta <Key2WaveTime
parseKey3MC:
	lda <KeyCTime
	cmp #KeyStopUnit
	beq parseKey3S
	cmp #KeyStopUnit * 2
	bcc parseKey3NS
;	lda <KeyCCur
;	and #$a0		;; Stop increment of time for Morse Dash.
;	beq parseKey3M
;	lda #KeyStopUnit * 2 + 1
;	sta <KeyCTime
;parseKey3M:
	lda <KeyDTime
	cmp #KeyStopUnit
	beq parseKey3S
	jmp parseKeyE
parseKey3S:
	lda #KeyStopUnit
	sta <KeyCTime
	sta <KeyDTime
	jmp parseKeyI
parseKey3NS:

parseKeyW:
	lda #0
	sta <R2

	lda <KeyC
	beq parseKeyW01
	lda #0
	sta <Key1WaveTime
	sta <Key2WaveTime
parseKeyW01:

	lda <Key1WaveTime
	beq parseKeyW1
	lda <KeyD
	tax
	and #$80
	beq parseKeyW1
	txa
	and #$70
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	SetBitXA
	bit <Key1Wave
	beq parseKeyW11
	lda <Key1Wave
	and #%10010
	beq parseKeyW11
	inc <R2
parseKeyW11:
	ora <Key1Wave
	sta <Key1Wave
parseKeyW1:

	lda <Key2WaveTime
	beq parseKeyW2
	lda <KeyD
	tax
	and #$08
	beq parseKeyW2
	txa
	and #$07
	tax
	SetBitXA
	bit <Key2Wave
	beq parseKeyW21
	lda <Key2Wave
	and #%10010
	beq parseKeyW21
	inc <R2
	inc <R2
parseKeyW21:
	ora <Key2Wave
	sta <Key2Wave
parseKeyW2:

	lda #1
	bit <R2
	beq parseKeyW31
	lda #2
	bit <R2
	beq parseKeyW31
	lda <Key1WaveTime
	cmp #KeyWaveUnit
	bcc parseKeyW31
	lda <Key2WaveTime
	cmp #KeyWaveUnit
	bcc parseKeyW31
	lda #0
	sta <Key1WaveTime
	sta <Key2WaveTime
	jmp parseKeyI
parseKeyW31:
	lda #1
	bit <R2
	bne parseKeyW32
	lda <Key1WaveTime
	cmp #KeyWaveUnit
	bcc parseKeyW32
	lda <Key2WaveTime
	beq parseKeyW32
	lda #0
	sta <Key1WaveTime
	jmp parseKeyI
parseKeyW32:
	lda #2
	bit <R2
	bne parseKeyW33
	lda <Key2WaveTime
	cmp #KeyWaveUnit
	bcc parseKeyW33
	lda <Key1WaveTime
	beq parseKeyW33
	lda #0
	sta <Key2WaveTime
	jmp parseKeyI
parseKeyW33:
	jmp parseKeyE

parseKeyI:
	lda #MD_INPUT
	sta MainMode
	
parseKeyE:
	ldx #0
	lda <KeyD
	beq parseKeyE1
	lda <KeyD
	cmp <KeyDCur
	beq parseKeyE1
	inx
parseKeyE1:
	lda <KeyD
	sta <KeyDCur
	lda <KeyC
	sta <KeyCCur

	lda <KeyC
	cmp #$80 + $30
	beq parseKeyEM
	cmp #$80 + $20
	beq parseKeyEC
	txa
	beq parseKeyE3
	lda <KeyD
	ora #$88
	sta <SailorAnim
	bne parseKeyES		; jmp parseKeyES
parseKeyEM:
	ldy #$04
	lda <KeyCTime
	bne parseKeyEM00
	inx
parseKeyEM00:
	cmp #KeyStopUnit / 2
	bcc parseKeyEME
	bne parseKeyEM1
	inx
parseKeyEM1:	
	ldy #$05
	cmp #KeyStopUnit
	bcc parseKeyEME
	bne parseKeyEM2
	inx
parseKeyEM2:	
	ldy #$06
	cmp #KeyStopUnit + (KeyStopUnit / 2)
	bcc parseKeyEME
	bne parseKeyEM3
	inx
parseKeyEM3:	
;	ldy #$07
	cmp #KeyStopUnit + KeyStopUnit
	bne parseKeyEME
;	inx
parseKeyEME:
	txa
	beq parseKeyE3
	lda <KeyD
	and #$70
	sta <SailorAnim
	tya
	ora <SailorAnim
	ora #$88
	sta <SailorAnim
	bne parseKeyES		; jmp parseKeyES

parseKeyES:
	lda #CHR_TERM
	sta <SailorAnim + 1
	lda #0
	sta <SailorAnim + 2
parseKeyES1:
	lda #0
	sta <SailorAnimCount
	lda #SailorAnimUnit
	sta <SailorAnimTime
	jsr ShowFlag
parseKeyE3:
	rts

parseKeyEC:
	lda <KeyCTime
	bne parseKeyEC0
	lda #$88 + $31
	sta <SailorAnim
	bne parseKeyES		; jmp parseKeyES
parseKeyEC0:
	cmp #KeyStopUnit
	bne parseKeyE3
	ldx #0
	lda #$88
	sta <SailorAnim, x
	inx
	lda #$99
	sta <SailorAnim, x
	inx
	lda #$aa
	sta <SailorAnim, x
	inx
	lda #$99
	sta <SailorAnim, x
	inx
	lda #$88
	sta <SailorAnim, x
	inx
	lda #$99
	sta <SailorAnim, x
	inx
	lda #$aa
	sta <SailorAnim, x
	inx
	lda #$0
	sta <SailorAnim, x
	beq parseKeyES1		; jmp parseKeyES1


InitBuf:
	lda #1
	sta SailorFont
	lda #1
	sta <SailorColor
	lda RandSeed
	clc
	adc <RandPrime
	sta RandSeed
	tax
	and #$7
	cmp #$1
	bne initBuf1
	lda #3
	sta <SailorColor
	txa
	cmp #$B8
	bcs initBuf1
	lda #2
	sta SailorFont
	txa
	cmp #$E0
	bcs initBuf1
	lda #6
	sta SailorFont
	txa
	cmp #$FC
	bcs initBuf1
	lda #5
	sta SailorFont
initBuf1:
	ldx #0
	txa
initBuf2:
	sta TextBuf, x
	inx
	bne initBuf2

	rts

InitTextArea:
	lda #$a0
	ldx #8 * 6
initTextArea1:
	sta BGColBuf, x
	inx
	cpx #8 * 7
	bne initTextArea1
	lda #$aa
initTextArea2:
	sta BGColBuf, x
	inx
	cpx #8 * 8
	bne initTextArea2
	lda #$00
	sta BGColBuf + 8 * 6 + 6
	sta BGColBuf + 8 * 6 + 7
	sta BGColBuf + 8 * 7 + 6
	sta BGColBuf + 8 * 7 + 7

;	lda #240 - 1
;	sta <ScrollY

	rts


SetCursor:
	tya
	asl a
	asl a
	asl a
	sbc #-4		;; SP はなぜか Y 軸に 1 ドットずれる。
			;; 8x8 フォントのときは 4 ドットずらす。
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
	
	ldy #ClipY - 2
	lda <TextLen
	sec
showCursor1:
	sbc #ClipCols
	iny
	iny
	bcs showCursor1
	adc #ClipCols
	tax
	lda <SystemSwitch
	and #4
	beq showCursor2
	txa
	eor #$ff
	clc
	adc #ClipCols
	tax
showCursor2:
	txa
	clc
	adc #ClipX
	tax
	jsr SetCursor
	lda <RefreshFlag
	ora #$40
	sta <RefreshFlag
	rts

RefreshTextM .macro
  if \2 = 0
	lda <R2
	pha

	lda #0
	sta <R2
	lda #low($2000 + ClipX + 32 * ClipY)
	sta <R0
	lda #high($2000 + ClipX + 32 * ClipY)
	sta <R1
refreshText\@1:
	WaitVScan
	SetScroll
	jsr CheckKey

	lda <SystemSwitch
	and #4
	beq refreshText\@LB
	ldy <R2
	ldx #ClipCols
	cpy <TextLen
	bcs refreshText\@LB1L
refreshText\@LB1:
	lda TextBuf, y
    if \1 = 1
	ToPrintableA
    endif
	sta <LineBuf - 1, x
	iny
	beq refreshText\@LB1R
	cpy <TextLen
	beq refreshText\@LB1R
	dex
	bne refreshText\@LB1
	beq refreshText\@LBE
refreshText\@LB1R:
	dex
	beq refreshText\@LBE
refreshText\@LB1L:
	lda #0
refreshText\@LB1S:
	sta <LineBuf - 1, x
	dex
	bne refreshText\@LB1S
	beq refreshText\@LBE
refreshText\@LB:
	ldy <R2
	ldx #0
	cpy <TextLen
	bcs refreshText\@LB0L
refreshText\@LB0:
	lda TextBuf, y
    if \1 = 1
	ToPrintableA
    endif
	sta <LineBuf, x
	iny
	beq refreshText\@LB0R
	cpy <TextLen
	beq refreshText\@LB0R
	inx
	cpx #ClipCols
	bne refreshText\@LB0
	beq refreshText\@LBE
refreshText\@LB0R:
	inx
	cpx #ClipCols
	beq refreshText\@LBE
refreshText\@LB0L:
	lda #0
refreshText\@LB0S:
	sta <LineBuf, x
	inx
	cpx #ClipCols
	bne refreshText\@LB0S
refreshText\@LBE:
	WaitVBlank

refreshText\@1N:
	ldx #0
	lda <R1
	sta $2006
	lda <R0
	sta $2006

refreshText\@2:
	lda <LineBuf, x
	sta $2007
	inx
	cpx #ClipCols
	bne refreshText\@2

	lda #32 * 2
	clc
	adc <R0
	sta <R0
	lda #0
	adc <R1
	sta <R1
	lda <R2
	clc
	adc #ClipCols
	sta <R2
	bcs refreshText\@3
	jmp refreshText\@1

refreshText\@3:
;	lda #$30;;debug
;	sta <NumCodeBuf
;	lda #$31;;debug
;	sta <MorseCodeBuf
	lda #high($2000 + ClipX + 32 * MorseCodeLine)
	sta $2006
	lda #low($2000 + ClipX + 32 * MorseCodeLine)
	sta $2006
	ldx #0
refreshText\@5:
	lda <NumCodeBuf, x
	beq refreshText\@4
	sta $2007
	inx
	cpx #NumCodeBufLen
	bne refreshText\@5
	lda #0
refreshText\@4:
refreshText\@6:
	sta $2007
	inx
	cpx #NumCodeBufLen
	bne refreshText\@6
	ldx #0
refreshText\@7:
	lda <MorseCodeBuf, x
	beq refreshText\@8
	sta $2007
	inx
	cpx #MorseCodeBufLen
	bne refreshText\@7
refreshText\@8:
	lda #0
refreshText\@9:
	sta $2007
	inx
	cpx #MorseCodeBufLen
	bne refreshText\@9
refreshText\@E:

	pla
	sta <R2
	rts
  else
	lda <R2
	pha

	lda #0
	sta <R2
	lda #low($2000 + ClipX + 32 * ClipY)
	sta <R0
	lda #high($2000 + ClipX + 32 * ClipY)
	sta <R1
refreshTextH\@1:
;	lda <R2
;	and #1
;	bne refreshTextH\@1N
	WaitVScan
	SetScroll
	jsr CheckKey

	lda <SystemSwitch
	and #4
	beq refreshTextH\@LB
	ldy <R2
	ldx #ClipCols
	cpy <TextLen
	bcs refreshTextH\@LB1L
refreshTextH\@LB1:
	lda TextBuf, y
refreshTextH\@LB1Q:
    if \1 = 1
	ToPrintableA
    endif
	sta <LineBuf - 1, x
	and #$f0
	clc
	adc <LineBuf - 1, x
	bcc refreshTextH\@LB1O
	ora #$10
	bpl refreshTextH\@LB1Q
	eor #$ff
	bpl refreshTextH\@LB1Q
refreshTextH\@LB1O:
	sta <LineBuf - 1, x
	iny
	beq refreshTextH\@LB1R
	cpy <TextLen
	beq refreshTextH\@LB1R
	dex
	bne refreshTextH\@LB1
	beq refreshTextH\@LBE
refreshTextH\@LB1R:
	dex
	beq refreshTextH\@LBE
refreshTextH\@LB1L:
	lda #0
refreshTextH\@LB1S:
	sta <LineBuf - 1, x
	dex
	bne refreshTextH\@LB1S
	beq refreshTextH\@LBE
refreshTextH\@LB:
	ldy <R2
	ldx #0
	cpy <TextLen
	bcs refreshTextH\@LB0L
refreshTextH\@LB0:
	lda TextBuf, y
refreshTextH\@LB0Q:
    if \1 = 1
	ToPrintableA
    endif
	sta <LineBuf, x
	and #$f0
	clc
	adc <LineBuf, x
	bcc refreshTextH\@LB0O
	ora #$10
	bpl refreshTextH\@LB0Q
	eor #$ff
	bpl refreshTextH\@LB0Q
refreshTextH\@LB0O:
	sta <LineBuf, x
	iny
	beq refreshTextH\@LB0R
	cpy <TextLen
	beq refreshTextH\@LB0R
	inx
	cpx #ClipCols
	bne refreshTextH\@LB0
	beq refreshTextH\@LBE
refreshTextH\@LB0R:
	inx
	cpx #ClipCols
	beq refreshTextH\@LBE
refreshTextH\@LB0L:
	lda #0
refreshTextH\@LB0S:
	sta <LineBuf, x
	inx
	cpx #ClipCols
	bne refreshTextH\@LB0S
refreshTextH\@LBE:
	WaitVBlank

refreshTextH\@1N:
	ldx #0
	lda <R1
	sta $2006
	lda <R0
	sta $2006

refreshTextH\@2:
	lda <LineBuf, x
	sta $2007
	inx
	cpx #ClipCols
	bne refreshTextH\@2

	lda #32
	clc
	adc <R0
	sta <R0
	lda #0
	adc <R1
	sta <R1

	ldx #0
	lda <R1
	sta $2006
	lda <R0
	sta $2006

refreshTextH\@2L:
	lda <LineBuf, x
	ora #$10
	sta $2007
	inx
	cpx #ClipCols
	bne refreshTextH\@2L

	lda #32
	clc
	adc <R0
	sta <R0
	lda #0
	adc <R1
	sta <R1

	lda <R2
	clc
	adc #ClipCols
	sta <R2
	bcs refreshTextH\@3
	jmp refreshTextH\@1

refreshTextH\@3:
;	lda #$30;;debug
;	sta <NumCodeBuf
;	lda #$31;;debug
;	sta <MorseCodeBuf
	lda #high($2000 + ClipX + 32 * MorseCodeLine)
	sta $2006
	lda #low($2000 + ClipX + 32 * MorseCodeLine)
	sta $2006
	ldx #0
refreshTextH\@5:
	lda <NumCodeBuf, x
	beq refreshTextH\@4
	sta <R0
	and #$70
	clc
	adc <R0
	sta $2007
	inx
	cpx #NumCodeBufLen
	bne refreshTextH\@5
	lda #0
refreshTextH\@4:
refreshTextH\@6:
	sta $2007
	inx
	cpx #NumCodeBufLen
	bne refreshTextH\@6
	ldx #0
refreshTextH\@7:
	lda <MorseCodeBuf, x
	beq refreshTextH\@8
	sta <R0
	and #$70
	clc
	adc <R0
	sta $2007
	inx
	cpx #MorseCodeBufLen
	bne refreshTextH\@7
refreshTextH\@8:
	lda #0
refreshTextH\@9:
	sta $2007
	inx
	cpx #MorseCodeBufLen
	bne refreshTextH\@9

	lda #high($2000 + ClipX + 32 * (MorseCodeLine + 1))
	sta $2006
	lda #low($2000 + ClipX + 32 * (MorseCodeLine + 1))
	sta $2006
	ldx #0
refreshTextH1\@5:
	lda <NumCodeBuf, x
	beq refreshTextH1\@4
	sta <R0
	and #$70
	clc
	adc <R0
	ora #$10
	sta $2007
	inx
	cpx #NumCodeBufLen
	bne refreshTextH1\@5
	lda #0
refreshTextH1\@4:
refreshTextH1\@6:
	sta $2007
	inx
	cpx #NumCodeBufLen
	bne refreshTextH1\@6
	ldx #0
refreshTextH1\@7:
	lda <MorseCodeBuf, x
	beq refreshTextH1\@8
	sta <R0
	and #$70
	clc
	adc <R0
	ora #$10
	sta $2007
	inx
	cpx #MorseCodeBufLen
	bne refreshTextH1\@7
refreshTextH1\@8:
	lda #0
refreshTextH1\@9:
	sta $2007
	inx
	cpx #MorseCodeBufLen
	bne refreshTextH1\@9
refreshTextH\@E:

	pla
	sta <R2
	rts
  endif
	.endm

RefreshText:
	lda <SystemSwitch
	and #3
	bne .L1
	jmp refreshText8x8NTP
.L1:
	cmp #3
	bne .L2
	jmp refreshText8x16TP
.L2:
	cmp #2
	beq refreshText8x8TP
	jmp refreshText8x16NTP

refreshText8x8TP:
	RefreshTextM 1, 0
refreshText8x8NTP:
	RefreshTextM 0, 0
refreshText8x16NTP:
	RefreshTextM 0, 1
refreshText8x16TP:
	RefreshTextM 1, 1


;; バックアップ RAM からロード
LoadBackUp:
	ldx #0
loadBackUpC1:
	lda CheckID, x
	beq loadBackUpC3
	cmp BackUpRamCheck, x
	beq loadBackUpC2
loadBackUpCR:
	lda #0
	rts
loadBackUpC2:
	inx
	bne loadBackUpC1
loadBackUpC3:
	lda BitsPointSave
	and #$F8
	bne loadBackUpCR
loadBackUpCE:

	lda LoadCount
	pha
	bmi loadBackUpNW
	sec
	adc #0
	sta LoadCount
	tax
	lda #0
loadBackUpW:
	tay
	txa
	sec
	sbc LoadCount		;; A Magic.
	bne loadBackUpW
	sty <LoadCost
	txa
	sec
	adc <LoadCost
	sta <LoadCost
loadBackUpNW:

	lda SavedSwitch
	sta <LoadedSwitch
	lda FontSaveBuf
	and #7
	sta <SailorFont
	lda ColorSaveBuf
	and #7
	sta <SailorColor
	lda TextSaveLen
	sta <TextLen
	lda BitsPointSave
	sta <BitsPoint
	lda BitsPointSave + 1
	sta <BitsPoint + 1
	lda BitsMarkSave
	sta <BitsMark
	lda BitsMarkSave + 1
	sta <BitsMark + 1
	ldx #0
loadBackUp2:
	lda TextSaveBuf, x
	sta TextBuf, x
	inx
	bne loadBackUp2
	ldx #0
loadBackUp1:
	lda BitsSaveBuf, x
	sta BitsBuf, x
	inx
	bne loadBackUp1

	pla
	bpl loadBackUpNC
	lda LoadCount
	sta <LoadCost
loadBackUpNC:
	dec LoadCount

	lda #1
	rts



;; バックアップ RAM へセーブ
SaveBackUp:
	lda RandSeed
	sta <R0
	sta <R1
	ldx #3
saveBackUp0:
	lda CheckID - 1, x
	sta BackUpRamCheck - 1, x
	dex
	bne saveBackUp0
	lda <SystemSwitch
	sta SavedSwitch
	lda <SailorFont
	sta FontSaveBuf
	lda <SailorColor
	sta ColorSaveBuf
	lda <TextLen
	sta TextSaveLen
	lda <BitsPoint
	and #$7
	sta BitsPointSave
	lda <BitsPoint + 1
	sta BitsPointSave + 1
	lda <BitsMark
	sta BitsMarkSave
	lda <BitsMark + 1
	sta BitsMarkSave + 1
	ldx #0
saveBackUp2:
	lda TextBuf, x
	sta TextSaveBuf, x
	clc
	adc <R0
	inx
	bne saveBackUp2
	ldx #0
saveBackUp1:
	lda BitsBuf, x
	sta BitsSaveBuf, x
	clc
	adc <R1
	inx
	bne saveBackUp1

	lda RandSeed		;; A (Summon) Magic. Don't Rationalize.
	clc
	adc <R0
	adc <R1
	pha
	lda <R0
	clc
	adc <RandPrime
	sta RandSeed
	pla
	sta RandSeed
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
	lda <SystemSwitch
	and #1
	beq drawBGChrNH1
	lda [R0], y
	bpl drawBGChrH11
	clc
	adc #$a0
drawBGChrH11:
	sta $2007
	iny
	lda [R0], y
	bpl drawBGChrH12
	clc
	adc #$a0
	bcs drawBGChrH12
drawBGChrNH1:
	lda [R0], y
	sta $2007
	iny
	lda [R0], y
drawBGChrH12:
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
	lda <SystemSwitch
	and #1
	beq drawBGChrNH2
	lda [R0], y
	bpl drawBGChrH21
	clc
	adc #$a0
drawBGChrH21:
	sta $2007
	iny
	lda [R0], y
	bpl drawBGChrH22
	clc
	adc #$a0
	bcs drawBGChrH22
drawBGChrNH2:
	lda [R0], y
	sta $2007
	iny
	lda [R0], y
drawBGChrH22:
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
	lda <SystemSwitch
	and #1
	bne drawSPChrN8
	lda <R3		;; 8x8 フォントのときは 4 ドットずらす。
	clc
	adc #4
	sta <R3
drawSPChrN8:
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

	lda <SystemSwitch
	and #1
	bne drawLogo8x16

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

drawLogo8x16:
	lda #high($2000 + Name8x16X + Name8x16Y * 32)
	sta $2006
	lda #low($2000 + Name8x16X + Name8x16Y * 32)
	sta $2006
	ldx #0
drawLogoH1:
	lda NameStr, x
	beq drawLogoH2
	sta <R0
	and #$70
	clc
	adc <R0
	sta $2007
	inx
	bne drawLogoH1
drawLogoH2:

	lda #high($2000 + Name8x16X + (Name8x16Y + 1) * 32)
	sta $2006
	lda #low($2000 + Name8x16X + (Name8x16Y + 1) * 32)
	sta $2006
	ldx #0
drawLogoL1:
	lda NameStr, x
	beq drawLogoL2
	sta <R0
	and #$70
	clc
	adc <R0
	ora #$10
	sta $2007
	inx
	bne drawLogoL1
drawLogoL2:
	
	lda #high($2000 + Version8x16X + Version8x16Y * 32)
	sta $2006
	lda #low($2000 + Version8x16X + Version8x16Y * 32)
	sta $2006
	ldx #0
drawLogoH3:
	lda VersionStr, x
	beq drawLogoH4
	sta <R0
	and #$70
	clc
	adc <R0
	sta $2007
	inx
	bne drawLogoH3
drawLogoH4:

	lda #high($2000 + Version8x16X + (Version8x16Y + 1) * 32)
	sta $2006
	lda #low($2000 + Version8x16X + (Version8x16Y + 1) * 32)
	sta $2006
	ldx #0
drawLogoL3:
	lda VersionStr, x
	beq drawLogoL4
	sta <R0
	and #$70
	clc
	adc <R0
	ora #$10
	sta $2007
	inx
	bne drawLogoL3
drawLogoL4:

	rts

DrawSailor:
	lda <SailorColor
	asl a
	asl a
	tax

	lda #$3f
	sta $2006
	lda #4
	sta $2006
	lda SailorPalette + 0, x
	sta $2007
	lda SailorPalette + 1, x
	sta $2007
	lda SailorPalette + 2, x
	sta $2007
	lda SailorPalette + 3, x
	sta $2007
	
	;; 腕の色をパレットに登録。
;	lda SailorPalette + 3, x
	tax
	lda #$3f
	sta $2006
	lda #$10 + 4 * 1 + 3
	sta $2006
	txa
	sta $2007
	lda #$3f
	sta $2006
	lda #$10 + 4 * 3 + 3
	sta $2006
	txa
	sta $2007

	lda <SailorFont
	and #6
	sta <R1
	asl a
	asl a
	adc <R1
	pha
	clc
	;; 上半身
	adc #low(SailorChr)
	sta <R0
	lda #0
	adc #high(SailorChr)
	sta <R1
	lda #SailorX / 8
	sta <R2
	lda #SailorY / 8
	sta <R3
	jsr DrawBGChr
	pla
	clc
	;; 下半身
	adc #5
	adc #low(SailorChr)
	sta <R0
	lda #0
	adc #high(SailorChr)
	sta <R1
	lda #SailorX / 8
	sta <R2
	lda #(SailorY + 16) / 8
	sta <R3
	jsr DrawBGChr
	rts

DrawFlag:
	ldx #FlagLSP
	ldy #FlagRSP
	lda <R0
	and #$07
	sta <R1
	lda <R0
	lsr a
	lsr a
	lsr a
	lsr a
	sta <R0
	cmp <R1
	bcs drawFlagSP
	ldx #FlagRSP
	ldy #FlagLSP
drawFlagSP:
	tya
	pha
	lda <R1
	pha
	txa
	pha
	lda <R0
	pha
	
	pla
	sta <R2
	lda <SailorFont
	and #1
	asl a
;	ora #0
	asl a
	asl a
	asl a
	clc
	adc <R2
	sta <R1
	adc <R1
	adc <R1
	adc <R1
	adc <R1
	clc
	adc #low(FlagChr)
	sta <R0
	lda #0
	adc #high(FlagChr)
	sta <R1

	lda <R2
	asl a
	tax
	lda FlagLoc, x
	clc
	adc #SailorX
	sta <R2
	lda FlagLoc + 1, x
	clc
	adc #SailorY
	sta <R3
	pla
	sta <R4
	jsr DrawSPChr

	pla
	sta <R2
	lda <SailorFont
	and #1
	asl a
	ora #1
	asl a
	asl a
	asl a
	clc
	adc <R2
	sta <R1
	adc <R1
	adc <R1
	adc <R1
	adc <R1
	clc
	adc #low(FlagChr)
	sta <R0
	lda #0
	adc #high(FlagChr)
	sta <R1

	lda <R2
	ora #8
	asl a
	tax
	lda FlagLoc, x
	clc
	adc #SailorX
	sta <R2
	lda FlagLoc + 1, x
	clc
	adc #SailorY
	sta <R3
	pla
	sta <R4
	jsr DrawSPChr

	rts

ShowFlag:
	ldx <SailorAnimCount
	lda <SailorAnim, x
	and #$77
	sta <R0
	jsr DrawFlag
	lda #$40
	ora <RefreshFlag
	sta <RefreshFlag
	rts


FlagBeep:
	lda $4015
	ora #8
	sta $4015
	lda #%00011111
	sta $400C
	lda #%10001111
	sta $400E
	lda #%00111000
	sta $400F
	rts

ShotBeep:
	lda $4015
	ora #1
	sta $4015
	lda #%01010010
	sta $4000
	lda #%10000011
	sta $4001
	lda #%01000100
	sta $4002
	lda #%00001000
	sta $4003
	rts

RingBeep:
	lda $4015
	ora #2
	sta $4015
	lda #%10000100
	sta $4004
	lda #%00000000
	sta $4005
	lda #%01000100
	sta $4006
	lda #%00001000
	sta $4007
	rts

ErrorBeep:
	lda $4015
	ora #8
	sta $4015
	lda #%00010111
	sta $400C
	lda #%10000100
	sta $400E
	lda #%00010000
	sta $400F
	rts

MorseBeepOn:
	lda $4015
	ora #4
	sta $4015
	lda #%11111111
	sta $4008
	lda #%00100010
	sta $400A
	lda #%00000000
	sta $400B
	rts

MorseBeepOff:
	lda $4015
	and #%11111011
	sta $4015
	rts

MorseBeepDot:
	lda $4015
	ora #1
	sta $4015
	lda #%01011111
	sta $4000
	lda #%00000000
	sta $4001
	lda #%01000100
	sta $4002
	lda #%00011000
	sta $4003
	rts

MorseBeepDash:
	lda $4015
	ora #1
	sta $4015
	lda #%01011111
	sta $4000
	lda #%00000000
	sta $4001
	lda #%01000100
	sta $4002
	lda #%00010000
	sta $4003
	rts

;; MorseBeepDot:
;; ;	jsr MorseBeepOff
;; 	lda $4015
;; 	ora #4
;; 	sta $4015
;; 	lda #%00001000
;; 	sta $4008
;; 	lda #%00100001
;; 	sta $400A
;; 	lda #%00001000
;; 	sta $400B
;; 	rts

;; MorseBeepDash:
;; ;	jsr MorseBeepOff
;; 	lda $4015
;; 	ora #4
;; 	sta $4015
;; 	lda #%01000000
;; 	sta $4008
;; 	lda #%00100010
;; 	sta $400A
;; 	lda #%00001000
;; 	sta $400B
;; 	rts

ParseMorseCode:
	lda #0
	tax
	tay
	sta <R0
	lda <MorseCodeBuf
	cmp <ChrMorseAmp
	beq parseMorseCodeS
	cmp <ChrMorseUBar
	bne parseMorseCode1
parseMorseCodeS	
	tay
	inx
parseMorseCode1:
	lda <MorseCodeBuf, x
	beq parseMorseCode2
	lsr a
	rol <R0
	inx
	cpx #MorseCodeBufLen
	bne parseMorseCode1
parseMorseCode2
	tya
	beq parseMorseCode2N
	dex
parseMorseCode2N:
	txa
	bne parseMorseCode2N1
	jmp parseMorseCodeI
parseMorseCode2N1:
	cpy <ChrMorseAmp
	bne parseMorseCodeNA
	ldy <R0
	jmp parseMorseCodeI
parseMorseCodeNA:
	cmp #7
	bne parseMorseCode2ND
	lda <R0
	cmp #%0001001
	bne parseMorseCodeErr
	lda #'$'
	jmp parseMorseCodeC
parseMorseCode2ND:
	cmp #8
	bne parseMorseCode2NE
	lda <R0
	cmp #%00000000
	bne parseMorseCodeErr
	ldy #CHR_ERROR
	jmp parseMorseCodeCtrl
parseMorseCode2NE:
	cmp #9
	bcs parseMorseCodeErr
parseMorseCode3:
	dex
	MaskBitXA
	clc
	adc <R0
	tax
	lda MorseCodeLenTable, x
	bne parseMorseCodeC
	ldy #0
	jmp parseMorseCodeCtrl
parseMorseCodeC:
	cpy #0
	bne parseMorseCodeC1
	cmp #'_'
	beq parseMorseCodeCS1
	cmp #'&'
	bne parseMorseCodeC1
	lda <ChrMorseAmp
	jmp parseMorseCodeCS2
parseMorseCodeCS1:
	lda <ChrMorseUBar
parseMorseCodeCS2:
	sta <MorseCodeBuf
	lda #0
	sta <MorseCodeBuf + 1
	SetTextRefresh
	jmp parseMorseCodeE
parseMorseCodeErr:
	ldy #CHR_NULL
parseMorseCodeCtrl:
	cpy #CHR_ERROR
	bne parseMorseCodeCtrl1
	jsr DeleteWordText
	jsr FlagBeep
	SetTextRefresh
	jsr ShowCursor
	lda #0
	sta <MorseCodeBuf
	jmp parseMorseCodeE
parseMorseCodeCtrl1:
	jsr ErrorBeep
	lda #0
	sta <MorseCodeBuf
	jmp parseMorseCodeE

parseMorseCodeCU1:
	lda UBarMorseCodeT, x
	jmp parseMorseCodeCE
parseMorseCodeC1:
	cpy <ChrMorseUBar
	bne parseMorseCodeCE
	ldx #0
parseMorseCodeCU0:
	cmp UBarMorseCode, x
	beq parseMorseCodeCU1
	inx
	cpx <UBarMorseCodeLen
	bne parseMorseCodeCU0
	ToUpperCase
	ldx #'^'
	cmp #$22
	beq parseMorseCodeCX
	ldx #'`'
	cmp #$27
	beq parseMorseCodeCX
	ldx #'~'
	cmp #'-'
	beq parseMorseCodeCX
	ldx #$5C
	cmp #'/'
	beq parseMorseCodeCX
	bne parseMorseCodeCE
parseMorseCodeCX:
	txa
parseMorseCodeCE:
	cmp #$20
	bcc parseMorseCodeCtrl
	cmp #$7e
	bcs parseMorseCodeCtrl
	tay
parseMorseCodeI:
	tya
	jsr InsertText
	jsr FlagBeep
	SetTextRefresh
	jsr ShowCursor
	lda #0
	sta <MorseCodeBuf
parseMorseCodeE:
	rts
	
SetBank:
	lda <SystemSwitch
	lsr a
	lsr a
	lsr a
	lsr a
	and <BankMask
	sta <R0

	lda _SystemSwitch
	and #$10
	beq setBank1
	ldx <R0
	lda BankStr, x
	sta BankStr, x
setBank1:
	;; R0 <- banknum
	lda <R0
	asl a
	sta <R0
	lda <SystemSwitch
	and #$1
	clc
	adc <R0
	sta <R0
	asl a
	clc
	adc <R0
	;; R0 <- banknum * 6 + UseFont8x16 * 3

	tax
	lda ToPrintableTables, x
	sta <ToPrintableFirst
	lda ToPrintableTables + 1, x
	sta <ToPrintableLast
	lda ToPrintableTables + 2, x
	sta <ToPrintableChrNon
setBankE:
	rts


SetScrollY:
	lda #0
	sta <ScrollY
	lda <SystemSwitch
	and #$1
	bne setScrollYE
	lda #-4
	sta <ScrollY
setScrollYE:
	rts


;; ちょっと bank の値が変だけど、NESASM だとこうしないとうまくマップされない。
;;
;; A bit awkward .bank 1, but NESASM doesn't map well if .bank 0.
	.bank 1	
	org $A000
;; .data
NameStr:
CheckID:
	.db "JRF", $0
DummyStr:
	.db "Any Non-NUL String, Here"
VersionStr:
	.db "v"
	JRF_VERSION .db
	.db $0

PublicSymbols:
Tables:
	.dw CheckID
	.dw FlagCode
	.dw MorseCodeLenTable
	.dw MorseCodeLetterTable
	.dw ReplayInitial
	.dw _SystemSwitch
	.dw _BankMask
	.dw _RandPrime
	.dw _LoadCost
	.dw _UBarMorseCodeLen
	.dw _DisplayChr
	.dw Palette
	.dw PaletteSize
	.dw SailorPalette
	.dw Logo
	.dw SailorChr
	.dw FlagChr
	.dw FlagLoc
	.dw BankStr
	.dw ToPrintableTables
	.dw FontName_0_0
	.dw FontName_0_1
	.dw FontName_1_0
	.dw FontName_1_1
	.dw FontName_2_0
	.dw FontName_2_1
	.dw FontName_3_0
	.dw FontName_3_1
	.dw $0
TablesEnd:
PublicSymbolsEnd:

FlagCode:
	;; L: Left flag in right arm, R: Right flag in left arm.
	;;    0,   1,   2,   3,   4,   5,   6,   7  R/L
        .db $00, 'g', 'f', 'e', '.', '?', '_', $03 ;; 0
        .db 'a', 'n', 'm', 'l', 'k', 'i', 'H', '?' ;; 1
        .db 'b', 's', 'r', 'q', 'p', 'o', '?', 'h' ;; 2
        .db 'c', $08, 'y', 'u', 't', '?', 'O', 'I' ;; 3
        .db 'd', 'v', 'j', '$', '?', '?', '?', '?' ;; 4
        .db '?', 'x', 'w', '?', '?', '?', '?', '?' ;; 5
        .db '&', '?', '?', 'W', '?', '?', '?', 'Z' ;; 6
        .db $03, '?', 'z', 'X', '?', '?', '?', ' ' ;; 7

;; 本プログラムでは特殊な方法として、モールス符号 '.' と '_' を用意。
;; モールス短音は、'.'->$00、モールス長音は '.'->'_' で '-'。
;; モールス符号の文字区切りは表中 $03 のものを使えばよい。
;; アルファベットは基本、小文字とし、大文字は '_'->文字 で指定。
;; また、'_'->'.' で '.'、'_'->' ' で ',' とする。
;; 上表の大文字は Wikipedia の方法と違うが、似ているのでそれでも入力でき、
;; その入力は表中の大文字ではなく小文字となる。
;;
;; '$' ではじまる数字モードのときは、通常は 3 つの数字で、8進数3ケタの
;; ascii コード指定。ただし、'_'->数字 で、その数字が出る。
;; コード指定の数字の最初が 4-9 なら、2つの数字で入力可。
;; 8 は次が 0 なら 1->0(->0) に、そうでないなら 1->3 に同じと解釈。
;; 9 は次が 0 なら 1->4(->0) に、そうでないなら 1->7 に同じと解釈。
;;
;; '&' は '$' とほとんど同じだが、(ASCII コードを)一文字分入力したとこ
;; ろで自動的に数字モードが終る。モード終了のために 'j' を送る必要はな
;; いし送ってはならない。
;;
;; 制御符号を除けば、$20 から $7f までは最大二つの符号で入力可能。

;; This program specially implements '.' and '_' as "Morse characters".
;; A dot of Morse code is '.'->$00.  A dash '-' of Morse code is '.'->'_'.
;; $03 is another $00 but can give a boundary of characters of Morse Code.
;; Alphabets are lower case in default. '_'->Letter gives upper case.
;; '_'->'.' gives '.'(period). '_'->' '(space) gives ','(comma).
;; In the table above, upper case letters mean another way of poses,
;; which are different from the original ones in Wikipedia but similar.
;; And they also give lower case instead of upper case.
;;
;; In numeral mode which begins by '$' , normally 3 octets give one
;; ascii code. However, '_'->Number gives that number.
;; If the first octet is 4-9, 2 octets can give one ascii code.
;; 8: if the next is 0, makes 1->0(->0), otherwise makes 1->3.
;; 9: if the next is 0, makes 1->4(->0), otherwise makes 1->7.
;;
;; '&' is similar to '$', but it automatically ends 'numeral mode' by
;; one character (of ASCII code) without 'j' i.e. letter mode sign.
;;
;; You can input $20-$7f in two codes excluding of control codes.

FlagInvLetter:
	.db $10 + $88	;; 'A'
	.db $20 + $88	;; 'B'
	.db $30 + $88	;; 'C'
	.db $40 + $88	;; 'D'
	.db $03 + $88	;; 'E'
	.db $02 + $88	;; 'F'
	.db $01 + $88	;; 'G'
	.db $27 + $88	;; 'H'
	.db $15 + $88	;; 'I'
	.db $42 + $88	;; 'J'
	.db $14 + $88	;; 'K'
	.db $13 + $88	;; 'L'
	.db $12 + $88	;; 'M'
	.db $11 + $88	;; 'N'
	.db $25 + $88	;; 'O'
	.db $24 + $88	;; 'P'
	.db $23 + $88	;; 'Q'
	.db $22 + $88	;; 'R'
	.db $21 + $88	;; 'S'
	.db $34 + $88	;; 'T'
	.db $33 + $88	;; 'U'
	.db $41 + $88	;; 'V'
	.db $52 + $88	;; 'W'
	.db $51 + $88	;; 'X'
	.db $32 + $88	;; 'Y'
	.db $72 + $88	;; 'Z'
	.db $0

FlagInvNum:
	.db $14 + $88	;; '0'
	.db $10 + $88	;; '1'
	.db $20 + $88	;; '2'
	.db $30 + $88	;; '3'
	.db $40 + $88	;; '4'
	.db $03 + $88	;; '5'
	.db $02 + $88	;; '6'
	.db $01 + $88	;; '7'
	.db $27 + $88	;; '8'
	.db $15 + $88	;; '9'
	.db $0

MorseCodeLenTable:
	.db $00		;; ""
	.db 'e'		;; %0
	.db 't'		;; %1
	.db 'i'		;; %00
	.db 'a'		;; %01
	.db 'n'		;; %10
	.db 'm'		;; %11
	.db 's'		;; %000
	.db 'u'		;; %001
	.db 'r'		;; %010
	.db 'w'		;; %011
	.db 'd'		;; %100
	.db 'k'		;; %101 (Invitation to transmit)
	.db 'g'		;; %110
	.db 'o'		;; %111
	.db 'h'		;; %0000
	.db 'v'		;; %0001
	.db 'f'		;; %0010
	.db $0		;; %0011
	.db 'l'		;; %0100
	.db $0		;; %0101
	.db 'p'		;; %0110
	.db 'j'		;; %0111
	.db 'b'		;; %1000
	.db 'x'		;; %1001
	.db 'c'		;; %1010
	.db 'y'		;; %1011
	.db 'z'		;; %1100
	.db 'q'		;; %1101
	.db $0		;; %1110
	.db $0		;; %1111
	.db '5'		;; %00000
	.db '4'		;; %00001
	.db CHR_ACK	;; %00010 (Understood)
	.db '3'		;; %00011
	.db $0		;; %00100
	.db $0		;; %00101
	.db $0		;; %00110
	.db '2'		;; %00111
	.db '&'		;; %01000 (Wait)
	.db $0		;; %01001
	.db '+'		;; %01010
	.db $0		;; %01011
	.db $0		;; %01100
	.db $0		;; %01101
	.db $0		;; %01110
	.db '1'		;; %01111
	.db '6'		;; %10000
	.db '='		;; %10001
	.db '/'		;; %10010
	.db $0		;; %10011
	.db $0		;; %10100
	.db CHR_START	;; %10101 (Starting Signal)
	.db '('		;; %10110
	.db $0		;; %10111
	.db '7'		;; %11000
	.db $0		;; %11001
	.db $0		;; %11010
	.db $0		;; %11011
	.db '8'		;; %11100
	.db $0		;; %11101
	.db '9'		;; %11110
	.db '0'		;; %11111
	.db $0		;; %000000
	.db $0		;; %000001
	.db $0		;; %000010
	.db $0		;; %000011
	.db $0		;; %000100
	.db CHR_TERM	;; %000101 (End of work)
	.db $0		;; %000110
	.db $0		;; %000111
	.db $0		;; %001000
	.db $0		;; %001001
	.db $0		;; %001010
	.db $0		;; %001011
	.db '?'		;; %001100
	.db '_'		;; %001101
	.db $0		;; %001110
	.db $0		;; %001111
	.db $0		;; %010000
	.db $0		;; %010001
	.db $22		;; %010010 (")
	.db $0		;; %010011
	.db $0		;; %010100
	.db '.'		;; %010101
	.db $0		;; %010110
	.db $0		;; %010111
	.db $0		;; %011000
	.db $0		;; %011001
	.db '@'		;; %011010
	.db $0		;; %011011
	.db $0		;; %011100
	.db $0		;; %011101
	.db $27		;; %011110 (')
	.db $0		;; %011111
	.db $0		;; %100000
	.db '-'		;; %100001
	.db $0		;; %100010
	.db $0		;; %100011
	.db $0		;; %100100
	.db $0		;; %100101
	.db $0		;; %100110
	.db $0		;; %100111
	.db $0		;; %101000
	.db $0		;; %101001
	.db $3B		;; %101010 (;)
	.db '!'		;; %101011
	.db $0		;; %101100
	.db ')'		;; %101101
	.db $0		;; %101110
	.db $0		;; %101111
	.db $0		;; %110000
	.db $0		;; %110001
	.db $0		;; %110010
	.db ','		;; %110011
	.db $0		;; %110100
	.db $0		;; %110101
	.db $0		;; %110110
	.db $0		;; %110111
	.db ':'		;; %111000
	.db $0		;; %111001
	.db $0		;; %111010
	.db $0		;; %111011
	.db $0		;; %111100
	.db $0		;; %111101
	.db $0		;; %111110
	.db $0		;; %111111
;	.db '$'		;; %0001001
;	.db CHR_ERROR	;; %00000000 (Error)

;; 特殊な欧文文字については、transliteration (逐字訳)の機能を待つべきと
;; する。jrf_semaphore においては、'&' + ビット列で、ASCII コードを入力
;; できるとする。ビット列の長さは8ビットまでで、UTF-8 コードと解釈する。
;; カタカナ入力も UTF-8 の必要がある(表示はされない。これも
;; transliteration を待つべき。)
;;
;; 英文字は小文字がデフォルトで、'_' + 文字だと大文字になる。'_' + 記号
;; は、下のような記号になる。これらは transliteration に都合がよい。
;;
;; As for international characters, you should expect transliteration.
;; In the jrf_semaphore, you can input an ascii character code by '&'
;; + bits("·"=0,"–"=1)-word.  If 8bits-word is greater than 0x7F, it
;; is interpreted as UTF-8.  So, unicode of 0x80-0xFF must also be
;; coded by UTF-8 (or expect transliteraton).
;;
;; Letters are lower case in default.  '_' + Letters give upper case.
;; '_' + Symbols give other symbols useful for transliteration:
;;
;;   '_' + '_' -> '_',
;;
;;   '_' + '&' -> '&',
;;
;;   '_' + '$' -> '$',
;;
;;   '_' + '"' -> '^',
;;
;;   '_' + "'" -> '`',
;;
;;   '_' + '-' -> '~',
;;
;;   '_' + '/' -> $5C (backslash).
;;

MorseCodeLetterTable:	;; $20 - $5F
	.db 0, %0	;;  
	.db 6, %101011	;; !
	.db 6, %010010	;; "
	.db 0, %0	;; #
	.db 7, %0001001	;; $
	.db 0, %0	;; %
	.db 5, %01000	;; &
	.db 6, %011110	;; '
	.db 5, %10110	;; (
	.db 6, %101101	;; )
	.db 0, %0	;; *
	.db 5, %01010	;; +
	.db 6, %110011	;; ,
	.db 6, %100001	;; -
	.db 6, %010101	;; .
	.db 5, %10010	;; /
	.db 5, %11111	;; 0
	.db 5, %01111	;; 1
	.db 5, %00111	;; 2
	.db 5, %00011	;; 3
	.db 5, %00001	;; 4
	.db 5, %00000	;; 5
	.db 5, %10000	;; 6
	.db 5, %11000	;; 7
	.db 5, %11100	;; 8
	.db 5, %11110	;; 9
	.db 6, %111000	;; :
	.db 6, %101010	;; ;
	.db 0, %0	;; <
	.db 5, %10001	;; =
	.db 0, %0	;; >
	.db 6, %001100	;; ?
	.db 6, %011010	;; @
	.db 2, %01	;; A
	.db 4, %1000	;; B
	.db 4, %1010	;; C
	.db 3, %100	;; D
	.db 1, %0	;; E
	.db 4, %0010	;; F
	.db 3, %110	;; G
	.db 4, %0000	;; H
	.db 2, %00	;; I
	.db 4, %0111	;; J
	.db 3, %101	;; K
	.db 4, %0100	;; L
	.db 2, %11	;; M
	.db 2, %10	;; N
	.db 3, %111	;; O
	.db 4, %0110	;; P
	.db 4, %1101	;; Q
	.db 3, %010	;; R
	.db 3, %000	;; S
	.db 1, %1	;; T
	.db 3, %001	;; U
	.db 4, %0001	;; V
	.db 3, %011	;; W
	.db 4, %1001	;; X
	.db 4, %1011	;; Y
	.db 4, %1100	;; Z
	.db 0, %0	;; [
	.db 0, %0	;; \
	.db 0, %0	;; ]
	.db 0, %0	;; ^
	.db 6, %001101	;; _


;; パレットテーブル
Palette:
	.incbin	"jrf_semaphore.dat"
SailorPalette:
	.incbin	"sailor_pal.dat"
PaletteEnd:
PaletteSize:
	.db PaletteEnd - Palette, $00

;; キャラクター
Logo:	
	.db 0, $02, $03, $12, $13
LogoBG:	
	.db 3, $01, $01, $01, $01

;; パブリックドメインになった本の検印だからといって、誰もが使っていいわ
;; けではない。同様にこのロゴがどこかの画像に含まれていたからといって何
;; の問題もないが、それを「自分」の印として使うなら、その(宗教的な)意味
;; までよく考えほうがいい。

;; A seal or stamp on a page of public-domained books doesn't apply to
;; everybody's use.  Similarly, it is no problem for me to see this
;; logo anywhere else, but you had better to think its (religious)
;; meaning when using it as the seal of 'yourself'.

SailorChr:
;; M: Male(Bold), F: Female(Normal), N: Normal, S: Slant.
SailorFNU:
        .db 1, $84, $85, $94, $95
SailorFNL:
        .db 1, $88, $89, $98, $99

SailorFSU:
        .db 1, $84, $85, $94, $95
SailorFSL:
        .db 1, $8c, $8d, $9c, $9d

SailorMNU:
        .db 1, $86, $87, $96, $97
SailorMNL:
        .db 1, $8a, $8b, $9a, $9b

SailorMSU:
        .db 1, $86, $87, $96, $97
SailorMSL:
        .db 1, $8e, $8f, $9e, $9f

FlagChr:
;; N: Normal, I: Italic, L: Left flag in right arm, R: Right flag in left arm.
;; 0: South(Lower) -> 4: North(Upper) -> (8: South)
FlagNL0:
        .db $03, $00, $15, $00, $16
FlagNL1:
        .db $03, $0e, $0f, $1e, $1f
FlagNL2:
        .db $03, $06, $05, $00, $00
FlagNL3:
        .db $03, $0c, $0d, $1c, $1d
FlagNL4:
        .db $03, $00, $16, $00, $14
FlagNL5:
        .db $43, $0d, $0c, $1d, $1c
FlagNL6:
        .db $43, $05, $06, $00, $00
FlagNL7:
        .db $43, $0f, $0e, $1f, $1e

FlagNR0:
        .db $41, $15, $00, $16, $00
FlagNR1:
        .db $41, $0f, $0e, $1f, $1e
FlagNR2:
        .db $41, $05, $06, $00, $00
FlagNR3:
        .db $41, $0d, $0c, $1d, $1c
FlagNR4:
        .db $41, $16, $00, $14, $00
FlagNR5:
        .db $01, $0c, $0d, $1c, $1d
FlagNR6:
        .db $01, $06, $05, $00, $00
FlagNR7:
        .db $01, $0e, $0f, $1e, $1f

FlagIL0:
        .db $03, $00, $15, $00, $17
FlagIL1:
        .db $03, $0a, $0b, $1a, $1b
FlagIL2:
        .db $03, $07, $05, $00, $00
FlagIL3:
        .db $03, $08, $09, $18, $19
FlagIL4:
        .db $03, $00, $17, $00, $14
FlagIL5:
        .db $43, $09, $08, $19, $18
FlagIL6:
        .db $43, $05, $07, $00, $00
FlagIL7:
        .db $43, $0b, $0a, $1b, $1a

FlagIR0:
        .db $41, $15, $00, $17, $00
FlagIR1:
        .db $41, $0b, $0a, $1b, $1a
FlagIR2:
        .db $41, $05, $07, $00, $00
FlagIR3:
        .db $41, $09, $08, $19, $18
FlagIR4:
        .db $41, $17, $00, $14, $00
FlagIR5:
        .db $01, $08, $09, $18, $19
FlagIR6:
        .db $01, $07, $05, $00, $00
FlagIR7:
        .db $01, $0a, $0b, $1a, $1b

FlagLoc:
;; 旗相対位置
;; L: Left flag in right arm, R: Right flag in left arm.
;; 0: South(Lower) -> 4: North(Upper) -> (8: South)
FlagL0:
	.db -16 + 4, 0 + 7
FlagL1:
	.db -16 + 4, 0 + 7
FlagL2:
	.db -16 + 4, 0 + 6
FlagL3:
	.db -16 + 4, -16 + 6
FlagL4:
	.db -16 + 5, -16 + 6
FlagL5:
	.db 0 + 4, -16 + 6
FlagL6:
	.db 0 + 4, 0 + 7
FlagL7:
	.db 0 + 3, 0 + 8

FlagR0:
	.db 16 - 4, 0 + 7
FlagR1:
	.db 16 - 4, 0 + 7
FlagR2:
	.db 16 - 4, 0 + 6
FlagR3:
	.db 16 - 4, -16 + 6
FlagR4:
	.db 16 - 5, -16 + 6
FlagR5:
	.db 0 - 4, -16 + 6
FlagR6:
	.db 0 - 4, 0 + 7
FlagR7:
	.db 0 - 3, 0 + 8

ModeTable:
	.dw Start
	.dw MDReinit
	.dw MDInput
	.dw MDReplay
	.dw MDMorseDot
	.dw MDShortCancel

SpecialKeyTable:
	.dw SKeyStart
	.dw SKeySelect
	.dw SKey1B
	.dw SKey1A
	.dw SKey1A		;; redirect 1P A to 2P START
	.dw SKeySelect
	.dw SKey2B
	.dw SKey2A
	
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

UBarMorseCode:
	.db '_', '&', '$', $27, $22, '-', '/'
UBarMorseCodeEnd:
	.db "         "
UBarMorseCodeT:
	.db '_', '&', '$', '`', '^', '~', $5C
	.db "         "

ReplayInitial:
	.db "jrf c ", $0
	.db "         "
	.db "                "

LoadErrorMessage:
	.db "This messege appears when you load without saving"
	.db " or your save has been broken. (Sorry.)", $0

  .if DebugLevel > 0
;; 表示文字列
HELLO_STRING:
	.db	"HELLO, WORLD!"
  .endif

ZeroPageInitValue:
_SystemSwitch:
	.db UseFont8x16 + UseToPrintable * 2 + UseRightToLeft * 4 + (2 + UseMapper3) * 16
;	.db UseFont8x16 + UseToPrintable * 2 + UseRightToLeft * 4 + (0 + UseMapper3) * 16
_BankMask:
	.db $03
_RandPrime:
	.db 89
_LoadCost:
	.db 1
_UBarMorseCodeLen:
	.db UBarMorseCodeEnd - UBarMorseCode
_DisplayChr:
	.db CHR_MORSE_DOT
	.db CHR_MORSE_DASH
	.db CHR_MORSE_SPC
	.db CHR_MORSE_UBAR
	.db CHR_MORSE_AMP
	.db CHR_MORSE_DOL

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

;; マッパ３では、CHR ROM バンクは 4 つまでが標準で、下記のウェブページ
;; によると、バス競合を避けるには、$30 から $34 の値を、そのデータがあ
;; る PRG ROM に書き込むのが正しいらしい。このプログラムでは、だから、
;; バンク切り替えは、BankStr + バンク番号を読み出して、それをそのままそ
;; こに書き込んでいる。ただ、これは、エミュレータを使う分にはほぼ関係が
;; ないので、ineschr を 4 より大きくして、BankStr の $30 とかを別の数字
;; に書き換えちゃえばいいはず。

;; For Mapper 3, CHR ROM banks should be le than 4 (ref. the web page
;; below) and you should change banks by writing bank_num added with
;; $30 to PRG ROM Address of the same value.  This program changes
;; banks by reading BankStr + bank_num and write itself to BankStr +
;; bank_num.  Perhaps, with emulators, you can rewrite, for example,
;; $30 to $00 or $5 or more.
;;
;;《Enri's Home PAGE (ファミリーコンピューター　ＲＯＭカセット　マッパー３)》
;;http://www43.tok2.com/home/cmpslv/Famic/Fcmp3.htm

BankStr:
	.db $30, $31, $32, $33, $34, $35, $36, $37
	.db $38, $39, $3A, $3B, $3C, $3D, $3E, $3F

;; ToPrintableTable はバンクごとにそれぞれ６バイトからなり、３バイトが
;; 8x8 フォント用、残り３バイトが 8x16 フォント用になる。３バイトのうち、
;; 最初の二つが Printable な範囲で、もう一つが NonPrintable を表すため
;; の文字コードとなる。
;; 
;; Each ToPrintableTable consists of 6 bytes per bank where 3 bytes
;; for 8x8 font, 3bytes for 8x16 font.  Each 3 bytes consists of 2
;; bytes of Printable range and 1 byte of character code for NonPrintables.

ToPrintableTables:
ToPrintableTable_0:
	.db $20, $7E, $7F, $20, $7E, $7F
ToPrintableTable_1:
	.db $20, $FE, $FF, $00, $7F, $7F
ToPrintableTable_2:
	.db $20, $7E, $7F, $20, $7E, $00
ToPrintableTable_3:
	.db $20, $7E, $7F, $A0, $FE, $00
ToPrintableTable_4to15:
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00
	.db $20, $7E, $7F, $20, $7E, $00

;; PublicUse のデータはこの ROM プログラムでは使わないが、
;; jrf_semaphore.pl や jsnes_fc_ui.js といった他のプログラムが使うのに
;; 便利なようにこの ROM に含めてある。
;;
;; PublicUse data is not used in this ROM program, but provided
;; for other programs like jrf_semaphore.pl or jsnes_fc_ui.js.
PublicUse:
FontName_0_0:
	FontNameRes .db, 0
	.db $0
FontName_0_1:
	FontNameRes .db, 1
	.db $0
FontName_1_0:
	FontNameRes .db, 2
	.db $0
FontName_1_1:
	FontNameRes .db, 3
	.db $0
FontName_2_0:
	FontNameRes .db, 4
	.db $0
FontName_2_1:
	FontNameRes .db, 5
	.db $0
FontName_3_0:
	FontNameRes .db, 6
	.db $0
FontName_3_1:
	FontNameRes .db, 7
	.db $0
PublicUseEnd:
	


;; バックアップ RAM
;	.org $6000
BackUpRamStart = $6000	
BackUpRamCheck = BackUpRamStart
TextSaveInfoStart = BackUpRamStart + $10
TextSaveLen = TextSaveInfoStart
LoadCount = TextSaveLen + 1
RandSeed = LoadCount + 1
SavedSwitch = RandSeed + 1
FontSaveBuf = SavedSwitch + 1
ColorSaveBuf = FontSaveBuf + 1
TextSaveInfoEnd = ColorSaveBuf + 1
BitsSaveInfoStart = TextSaveInfoStart + $10
BitsPointSave = BitsSaveInfoStart
BitsMarkSave = BitsPointSave + 2
BitsSaveInfoEnd = BitsMarkSave + 2
TextSaveBuf = BackUpRamStart + $100
BitsSaveBuf = TextSaveBuf + $100
  .if TextSaveInfoEnd > BitsSaveInfoStart
	fail "TextInfoSaveEnd exceeds BitsInfoStart."
  .endif


;; パターンテーブル
	.bank 2
        .org    $0000
	FontNameRes .incbin, 0
	FontNameRes .incbin, 1
	.bank 3
        .org    $0000
	FontNameRes .incbin, 2
	FontNameRes .incbin, 3
	.bank 4
        .org    $0000
	FontNameRes .incbin, 4
	FontNameRes .incbin, 5
	.bank 5
        .org    $0000
	FontNameRes .incbin, 6
	FontNameRes .incbin, 7
