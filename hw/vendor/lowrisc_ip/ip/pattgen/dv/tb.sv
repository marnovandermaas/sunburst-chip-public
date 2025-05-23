// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
module tb;
  // dep packages
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  import pattgen_env_pkg::*;
  import pattgen_test_pkg::*;
  import pattgen_agent_pkg::*;

  // macro includes
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  wire clk, rst_n;

  wire [NUM_PATTGEN_CHANNELS-1:0] pda_tx_o;
  wire [NUM_PATTGEN_CHANNELS-1:0] pcl_tx_o;
  wire intr_done_ch0;
  wire intr_done_ch1;
  wire [NUM_MAX_INTERRUPTS-1:0] interrupts;

  logic cio_pda0_tx_en, cio_pcl0_tx_en, cio_pda1_tx_en, cio_pcl1_tx_en;

  // interfaces
  clk_rst_if clk_rst_if(.clk(clk), .rst_n(rst_n));
  pins_if #(NUM_MAX_INTERRUPTS) intr_if(interrupts);
  pattgen_if #(NUM_PATTGEN_CHANNELS) pattgen_if();
  tl_if tl_if(.clk(clk), .rst_n(rst_n));

  // dut
  pattgen dut (
    .clk_i                (clk           ),
    .rst_ni               (rst_n         ),

    .tl_i                 (tl_if.h2d     ),
    .tl_o                 (tl_if.d2h     ),

    .cio_pda0_tx_o        (pda_tx_o[0]   ),
    .cio_pcl0_tx_o        (pcl_tx_o[0]   ),
    .cio_pda1_tx_o        (pda_tx_o[1]   ),
    .cio_pcl1_tx_o        (pcl_tx_o[1]   ),

    .cio_pda0_tx_en_o     (cio_pda0_tx_en),
    .cio_pcl0_tx_en_o     (cio_pcl0_tx_en),
    .cio_pda1_tx_en_o     (cio_pda1_tx_en),
    .cio_pcl1_tx_en_o     (cio_pcl1_tx_en),

    .intr_done_ch0_o      (intr_done_ch0 ),
    .intr_done_ch1_o      (intr_done_ch1 )
  );

  assign pattgen_if.rst_ni   = rst_n;
  assign pattgen_if.clk_i    = clk;
  assign pattgen_if.pda_tx   = pda_tx_o;
  assign pattgen_if.pcl_tx   = pcl_tx_o;

  assign interrupts[DoneCh0] = intr_done_ch0;
  assign interrupts[DoneCh1] = intr_done_ch1;

  // Pattgen has four "enable" ports that are just wired to 1'b1. Rather than doing any functional
  // verification about these signals, it's easiest to assert that they are '1.
  `ASSERT(TxEnHigh_A, &{cio_pda0_tx_en, cio_pcl0_tx_en, cio_pda1_tx_en, cio_pcl1_tx_en},
          clk_rst_if.clk, !clk_rst_if.rst_n)

  initial begin
    // drive clk and rst_n from clk_if
    clk_rst_if.set_active();
    uvm_config_db#(virtual clk_rst_if)::set(null, "*.env", "clk_rst_vif", clk_rst_if);
    uvm_config_db#(intr_vif)::set(null, "*.env", "intr_vif", intr_if);
    uvm_config_db#(virtual tl_if)::set(null, "*.env.m_tl_agent*", "vif", tl_if);
    uvm_config_db#(virtual pattgen_if)::set(null, "*.env.m_pattgen_agent*", "vif", pattgen_if);
    $timeformat(-12, 0, " ps", 12);
    run_test();
  end

endmodule
