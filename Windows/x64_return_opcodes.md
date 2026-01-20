# x64 Windows Return Opcode Variants

A comprehensive collection of creative ways to achieve a return in x64 Windows assembly.

---

## Table of Contents

1. [LODSQ Explanation](#lodsq-explanation)
2. [Standard Returns](#standard-returns)
3. [Pop + Jmp Register](#pop--jmp-register)
4. [Pop + Call Register](#pop--call-register)
5. [Pop + Push + Ret](#pop--push--ret)
6. [XCHG Variants](#xchg-variants)
7. [Double XCHG](#double-xchg)
8. [MOV reg,reg Chains](#mov-regreg-chains)
9. [LEA Variants](#lea-variants)
10. [LEA with Displacement](#lea-with-displacement)
11. [Arithmetic No-ops](#arithmetic-no-ops)
12. [Increment/Decrement Cancel](#incrementdecrement-cancel)
13. [NOT NOT (Double Negation)](#not-not-double-negation)
14. [Rotate Cancel](#rotate-cancel)
15. [Shift Cancel](#shift-cancel)
16. [BSWAP BSWAP](#bswap-bswap)
17. [XOR Patterns](#xor-patterns)
18. [CMOVcc Conditional Move](#cmovcc-conditional-move)
19. [SETcc Tricks](#setcc-tricks)
20. [LODSQ Variants](#lodsq-variants)
21. [LODSD 32-bit](#lodsd-32-bit)
22. [MOVSQ Abuse](#movsq-abuse)
23. [STOSQ Then Load Back](#stosq-then-load-back)
24. [Stack Pointer Games](#stack-pointer-games)
25. [RSP with SIB Byte](#rsp-with-sib-byte)
26. [Indirect Jmp [rsp]](#indirect-jmp-rsp)
27. [NOP Sleds](#nop-sleds)
28. [LEAVE Variants](#leave-variants)
29. [ENTER Then LEAVE](#enter-then-leave)
30. [Push Immediate Then Add RSP](#push-immediate-then-add-rsp)
31. [PUSHFQ/POPFQ Flags Dance](#pushfqpopfq-flags-dance)
32. [SAHF/LAHF](#sahflahf)
33. [CPUID Clobber](#cpuid-clobber)
34. [RDTSC Clobber](#rdtsc-clobber)
35. [XGETBV Clobber](#xgetbv-clobber)
36. [Segment Register Abuse](#segment-register-abuse)
37. [String Prefix](#string-prefix)
38. [Redundant REX Prefixes](#redundant-rex-prefixes)
39. [Segment Override Prefixes](#segment-override-prefixes)
40. [Operand Size Prefix](#operand-size-prefix)
41. [Address Size Prefix](#address-size-prefix)
42. [Multiple Useless Prefixes](#multiple-useless-prefixes)
43. [PUSH/POP RSP Weirdness](#pushpop-rsp-weirdness)
44. [Self-XOR Patterns](#self-xor-patterns)
45. [POPCNT Abuse](#popcnt-abuse)
46. [LZCNT Abuse](#lzcnt-abuse)
47. [TZCNT Abuse](#tzcnt-abuse)
48. [BSF/BSR](#bsfbsr)
49. [BT/BTS/BTR/BTC Bit Test](#btbtsbtrbtc-bit-test)
50. [ANDN (BMI1)](#andn-bmi1)
51. [BLSI/BLSR/BLSMSK (BMI1)](#blsiblsrblsmsk-bmi1)
52. [PDEP/PEXT (BMI2)](#pdeppext-bmi2)
53. [ADC/SBB with Carry](#adcsbb-with-carry)
54. [CLC/STC/CMC Dance](#clcstccmc-dance)
55. [CLD/STD Direction Flag](#cldstd-direction-flag)
56. [Store to Stack Load Back](#store-to-stack-load-back)
57. [Triple Indirect](#triple-indirect)
58. [Conditional Jump Over Ret](#conditional-jump-over-ret)
59. [CALL Next Instruction](#call-next-instruction)
60. [LOOP That Doesn't Loop](#loop-that-doesnt-loop)
61. [REP Prefix on Non-String](#rep-prefix-on-non-string)

---

## LODSQ Explanation

`LODSQ` (Load String Quadword) is a string instruction that:

1. Reads 8 bytes from the address in `RSI`
2. Stores them in `RAX`
3. Increments or decrements `RSI` by 8 (depending on direction flag)

So if you point `RSI` at the stack where the return address lives, `LODSQ` will load it into `RAX`. Then you just jump to `RAX`.

```nasm
mov rsi, rsp      ; point RSI at stack (where return addr is)
lodsq             ; RAX = [RSI], RSI += 8
; now RSI has moved past the return address, but RSP hasn't
lea rsp, [rsp+8]  ; fix stack pointer (or add rsp, 8)
jmp rax           ; jump to return address
```

The catch: `RSI` gets modified but `RSP` doesn't automatically, so you need to fix the stack manually.

---

## Standard Returns

```c
{ 0xC3 };                                                              // ret
{ 0xC2, 0x00, 0x00 };                                                  // ret 0
{ 0xC2, 0x08, 0x00 };                                                  // ret 8 (if you pushed something)
```

---

## Pop + Jmp Register

```c
{ 0x58, 0xFF, 0xE0 };                                                  // pop rax; jmp rax
{ 0x59, 0xFF, 0xE1 };                                                  // pop rcx; jmp rcx
{ 0x5A, 0xFF, 0xE2 };                                                  // pop rdx; jmp rdx
{ 0x5B, 0xFF, 0xE3 };                                                  // pop rbx; jmp rbx
{ 0x5C, 0xFF, 0xE4 };                                                  // pop rsp; jmp rsp (cursed)
{ 0x5D, 0xFF, 0xE5 };                                                  // pop rbp; jmp rbp
{ 0x5E, 0xFF, 0xE6 };                                                  // pop rsi; jmp rsi
{ 0x5F, 0xFF, 0xE7 };                                                  // pop rdi; jmp rdi
{ 0x41, 0x58, 0x41, 0xFF, 0xE0 };                                      // pop r8; jmp r8
{ 0x41, 0x59, 0x41, 0xFF, 0xE1 };                                      // pop r9; jmp r9
{ 0x41, 0x5A, 0x41, 0xFF, 0xE2 };                                      // pop r10; jmp r10
{ 0x41, 0x5B, 0x41, 0xFF, 0xE3 };                                      // pop r11; jmp r11
{ 0x41, 0x5C, 0x41, 0xFF, 0xE4 };                                      // pop r12; jmp r12
{ 0x41, 0x5D, 0x41, 0xFF, 0xE5 };                                      // pop r13; jmp r13
{ 0x41, 0x5E, 0x41, 0xFF, 0xE6 };                                      // pop r14; jmp r14
{ 0x41, 0x5F, 0x41, 0xFF, 0xE7 };                                      // pop r15; jmp r15
```

---

## Pop + Call Register

```c
{ 0x58, 0xFF, 0xD0 };                                                  // pop rax; call rax
{ 0x59, 0xFF, 0xD1 };                                                  // pop rcx; call rcx
{ 0x5A, 0xFF, 0xD2 };                                                  // pop rdx; call rdx
{ 0x5B, 0xFF, 0xD3 };                                                  // pop rbx; call rbx
{ 0x5E, 0xFF, 0xD6 };                                                  // pop rsi; call rsi
{ 0x5F, 0xFF, 0xD7 };                                                  // pop rdi; call rdi
{ 0x41, 0x58, 0x41, 0xFF, 0xD0 };                                      // pop r8; call r8
{ 0x41, 0x59, 0x41, 0xFF, 0xD1 };                                      // pop r9; call r9
```

---

## Pop + Push + Ret

```c
{ 0x58, 0x50, 0xC3 };                                                  // pop rax; push rax; ret
{ 0x59, 0x51, 0xC3 };                                                  // pop rcx; push rcx; ret
{ 0x5A, 0x52, 0xC3 };                                                  // pop rdx; push rdx; ret
{ 0x5B, 0x53, 0xC3 };                                                  // pop rbx; push rbx; ret
{ 0x5D, 0x55, 0xC3 };                                                  // pop rbp; push rbp; ret
{ 0x5E, 0x56, 0xC3 };                                                  // pop rsi; push rsi; ret
{ 0x5F, 0x57, 0xC3 };                                                  // pop rdi; push rdi; ret
{ 0x41, 0x58, 0x41, 0x50, 0xC3 };                                      // pop r8; push r8; ret
{ 0x41, 0x59, 0x41, 0x51, 0xC3 };                                      // pop r9; push r9; ret
```

---

## XCHG Variants

```c
{ 0x58, 0x48, 0x91, 0xFF, 0xE1 };                                      // pop rax; xchg rax,rcx; jmp rcx
{ 0x58, 0x48, 0x92, 0xFF, 0xE2 };                                      // pop rax; xchg rax,rdx; jmp rdx
{ 0x58, 0x48, 0x93, 0xFF, 0xE3 };                                      // pop rax; xchg rax,rbx; jmp rbx
{ 0x58, 0x48, 0x94, 0xFF, 0xE4 };                                      // pop rax; xchg rax,rsp; jmp rsp (extremely cursed)
{ 0x58, 0x48, 0x95, 0xFF, 0xE5 };                                      // pop rax; xchg rax,rbp; jmp rbp
{ 0x58, 0x48, 0x96, 0xFF, 0xE6 };                                      // pop rax; xchg rax,rsi; jmp rsi
{ 0x58, 0x48, 0x97, 0xFF, 0xE7 };                                      // pop rax; xchg rax,rdi; jmp rdi
{ 0x59, 0x48, 0x91, 0xFF, 0xE0 };                                      // pop rcx; xchg rcx,rax; jmp rax
{ 0x5A, 0x48, 0x92, 0xFF, 0xE0 };                                      // pop rdx; xchg rdx,rax; jmp rax
```

---

## Double XCHG

```c
{ 0x58, 0x48, 0x91, 0x48, 0x92, 0xFF, 0xE2 };                          // pop rax; xchg rax,rcx; xchg rax,rdx; jmp rdx
{ 0x58, 0x48, 0x91, 0x48, 0x91, 0xFF, 0xE0 };                          // pop rax; xchg rax,rcx; xchg rax,rcx; jmp rax
```

---

## MOV reg,reg Chains

```c
{ 0x58, 0x48, 0x89, 0xC1, 0xFF, 0xE1 };                                // pop rax; mov rcx,rax; jmp rcx
{ 0x58, 0x48, 0x89, 0xC2, 0xFF, 0xE2 };                                // pop rax; mov rdx,rax; jmp rdx
{ 0x58, 0x48, 0x89, 0xC3, 0xFF, 0xE3 };                                // pop rax; mov rbx,rax; jmp rbx
{ 0x58, 0x48, 0x89, 0xC6, 0xFF, 0xE6 };                                // pop rax; mov rsi,rax; jmp rsi
{ 0x58, 0x48, 0x89, 0xC7, 0xFF, 0xE7 };                                // pop rax; mov rdi,rax; jmp rdi
{ 0x58, 0x48, 0x89, 0xC1, 0x48, 0x89, 0xCA, 0xFF, 0xE2 };              // pop rax; mov rcx,rax; mov rdx,rcx; jmp rdx
{ 0x58, 0x48, 0x89, 0xC1, 0x48, 0x89, 0xCE, 0x48, 0x89, 0xF7, 0xFF, 0xE7 };  // pop rax; mov rcx,rax; mov rsi,rcx; mov rdi,rsi; jmp rdi
```

---

## LEA Variants

```c
{ 0x58, 0x48, 0x8D, 0x08, 0xFF, 0xE1 };                                // pop rax; lea rcx,[rax]; jmp rcx
{ 0x58, 0x48, 0x8D, 0x10, 0xFF, 0xE2 };                                // pop rax; lea rdx,[rax]; jmp rdx
{ 0x58, 0x48, 0x8D, 0x18, 0xFF, 0xE3 };                                // pop rax; lea rbx,[rax]; jmp rbx
{ 0x59, 0x48, 0x8D, 0x01, 0xFF, 0xE0 };                                // pop rcx; lea rax,[rcx]; jmp rax
{ 0x5A, 0x48, 0x8D, 0x02, 0xFF, 0xE0 };                                // pop rdx; lea rax,[rdx]; jmp rax
{ 0x58, 0x48, 0x8D, 0x40, 0x00, 0xFF, 0xE0 };                          // pop rax; lea rax,[rax+0]; jmp rax
{ 0x58, 0x48, 0x8D, 0x80, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xE0 };        // pop rax; lea rax,[rax+0x00000000]; jmp rax
```

---

## LEA with Displacement

```c
{ 0x58, 0x48, 0x8D, 0x48, 0x00, 0xFF, 0xE1 };                          // pop rax; lea rcx,[rax+0]; jmp rcx
{ 0x58, 0x48, 0x8D, 0x50, 0x00, 0xFF, 0xE2 };                          // pop rax; lea rdx,[rax+0]; jmp rdx
```

---

## Arithmetic No-ops

```c
{ 0x58, 0x48, 0x83, 0xC0, 0x00, 0xFF, 0xE0 };                          // pop rax; add rax,0; jmp rax
{ 0x58, 0x48, 0x83, 0xE8, 0x00, 0xFF, 0xE0 };                          // pop rax; sub rax,0; jmp rax
{ 0x58, 0x48, 0x83, 0xC8, 0x00, 0xFF, 0xE0 };                          // pop rax; or rax,0; jmp rax
{ 0x58, 0x48, 0x83, 0xE0, 0xFF, 0xFF, 0xE0 };                          // pop rax; and rax,-1; jmp rax
{ 0x58, 0x48, 0x83, 0xF0, 0x00, 0xFF, 0xE0 };                          // pop rax; xor rax,0; jmp rax
{ 0x58, 0x48, 0x69, 0xC0, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xE0 };        // pop rax; imul rax,rax,1; jmp rax
```

---

## Increment/Decrement Cancel

```c
{ 0x58, 0x48, 0xFF, 0xC0, 0x48, 0xFF, 0xC8, 0xFF, 0xE0 };              // pop rax; inc rax; dec rax; jmp rax
{ 0x58, 0x48, 0xFF, 0xC8, 0x48, 0xFF, 0xC0, 0xFF, 0xE0 };              // pop rax; dec rax; inc rax; jmp rax
{ 0x58, 0x48, 0xFF, 0xC0, 0x48, 0xFF, 0xC0, 0x48, 0xFF, 0xC8, 0x48, 0xFF, 0xC8, 0xFF, 0xE0 };  // pop rax; inc; inc; dec; dec; jmp rax
```

---

## NOT NOT (Double Negation)

```c
{ 0x58, 0x48, 0xF7, 0xD0, 0x48, 0xF7, 0xD0, 0xFF, 0xE0 };              // pop rax; not rax; not rax; jmp rax
{ 0x58, 0x48, 0xF7, 0xD8, 0x48, 0xF7, 0xD8, 0xFF, 0xE0 };              // pop rax; neg rax; neg rax; jmp rax
```

---

## Rotate Cancel

```c
{ 0x58, 0x48, 0xD1, 0xC0, 0x48, 0xD1, 0xC8, 0xFF, 0xE0 };              // pop rax; rol rax,1; ror rax,1; jmp rax
{ 0x58, 0x48, 0xD1, 0xC8, 0x48, 0xD1, 0xC0, 0xFF, 0xE0 };              // pop rax; ror rax,1; rol rax,1; jmp rax
{ 0x58, 0x48, 0xC1, 0xC0, 0x08, 0x48, 0xC1, 0xC8, 0x08, 0xFF, 0xE0 };  // pop rax; rol rax,8; ror rax,8; jmp rax
{ 0x58, 0x48, 0xC1, 0xC0, 0x10, 0x48, 0xC1, 0xC8, 0x10, 0xFF, 0xE0 };  // pop rax; rol rax,16; ror rax,16; jmp rax
{ 0x58, 0x48, 0xC1, 0xC0, 0x20, 0x48, 0xC1, 0xC8, 0x20, 0xFF, 0xE0 };  // pop rax; rol rax,32; ror rax,32; jmp rax
```

---

## Shift Cancel

```c
{ 0x58, 0x48, 0xD1, 0xE0, 0x48, 0xD1, 0xE8, 0xFF, 0xE0 };              // pop rax; shl rax,1; shr rax,1; jmp rax (DESTROYS top bit - use with caution)
```

---

## BSWAP BSWAP

```c
{ 0x58, 0x48, 0x0F, 0xC8, 0x48, 0x0F, 0xC8, 0xFF, 0xE0 };              // pop rax; bswap rax; bswap rax; jmp rax
{ 0x59, 0x48, 0x0F, 0xC9, 0x48, 0x0F, 0xC9, 0xFF, 0xE1 };              // pop rcx; bswap rcx; bswap rcx; jmp rcx
```

---

## XOR Patterns

```c
{ 0x58, 0x50, 0x48, 0x31, 0xC0, 0x58, 0xFF, 0xE0 };                    // pop rax; push rax; xor rax,rax; pop rax; jmp rax
{ 0x58, 0x48, 0x89, 0xC1, 0x48, 0x31, 0xC0, 0x48, 0x89, 0xC8, 0xFF, 0xE0 };  // pop rax; mov rcx,rax; xor rax,rax; mov rax,rcx; jmp rax
{ 0x58, 0x59, 0x48, 0x31, 0xC1, 0x48, 0x31, 0xC8, 0x48, 0x31, 0xC1, 0xFF, 0xE0 };  // pop rax; pop rcx; xor rcx,rax; xor rax,rcx; xor rcx,rax; jmp rax
```

---

## CMOVcc Conditional Move

```c
{ 0x58, 0x48, 0x31, 0xC9, 0x48, 0x0F, 0x44, 0xC8, 0xFF, 0xE1 };        // pop rax; xor rcx,rcx; cmovz rcx,rax; jmp rcx (ZF=1 after xor)
{ 0x58, 0x48, 0x31, 0xC9, 0x48, 0x0F, 0x45, 0xC8, 0x48, 0x39, 0xC0, 0x48, 0x0F, 0x44, 0xC8, 0xFF, 0xE1 };  // more convoluted cmov
```

---

## SETcc Tricks

```c
{ 0x58, 0x48, 0x85, 0xC0, 0x0F, 0x95, 0xC1, 0xFF, 0xE0 };              // pop rax; test rax,rax; setnz cl; jmp rax (cl gets clobbered, but rax intact)
```

---

## LODSQ Variants

```c
{ 0x48, 0x8B, 0xF4, 0x48, 0xAD, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // mov rsi,rsp; lodsq; add rsp,8; jmp rax
{ 0x48, 0x8B, 0xF4, 0x48, 0xAD, 0x48, 0x8D, 0x64, 0x24, 0x08, 0xFF, 0xE0 };  // mov rsi,rsp; lodsq; lea rsp,[rsp+8]; jmp rax
{ 0x54, 0x5E, 0x48, 0xAD, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };        // push rsp; pop rsi; lodsq; add rsp,8; jmp rax
```

---

## LODSD 32-bit

```c
{ 0x48, 0x8B, 0xF4, 0xAD, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };        // mov rsi,rsp; lodsd; add rsp,8; jmp rax (only works if addr fits 32 bits)
```

---

## MOVSQ Abuse

```c
{ 0x48, 0x8B, 0xF4, 0x48, 0x83, 0xEC, 0x08, 0x48, 0x8B, 0xFC, 0x48, 0xA5, 0x58, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // mov rsi,rsp; sub rsp,8; mov rdi,rsp; movsq; pop rax; add rsp,8; jmp rax
```

---

## STOSQ Then Load Back

```c
{ 0x58, 0x48, 0x83, 0xEC, 0x08, 0x48, 0x8B, 0xFC, 0x48, 0xAB, 0x48, 0x8B, 0x44, 0x24, 0xF8, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // pop rax; sub rsp,8; mov rdi,rsp; stosq; mov rax,[rsp-8]; add rsp,8; jmp rax
```

---

## Stack Pointer Games

```c
{ 0x48, 0x8B, 0x04, 0x24, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };        // mov rax,[rsp]; add rsp,8; jmp rax
{ 0x48, 0x8B, 0x0C, 0x24, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE1 };        // mov rcx,[rsp]; add rsp,8; jmp rcx
{ 0x48, 0x8B, 0x14, 0x24, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE2 };        // mov rdx,[rsp]; add rsp,8; jmp rdx
{ 0x48, 0x8B, 0x04, 0x24, 0x48, 0x8D, 0x64, 0x24, 0x08, 0xFF, 0xE0 };  // mov rax,[rsp]; lea rsp,[rsp+8]; jmp rax
```

---

## RSP with SIB Byte

```c
{ 0x48, 0x8B, 0x44, 0x24, 0x00, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // mov rax,[rsp+0]; add rsp,8; jmp rax
{ 0x48, 0x8B, 0x84, 0x24, 0x00, 0x00, 0x00, 0x00, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // mov rax,[rsp+0x00000000]; add rsp,8; jmp rax
```

---

## Indirect Jmp [rsp]

```c
{ 0xFF, 0x24, 0x24 };                                                  // jmp [rsp] - doesn't pop, will crash on next ret
{ 0xFF, 0x64, 0x24, 0x00 };                                            // jmp [rsp+0]
```

---

## NOP Sleds

```c
{ 0x90, 0xC3 };                                                        // nop; ret
{ 0x90, 0x90, 0xC3 };                                                  // nop; nop; ret
{ 0x90, 0x90, 0x90, 0xC3 };                                            // nop; nop; nop; ret
{ 0x90, 0x90, 0x90, 0x90, 0xC3 };                                      // nop; nop; nop; nop; ret
{ 0x66, 0x90, 0xC3 };                                                  // xchg ax,ax (2-byte nop); ret
{ 0x0F, 0x1F, 0x00, 0xC3 };                                            // nop dword [rax] (3-byte); ret
{ 0x0F, 0x1F, 0x40, 0x00, 0xC3 };                                      // nop dword [rax+0] (4-byte); ret
{ 0x0F, 0x1F, 0x44, 0x00, 0x00, 0xC3 };                                // 5-byte nop; ret
{ 0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00, 0xC3 };                          // 6-byte nop; ret
{ 0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00, 0xC3 };                    // 7-byte nop; ret
{ 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC3 };              // 8-byte nop; ret
{ 0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC3 };        // 9-byte nop; ret
```

---

## LEAVE Variants

```c
{ 0xC9, 0xC3 };                                                        // leave; ret
{ 0x48, 0x89, 0xEC, 0x5D, 0xC3 };                                      // mov rsp,rbp; pop rbp; ret
{ 0x48, 0x8B, 0xE5, 0x5D, 0xC3 };                                      // mov rsp,rbp; pop rbp; ret (alternate encoding)
```

---

## ENTER Then LEAVE

```c
{ 0xC8, 0x00, 0x00, 0x00, 0xC9, 0xC3 };                                // enter 0,0; leave; ret
```

---

## Push Immediate Then Add RSP

```c
{ 0x6A, 0x00, 0x48, 0x83, 0xC4, 0x08, 0xC3 };                          // push 0; add rsp,8; ret
{ 0x68, 0x00, 0x00, 0x00, 0x00, 0x48, 0x83, 0xC4, 0x08, 0xC3 };        // push 0x00000000; add rsp,8; ret
```

---

## PUSHFQ/POPFQ Flags Dance

```c
{ 0x9C, 0x9D, 0xC3 };                                                  // pushfq; popfq; ret
{ 0x9C, 0x58, 0x50, 0x9D, 0xC3 };                                      // pushfq; pop rax; push rax; popfq; ret
```

---

## SAHF/LAHF

```c
{ 0x58, 0x9F, 0x9E, 0xFF, 0xE0 };                                      // pop rax; lahf; sahf; jmp rax
```

---

## CPUID Clobber

```c
{ 0x58, 0x50, 0x53, 0x51, 0x52, 0x0F, 0xA2, 0x5A, 0x59, 0x5B, 0x58, 0xFF, 0xE0 };  // pop rax; push rax,rbx,rcx,rdx; cpuid; pop rdx,rcx,rbx,rax; jmp rax
```

---

## RDTSC Clobber

```c
{ 0x59, 0x0F, 0x31, 0xFF, 0xE1 };                                      // pop rcx; rdtsc; jmp rcx (rax,rdx clobbered)
```

---

## XGETBV Clobber

```c
{ 0x59, 0x48, 0x31, 0xC0, 0x0F, 0x01, 0xD0, 0xFF, 0xE1 };              // pop rcx; xor rax,rax; xgetbv; jmp rcx (needs ecx=0)
```

---

## Segment Register Abuse

```c
{ 0x1E, 0x1F, 0xC3 };                                                  // push ds; pop ds; ret (if valid in your mode)
{ 0x06, 0x07, 0xC3 };                                                  // push es; pop es; ret (if valid in your mode)
```

---

## String Prefix

```c
{ 0xF3, 0xC3 };                                                        // rep ret (AMD branch predictor hint)
{ 0xF3, 0x90, 0xC3 };                                                  // pause; ret
```

---

## Redundant REX Prefixes

```c
{ 0x48, 0xC3 };                                                        // REX.W ret (does nothing but valid)
{ 0x40, 0xC3 };                                                        // REX ret
{ 0x41, 0xC3 };                                                        // REX.B ret
{ 0x42, 0xC3 };                                                        // REX.X ret
{ 0x44, 0xC3 };                                                        // REX.R ret
{ 0x48, 0x48, 0xC3 };                                                  // REX.W REX.W ret (multiple REX, last wins)
{ 0x40, 0x48, 0xC3 };                                                  // REX REX.W ret
```

---

## Segment Override Prefixes

```c
{ 0x26, 0xC3 };                                                        // ES: ret
{ 0x2E, 0xC3 };                                                        // CS: ret
{ 0x36, 0xC3 };                                                        // SS: ret
{ 0x3E, 0xC3 };                                                        // DS: ret
{ 0x64, 0xC3 };                                                        // FS: ret
{ 0x65, 0xC3 };                                                        // GS: ret
```

---

## Operand Size Prefix

```c
{ 0x66, 0xC3 };                                                        // 16-bit ret (pops 16 bits - DANGEROUS, will likely crash)
```

---

## Address Size Prefix

```c
{ 0x67, 0xC3 };                                                        // addr32 ret (no real effect on ret)
```

---

## Multiple Useless Prefixes

```c
{ 0x26, 0x2E, 0x36, 0x3E, 0xC3 };                                      // ES: CS: SS: DS: ret
{ 0x64, 0x65, 0x26, 0xC3 };                                            // FS: GS: ES: ret
{ 0x66, 0x67, 0x48, 0xC3 };                                            // mixed prefixes ret
```

---

## PUSH/POP RSP Weirdness

```c
{ 0x54, 0x5C, 0xC3 };                                                  // push rsp; pop rsp; ret
{ 0x54, 0x58, 0x48, 0x83, 0xC0, 0x08, 0x48, 0x8B, 0x00, 0xFF, 0xE0 };  // push rsp; pop rax; add rax,8; mov rax,[rax]; jmp rax
```

---

## Self-XOR Patterns

```c
{ 0x58, 0x48, 0x31, 0xC1, 0x48, 0x31, 0xC1, 0xFF, 0xE1 };              // pop rax; xor rcx,rax; xor rcx,rax; jmp rcx
{ 0x58, 0x48, 0x89, 0xC1, 0x48, 0x31, 0xC8, 0x48, 0x31, 0xC8, 0xFF, 0xE0 };  // pop rax; mov rcx,rax; xor rax,rcx; xor rax,rcx; jmp rax
```

---

## POPCNT Abuse

```c
{ 0x59, 0xF3, 0x48, 0x0F, 0xB8, 0xC1, 0xFF, 0xE1 };                    // pop rcx; popcnt rax,rcx; jmp rcx (rax gets bit count, but rcx intact)
```

---

## LZCNT Abuse

```c
{ 0x59, 0xF3, 0x48, 0x0F, 0xBD, 0xC1, 0xFF, 0xE1 };                    // pop rcx; lzcnt rax,rcx; jmp rcx
```

---

## TZCNT Abuse

```c
{ 0x59, 0xF3, 0x48, 0x0F, 0xBC, 0xC1, 0xFF, 0xE1 };                    // pop rcx; tzcnt rax,rcx; jmp rcx
```

---

## BSF/BSR

```c
{ 0x59, 0x48, 0x0F, 0xBC, 0xC1, 0xFF, 0xE1 };                          // pop rcx; bsf rax,rcx; jmp rcx
{ 0x59, 0x48, 0x0F, 0xBD, 0xC1, 0xFF, 0xE1 };                          // pop rcx; bsr rax,rcx; jmp rcx
```

---

## BT/BTS/BTR/BTC Bit Test

```c
{ 0x58, 0x48, 0x0F, 0xA3, 0xC1, 0xFF, 0xE0 };                          // pop rax; bt rcx,rax; jmp rax (tests bit, doesn't change rax)
```

---

## ANDN (BMI1)

```c
{ 0x59, 0xC4, 0xE2, 0xF0, 0xF2, 0xC1, 0xFF, 0xE1 };                    // pop rcx; andn rax,rcx,rcx; jmp rcx (rax = ~rcx & rcx = 0)
```

---

## BLSI/BLSR/BLSMSK (BMI1)

```c
{ 0x59, 0xC4, 0xE2, 0xF8, 0xF3, 0xD9, 0xFF, 0xE1 };                    // pop rcx; blsi rax,rcx; jmp rcx (rax = lowest set bit)
```

---

## PDEP/PEXT (BMI2)

```c
{ 0x5A, 0x59, 0xC4, 0xE2, 0xEB, 0xF5, 0xC1, 0xFF, 0xE1 };              // pop rdx; pop rcx; pext rax,rdx,rcx; jmp rcx (extremely cursed)
```

---

## ADC/SBB with Carry

```c
{ 0x58, 0xF8, 0x48, 0x83, 0xD0, 0x00, 0xFF, 0xE0 };                    // pop rax; clc; adc rax,0; jmp rax
{ 0x58, 0xF8, 0x48, 0x83, 0xD8, 0x00, 0xFF, 0xE0 };                    // pop rax; clc; sbb rax,0; jmp rax
```

---

## CLC/STC/CMC Dance

```c
{ 0x58, 0xF8, 0xF9, 0xF5, 0xF5, 0xFF, 0xE0 };                          // pop rax; clc; stc; cmc; cmc; jmp rax
```

---

## CLD/STD Direction Flag

```c
{ 0x48, 0x8B, 0xF4, 0xFC, 0x48, 0xAD, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // mov rsi,rsp; cld; lodsq; add rsp,8; jmp rax
```

---

## Store to Stack Load Back

```c
{ 0x58, 0x48, 0x83, 0xEC, 0x08, 0x48, 0x89, 0x04, 0x24, 0x48, 0x8B, 0x04, 0x24, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // pop rax; sub rsp,8; mov [rsp],rax; mov rax,[rsp]; add rsp,8; jmp rax
```

---

## Triple Indirect

```c
{ 0x58, 0x50, 0x48, 0x8B, 0x04, 0x24, 0x48, 0x83, 0xC4, 0x08, 0xFF, 0xE0 };  // pop rax; push rax; mov rax,[rsp]; add rsp,8; jmp rax
```

---

## Conditional Jump Over Ret

```c
{ 0xEB, 0x00, 0xC3 };                                                  // jmp $+2; ret (jumps to ret)
{ 0x74, 0x00, 0xC3 };                                                  // jz $+2; ret (falls through or jumps to same place)
{ 0x75, 0x00, 0xC3 };                                                  // jnz $+2; ret
{ 0xEB, 0x01, 0x90, 0xC3 };                                            // jmp $+3; nop; ret (skips nop, hits ret)
{ 0xE9, 0x00, 0x00, 0x00, 0x00, 0xC3 };                                // jmp $+5; ret (near jump to next instruction)
```

---

## CALL Next Instruction

```c
{ 0xE8, 0x00, 0x00, 0x00, 0x00, 0x48, 0x83, 0xC4, 0x08, 0xC3 };        // call $+5; add rsp,8; ret (pushes return addr, pops it, returns)
```

---

## LOOP That Doesn't Loop

```c
{ 0x48, 0x31, 0xC9, 0xE2, 0xFE, 0xC3 };                                // xor rcx,rcx; loop $-2; ret (rcx=0, doesn't loop)
{ 0xB9, 0x01, 0x00, 0x00, 0x00, 0xE2, 0x00, 0xC3 };                    // mov ecx,1; loop $+2; ret (loops once to ret)
```

---

## REP Prefix on Non-String

```c
{ 0xF3, 0x58, 0xF3, 0xFF, 0xE0 };                                      // rep pop rax; rep jmp rax (rep ignored)
```

---

## Notes

- Many of these are intentionally obfuscated and inefficient
- Some may crash depending on register/stack state (marked as "cursed" or "dangerous")
- The `{ 0x66, 0xC3 }` (16-bit ret) is particularly dangerous as it only pops 16 bits
- BMI1/BMI2 instructions require CPU support
- Segment register operations may be invalid in x64 long mode
- The `rep ret` sequence (`0xF3, 0xC3`) was historically used as an AMD branch predictor optimization

---

## License

Public domain. Use at your own risk.
