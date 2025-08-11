// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// pre_ascon.sv
//
// Simple OBI slave that stores a 32-bit register at offset 0x00 and
// returns it on reads. Writes complete immediately (slave replies),
// so masters won't hang waiting for a response. Useful for checking
// that write data traversed the OBI bus correctly.
//
// Style notes:
//  - Uses obi_pkg::obi_cfg_t, typical obi_req_t / obi_rsp_t types.
//  - All state is registered with always_ff.
//  - Handshake: req -> gnt, rvalid asserted when response ready
//  - r.rdata returns reg0 on reads; writes produce rvalid with rdata = 0.

module pre_ascon #(
  /// OBI configuration
  parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
  /// OBI request struct type
  parameter type obi_req_t = logic,
  /// OBI response struct type
  parameter type obi_rsp_t = logic
) (
  input  logic     clk_i,
  input  logic     rst_ni,

  // OBI slave interface (sbr)
  input  obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o
);

  // -----------------------
  // Local registers / state
  // -----------------------
  // Registered version of incoming request handshake fields
  logic req_q;
  logic we_q;
  logic [ObiCfg.DataWidth-1:0] wdata_q;
  logic [ObiCfg.AddrWidth-1:0] addr_q;
  logic [ObiCfg.IdWidth-1:0] id_q;

  // Persistent register to store writes to offset 0x00
  logic [ObiCfg.DataWidth-1:0] reg0_q;

  // Response combinational
  logic [ObiCfg.DataWidth-1:0] rsp_rdata;
  logic rsp_err;

  // -----------------------
  // Register incoming request (pipeline stage)
  // -----------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_q   <= 1'b0;
      we_q    <= 1'b0;
      wdata_q <= '0;
      addr_q  <= '0;
      id_q    <= '0;
      reg0_q  <= '0;
    end else begin
      req_q   <= obi_req_i.req;
      we_q    <= obi_req_i.a.we;
      wdata_q <= obi_req_i.a.wdata;
      addr_q  <= obi_req_i.a.addr;
      id_q    <= obi_req_i.a.aid;

      // Latch write into reg0 when there is a valid write request to offset 0x00
      // Use address word-select addr_q[3:2] consistent with other modules (word aligned)
      if (obi_req_i.req && obi_req_i.a.we && (obi_req_i.a.addr[3:2] == 2'b00)) begin
        reg0_q <= obi_req_i.a.wdata;
      end
    end
  end

  // -----------------------
  // Response data generation (combinational)
  // -----------------------
  always_comb begin
    // default
    rsp_rdata = '0;
    rsp_err   = 1'b0;

    // If the registered request was a read (we_q == 0), return the stored reg0_q
    if (!we_q && req_q) begin
      case (addr_q[3:2])
        2'b00: rsp_rdata = reg0_q;        // read reg0
        default: rsp_rdata = 32'hDEADBEEF; // unmapped addresses -> sentinel
      endcase
    end else begin
      // For writes, we still produce a valid response (ack) but no meaningful rdata
      // Keep rsp_rdata = 0 for write responses (or could echo back if desired)
      rsp_rdata = '0;
    end
  end

  // -----------------------
  // OBI handshake wiring
  // -----------------------
  // Grant: immediately reflect request (no arbitration here)
  assign obi_rsp_o.gnt = obi_req_i.req;

  // Response valid:
  // - we assert rvalid when we have latched a request (req_q)
  // - this makes both reads and writes complete (avoids master hang on store)
  assign obi_rsp_o.rvalid = req_q;

  // Response payload
  assign obi_rsp_o.r.rdata       = rsp_rdata;
  assign obi_rsp_o.r.rid         = id_q;
  assign obi_rsp_o.r.err         = rsp_err;
  assign obi_rsp_o.r.r_optional  = '0;

endmodule
