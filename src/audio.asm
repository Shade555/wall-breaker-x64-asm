; =============================================================================
; audio.asm - Procedural Retro 8-bit PCM WAV Synthesizer & Playback (GoAsm x64)
; =============================================================================

#include constants.inc

CODE SECTION

; -----------------------------------------------------------------------------
; InitAudio: Allocates 64KB buffer and generates 9 procedural PCM WAV effects
; -----------------------------------------------------------------------------
InitAudio FRAME
USES RBX, RSI, RDI, R12

    INVOKE VirtualAlloc, 0, 65536, MEM_COMMIT + MEM_RESERVE, PAGE_READWRITE
    TEST RAX, RAX
    JZ >>.fail
    MOV [gSfxBase], RAX
    MOV R12, RAX

    LEA RBX, [gSfxPtrs]

    ; 0: SFX_PADDLE - crisp upward chirp (1500 samples)
    MOV [RBX + 0*8], R12
    INVOKE BuildWavTone, R12, 1500, 380, 620, 0, 56
    ADD R12, 6144

    ; 1: SFX_BRICK - chip pop (1200 samples)
    MOV [RBX + 1*8], R12
    INVOKE BuildWavTone, R12, 1200, 540, 420, 0, 52
    ADD R12, 6144

    ; 2: SFX_STEEL - metallic ping (1900 samples)
    MOV [RBX + 2*8], R12
    INVOKE BuildWavTone, R12, 1900, 1320, 1180, 0, 48
    ADD R12, 6144

    ; 3: SFX_BREAK - shatter burst (2200 samples)
    MOV [RBX + 3*8], R12
    INVOKE BuildWavTone, R12, 2200, 620, 980, 1, 56
    ADD R12, 6144

    ; 4: SFX_POWERUP - bright rising chime (4400 samples)
    MOV [RBX + 4*8], R12
    INVOKE BuildWavArp, R12, 4400, 523, 659, 784, 1046
    ADD R12, 6144

    ; 5: SFX_LASER - sci-fi laser pew (1800 samples)
    MOV [RBX + 5*8], R12
    INVOKE BuildWavTone, R12, 1800, 1500, 320, 0, 50
    ADD R12, 6144

    ; 6: SFX_EXPLODE - heavy blast + noise (5400 samples)
    MOV [RBX + 6*8], R12
    INVOKE BuildWavTone, R12, 5400, 210, 48, 2, 78
    ADD R12, 6144

    ; 7: SFX_LOSE - descending fail tones (5200 samples)
    MOV [RBX + 7*8], R12
    INVOKE BuildWavArp, R12, 5200, 392, 311, 247, 175
    ADD R12, 6144

    ; 8: SFX_LEVELUP - victory fanfare (5800 samples)
    MOV [RBX + 8*8], R12
    INVOKE BuildWavArp, R12, 5800, 523, 659, 784, 1175

.fail:
    RET
ENDF

; -----------------------------------------------------------------------------
; WriteWavHeader(pBuf, numSamples) -> returns pointer to PCM data in RAX
; -----------------------------------------------------------------------------
WriteWavHeader FRAME pBuf, numSamples
    MOV RAX, [pBuf]
    MOV ECX, [numSamples]

    MOV D[RAX + 0], 'RIFF'
    LEA EDX, [ECX + 36]
    MOV D[RAX + 4], EDX
    MOV D[RAX + 8], 'WAVE'
    MOV D[RAX + 12], 'fmt '
    MOV D[RAX + 16], 16         ; fmt chunk size
    MOV W[RAX + 20], 1          ; PCM = 1
    MOV W[RAX + 22], 1          ; Mono = 1
    MOV D[RAX + 24], 22050      ; Sample rate
    MOV D[RAX + 28], 22050      ; Byte rate
    MOV W[RAX + 32], 1          ; Block align
    MOV W[RAX + 34], 8          ; Bits per sample
    MOV D[RAX + 36], 'data'
    MOV D[RAX + 40], ECX        ; Data chunk size
    ADD RAX, 44
    RET
ENDF

; -----------------------------------------------------------------------------
; BuildWavTone(pBuf, numSamples, fStart, fEnd, noiseMode, amp)
; noiseMode: 0=pure square, 1=light grit, 2=heavy explosion noise
; -----------------------------------------------------------------------------
BuildWavTone FRAME pBuf, numSamples, fStart, fEnd, noiseMode, amp
USES RBX, RSI, RDI, R12, R13, R14, R15

    INVOKE WriteWavHeader, [pBuf], [numSamples]
    MOV RDI, RAX                ; RDI = PCM sample output pointer

    MOV R12D, [numSamples]      ; N
    XOR ESI, ESI                ; i = 0
    XOR EBX, EBX                ; 32-bit phase accumulator
    MOV R13D, 13572468h         ; local PRNG for noise

