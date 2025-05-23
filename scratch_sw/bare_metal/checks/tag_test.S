// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Overview of the sections in this test:
// - start: read root capabilities
// - captags: check that capability tags are stored correctly and are invalidated by non-CSC writes.
// - revtags: check the load-barrier on CLC, when the revocation bits are set CLC should invalidate the tags.
// - hw_rev: test that the hardware revoker can sweep memory and invalidate capabilities that are marked for revocation.

.include "assembly-helpers.s"

.section .text.start, "ax", @progbits
  .zero 0x80
  .globl start
  .p2align 2
  .type start,@function
start:
  // The memory root for storing and loading.
  cspecialr ca0, mtdc
  // The execution root.
  auipcc ca1, 0
  // The sealing root.
  cspecialr ca2, mscratchc

.section .text

// Test for capability tags
captags:
  // Get capability to storage in ct0
  la_abs t0, storage
  srli t0, t0, 3 // Make sure it is 64-bit aligned
  slli t0, t0, 3
  csetaddr ct0, ca0, t0
  // Check that tags start out as 0
  clc ct1,  0(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  bnez t2, fail
  // Store valid capabilities
  csc ct0,  0(ct0)
  csc ct0,  8(ct0)
  csc ct0, 16(ct0)
  // Check that tags are all valid
  clc ct1,  0(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  beqz t2, fail
  // Invalidate second capability with write to top word
  csw zero, 8(ct0)
  // Check tags are 1,0,1
  clc ct1,  0(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  beqz t2, fail
  // Write back valid capability
  csc ct0,  8(ct0)
  // Invalidate second capability with write to middle byte
  csb zero,13(ct0)
  // Check that tags are 1,0,1
  clc ct1,  0(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  beqz t2, fail
  // Invalidate other two capabilities
  csh zero, 4(ct0)
  csw zero,20(ct0)
  // Check that tags are all invalid
  clc ct1,  0(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  bnez t2, fail
  // Store valid capabilities
  csc ct0,  0(ct0)
  csc ct0,  8(ct0)
  csc ct0, 16(ct0)
  // Check that tags are all valid
  clc ct1,  0(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  beqz t2, fail
  // Store null cap to second capability
  csc cnull,  8(ct0)
  // Check that tags are 1,0,1
  clc ct1,  0(ct0)
  cgettag t2, ct1
  beqz t2, fail
  clc ct1,  8(ct0)
  cgettag t2, ct1
  bnez t2, fail
  clc ct1, 16(ct0)
  cgettag t2, ct1
  beqz t2, fail

// Test for revocation tags
revtags:
  // Capability to revocation tags
  li t0, 0x00300000
  csetaddr ct0, ca0, t0
  // Get capability to storage
  la_abs t1, storage
  srli t1, t1, 3 // Make sure it is 64-bit aligned
  slli t1, t1, 3
  csetaddr ct2, ca0, t1
  csetboundsimm ct2, ct2, 24 // Make base and address be within revocation region
  // Calculate the address of the memory-mapped revocation bits for the memory labeled as "storage" in this elf.
  li t0, 0x00300000
  li a3, 0x00200000 // SRAM base
  sub t1, t1, a3
  srli t1, t1, 8 // 1 tag per 8 Bytes (shift 3) and load 32 tags at a time (shift 5)
  slli t1, t1, 2 // Always load 32-bit aligned values
  add t0, t0, t1
  csetaddr ct0, ca0, t0
  // Zero revocation tags
  csw zero, 0(ct0)
  // Store and load capability and check tag stays valid
  csc ct2, 8(ct2)
  clc ct1, 8(ct2)
  cgettag a3, ct1
  beqz a3, fail
  // Mark storage for revocation
  li a3, 0xFFFFFFFF
  csw a3, 0(ct0)
  // Store and load capability and check it is revoked
  csc ct2, 8(ct2)
  clc ct1, 8(ct2)
  cgettag a3, ct1
  bnez a3, fail
  // Store and load capability with base outside of SRAM and check tag stays valid
  csc ca0, 8(ct2)
  clc ct1, 8(ct2)
  cgettag a3, ct1
  beqz a3, fail

// Test of hardware revoker
hw_rev:
  // Capability to end of revocation tags
  li t0, 0x00302000
  addi t0, t0, -4
  csetaddr ct0, ca0, t0
  // Zero revocation tags
  csw zero, 0(ct0)
  // Capability to hardware revoker control
  li t1, 0x00340000
  csetaddr ct1, ca0, t1
  li t2, 0x00280000 // End of SRAM
  addi t2, t2, -8 // Point to last capability aligned region in SRAM
  csetaddr ct2, ca0, t2
  csc ct0, 0(ct2) // Write capability with base 0, which should not be cleared.
  csw t2, 4(ct1) // Set end of memory to sweep
  addi t2, t2, -8 // Second to last capability in SRAM.
  csetaddr ca3, ca0, t2
  csetboundsimm ca3, ca3, 1
  csetaddr ct2, ca0, t2
  csc ca3, 0(ct2) // Write capability with base 0x11FFE0, which should be cleared
  // Revoke end of SRAM
  li a3, 0xFFFFFFFF
  csw a3, 0(ct0)
  csw t2, 0(ct1) // Set start of memory to sweep
  clw t2, 12(ct1) // Read current epoch
  andi t2, t2, 1 // Get running bit, which should be 0
  bnez t2, fail
  li t2, 1
  csw t2, 8(ct1) // Start sweep
  nop // Wait a few cycles to allow run to be set to 1
  nop
  nop
  clw t2, 12(ct1) // Read current epoch
  andi t2, t2, 1 // Get running bit, which should be 1
  beqz t2, fail
  // Wait for some cycles while the sweep happens.
  li t2, 10
wait_loop:
  addi t2, t2, -1
  bnez t2, wait_loop
  // Check that interrupt status is high after sweep.
  clw t2, 16(ct1)
  beqz t2, fail
  csw zero, 16(ct1) // Clear interrupt status
  // Unrevoke end of SRAM to disable load capability barrier.
  csw zero, 0(ct0)
  li t2, 0x00280000 // End of SRAM
  addi t2, t2, -8 // Point to last capability aligned region in SRAM
  csetaddr ct2, ca0, t2
  clc ca3, 0(ct2) // Read capability for which tag should stay 1.
  cgettag a3, ca3
  beqz a3, fail
  addi t2, t2, -8 // Second to last capability in SRAM.
  csetaddr ct2, ca0, t2
  clc ca3, 0(ct2) // Read capability for which tag should be 0.
  cgettag a3, ca3
  bnez a3, fail

hw_rev_intr:
  li t2, 1
  csw t2, 20(ct1) // Enable interrupts
  csw t2, 8(ct1) // Start sweep
  // This last interrupt is currently not checked.
  // There will first need a trap handler installed.
  // Then we need to enable the revocation interrupt in the PLIC.
  // For now you can check that this is functioning properly by checking the rev_ctl_irq_o in the waveform.

success:
  j success

  nop // In case of misalignment
  nop
  nop
storage:
  // First capability
  nop
  nop
  nop
  nop
  // Second capability
  nop
  nop
  nop
  nop
  // Third capability
  nop
  nop
  nop
  nop

// If we get here we know something went wrong.
fail:
  j fail
