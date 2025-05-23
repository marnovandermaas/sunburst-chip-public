// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// tl_main package generated by `tlgen.py` tool

package tl_main_pkg;

  localparam logic [31:0] ADDR_SPACE_ROM            = 32'h 00100000;
  localparam logic [31:0] ADDR_SPACE_SRAM           = 32'h 00200000;
  localparam logic [31:0] ADDR_SPACE_REVOCATION_RAM = 32'h 00300000;
  localparam logic [31:0] ADDR_SPACE_REV_CTL        = 32'h 00340000;
  localparam logic [31:0] ADDR_SPACE_CORE_IBEX__CFG = 32'h 811f0000;
  localparam logic [31:0] ADDR_SPACE_DBG_MEM        = 32'h b0000000;
  localparam logic [31:0] ADDR_SPACE_RV_PLIC        = 32'h 88000000;
  localparam logic [31:0] ADDR_SPACE_PERI           = 32'h 40000000;

  localparam logic [31:0] ADDR_MASK_ROM            = 32'h 00000fff;
  localparam logic [31:0] ADDR_MASK_SRAM           = 32'h 0007ffff;
  localparam logic [31:0] ADDR_MASK_REVOCATION_RAM = 32'h 00001fff;
  localparam logic [31:0] ADDR_MASK_REV_CTL        = 32'h 00000fff;
  localparam logic [31:0] ADDR_MASK_CORE_IBEX__CFG = 32'h 00000fff;
  localparam logic [31:0] ADDR_MASK_DBG_MEM        = 32'h 00000fff;
  localparam logic [31:0] ADDR_MASK_RV_PLIC        = 32'h 03ffffff;
  localparam logic [31:0] ADDR_MASK_PERI           = 32'h 3fffffff;

  localparam int N_HOST   = 3;
  localparam int N_DEVICE = 8;

  typedef enum int {
    TlRom = 0,
    TlSram = 1,
    TlRevocationRam = 2,
    TlRevCtl = 3,
    TlCoreIbexCfg = 4,
    TlDbgMem = 5,
    TlRvPlic = 6,
    TlPeri = 7
  } tl_device_e;

  typedef enum int {
    TlCoreIbexCorei = 0,
    TlCoreIbexCored = 1,
    TlDbg = 2
  } tl_host_e;

endpackage