.loop:
    CMP ESI, R12D
    JGE >>.done

    ; Interpolate freq = fStart + (fEnd - fStart) * i / N
    MOV EAX, [fEnd]
    SUB EAX, [fStart]
    IMUL EAX, ESI
    CDQ
    IDIV R12D
    ADD EAX, [fStart]
    CMP EAX, 20
    JGE >.f_ok
    MOV EAX, 20
.f_ok:
    ; phaseStep = freq * (65536 * 65536 / 22050) ~= freq * 194772
    IMUL RAX, RAX, 194772
    ADD EBX, EAX

    ; Envelope: enc = amp * (N - i) / N
    MOV EAX, R12D
    SUB EAX, ESI
    IMUL EAX, [amp]
    XOR EDX, EDX
    DIV R12D
    MOV R14D, EAX               ; current amplitude (0..amp)

    ; Square wave polarity from MSB of EBX
    TEST EBX, 80000000h
    JZ >.pos_half
    NEG R14D
.pos_half:

    ; Apply noise if noiseMode > 0
    MOV ECX, [noiseMode]
    TEST ECX, ECX
    JZ >.store_sample

    IMUL R13D, R13D, 1103515245
    ADD R13D, 12345
    MOV EAX, R13D
    SHR EAX, 24
    AND EAX, 3Fh
    SUB EAX, 32                 ; -32..+31 noise
    CMP ECX, 2
    JE >.heavy_noise
    SAR EAX, 1
    ADD R14D, EAX
    JMP >.store_sample
.heavy_noise:
    ; Mix noise scaled by envelope
    MOV ECX, R12D
    SUB ECX, ESI
    IMUL EAX, ECX
    CDQ
    IDIV R12D
    ADD R14D, EAX

.store_sample:
    ADD R14D, 128
    CMP R14D, 0
    JGE >.clamp_hi
    XOR R14D, R14D
.clamp_hi:
    CMP R14D, 255
    JLE >.write_byte
    MOV R14D, 255
.write_byte:
    MOV EAX, R14D
    MOV [RDI + RSI], AL
    INC ESI
    JMP <.loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; BuildWavArp(pBuf, numSamples, f0, f1, f2, f3) - 4-note arpeggio
; -----------------------------------------------------------------------------
BuildWavArp FRAME pBuf, numSamples, f0, f1, f2, f3
USES RBX, RSI, RDI, R12, R13

    INVOKE WriteWavHeader, [pBuf], [numSamples]
    MOV RDI, RAX

    MOV R12D, [numSamples]
    XOR ESI, ESI
    XOR EBX, EBX

.loop:
    CMP ESI, R12D
    JGE >>.done

    ; Note index 0..3 = (i * 4) / N
    MOV EAX, ESI
    SHL EAX, 2
    XOR EDX, EDX
    DIV R12D
    CMP EAX, 0
    JNE >.n1
    MOV EAX, [f0]
    JMP >.got_f
.n1:
    CMP EAX, 1
    JNE >.n2
    MOV EAX, [f1]
    JMP >.got_f
.n2:
    CMP EAX, 2
    JNE >.n3
    MOV EAX, [f2]
    JMP >.got_f
.n3:
    MOV EAX, [f3]
.got_f:
    IMUL RAX, RAX, 194772
    ADD EBX, EAX

    ; Envelope decay
    MOV EAX, R12D
    SUB EAX, ESI
    IMUL EAX, 58
    XOR EDX, EDX
    DIV R12D
    TEST EBX, 80000000h
    JZ >.pos
    NEG EAX
.pos:
    ADD EAX, 128
    MOV B[RDI + RSI], AL
    INC ESI
    JMP <.loop

.done:
    RET
ENDF

; -----------------------------------------------------------------------------
; PlaySfx(sfxId) - Non-blocking async WAV trigger
; -----------------------------------------------------------------------------
PlaySfx FRAME sfxId
    CMP D[gMuted], 0
    JNE >.done
    MOV EAX, [sfxId]
    CMP EAX, 0
    JL >.done
    CMP EAX, 8
    JG >.done
    LEA RCX, [gSfxPtrs]
    MOV RAX, [RCX + RAX*8]
    TEST RAX, RAX
    JZ >.done
    INVOKE PlaySoundA, RAX, 0, SND_PLAY_FLAGS
.done:
    RET
ENDF
