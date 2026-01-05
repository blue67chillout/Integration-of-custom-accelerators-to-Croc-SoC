module mac_accelerator
  import croc_pkg::*;
(
  input  logic        clk_i,
  input  logic        rst_ni,

  // OBI subordinate interface (from demux / xbar)
  input  sbr_obi_req_t obi_req_i,
  output sbr_obi_rsp_t obi_rsp_o
);

  // --------------------------------------------------
  // Registers
  // --------------------------------------------------
  logic [31:0] operand_a;
  logic [31:0] operand_b;
  logic [31:0] operand_c;
  logic [31:0] result;

  logic        mac_done;
  logic        mac_busy;

  // --------------------------------------------------
  // Internal transaction tracking
  // --------------------------------------------------
  logic        req_accepted;
  logic        rsp_pending;

  logic        rsp_is_read;
  logic [31:0] rsp_rdata;
  logic [SbrObiCfg.IdWidth-1:0] rsp_rid;

  // --------------------------------------------------
  // MAC computation (single-cycle combinational)
  // --------------------------------------------------
  logic signed [63:0] mac_full;
  assign mac_full = $signed(operand_a)
                  * $signed(operand_b)
                  + $signed(operand_c);

  // --------------------------------------------------
  // Accept request
  // --------------------------------------------------
  assign req_accepted = obi_req_i.req && obi_rsp_o.gnt;

  // --------------------------------------------------
  // OBI response defaults
  // --------------------------------------------------
  always_comb begin
    obi_rsp_o         = '0;
    obi_rsp_o.gnt     = !rsp_pending;  // backpressure if response not sent yet
    obi_rsp_o.rvalid  = rsp_pending;
    obi_rsp_o.r.rdata = rsp_rdata;
    obi_rsp_o.r.rid   = rsp_rid;
    obi_rsp_o.r.err   = 1'b0;
  end

  // --------------------------------------------------
  // Sequential logic
  // --------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      operand_a  <= 32'b0;
      operand_b  <= 32'b0;
      operand_c  <= 32'b0;
      result     <= 32'b0;

      mac_done   <= 1'b1;
      mac_busy   <= 1'b0;

      rsp_pending <= 1'b0;
      rsp_rdata   <= 32'b0;
      rsp_rid     <= '0;
      rsp_is_read <= 1'b0;

    end else begin
      // --------------------------------------------------
      // Clear response after one cycle
      // --------------------------------------------------
      if (rsp_pending) begin
        rsp_pending <= 1'b0;
      end

      // --------------------------------------------------
      // Handle accepted request
      // --------------------------------------------------
      if (req_accepted) begin
        rsp_pending <= 1'b1;
        rsp_rid     <= obi_req_i.a.aid;
        rsp_is_read <= !obi_req_i.a.we;

        unique case (obi_req_i.a.addr[6:2]) // word aligned
          // ---------------- WRITE REGISTERS ----------------
          5'h00: if (obi_req_i.a.we) operand_a <= obi_req_i.a.wdata;
          5'h01: if (obi_req_i.a.we) operand_b <= obi_req_i.a.wdata;
          5'h02: if (obi_req_i.a.we) operand_c <= obi_req_i.a.wdata;

          // ---------------- CONTROL ----------------
          5'h05: if (obi_req_i.a.we && obi_req_i.a.wdata[0]) begin
            mac_busy <= 1'b1;
            mac_done <= 1'b0;
          end

          default: ;
        endcase

        // ---------------- READ DATA ----------------
        unique case (obi_req_i.a.addr[6:2])
          5'h00: rsp_rdata <= operand_a;
          5'h01: rsp_rdata <= operand_b;
          5'h02: rsp_rdata <= operand_c;
          5'h03: rsp_rdata <= result;
          5'h04: rsp_rdata <= {31'b0, mac_done};
          default: rsp_rdata <= 32'hDEAD_BEEF;
        endcase
      end

      // --------------------------------------------------
      // MAC completion (single-cycle)
      // --------------------------------------------------
      if (mac_busy) begin
        result   <= mac_full[31:0];
        mac_done <= 1'b1;
        mac_busy <= 1'b0;
      end
    end
  end

endmodule