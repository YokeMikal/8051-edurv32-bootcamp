`timescale 1ns/10ps
`include "oc8051_defines.v"

module tb_8051_day1;

  // Clock & reset
  reg wb_clk_i;
  reg wb_rst_i;

  // Program ROM interface (Wishbone/pipelined)
  wire [15:0] wbi_adr_o;
  reg  [31:0] wbi_dat_i;
  wire        wbi_stb_o;
  reg         wbi_ack_i;
  wire        wbi_cyc_o;
  wire        wbi_err_i = 1'b0;

  // External Data RAM interface (stubbed clean for Day 1)
  reg  [7:0]  wbd_dat_i;
  wire [7:0]  wbd_dat_o;
  wire [15:0] wbd_adr_o;
  wire        wbd_we_o;
  reg         wbd_ack_i;
  wire        wbd_stb_o;
  wire        wbd_cyc_o;
  wire        wbd_err_i = 1'b0;

  // Peripherals & control
  reg         int0_i;
  reg         int1_i;
  reg  [7:0]  p0_i, p1_i, p2_i, p3_i;
  wire [7:0]  p0_o, p1_o, p2_o, p3_o;
  reg         rxd_i;
  wire        txd_o;
  reg         t0_i, t1_i, t2_i, t2ex_i;
  wire        ea_in = 1'b0; // External ROM via wbi_*

  // 64KB External Program ROM model
  reg [7:0] rom_mem [0:65535];
  integer idx;

  // DUT instantiation
  oc8051_top dut (
    .wb_rst_i (wb_rst_i),
    .wb_clk_i (wb_clk_i),
    .wbi_adr_o(wbi_adr_o),
    .wbi_dat_i(wbi_dat_i),
    .wbi_stb_o(wbi_stb_o),
    .wbi_ack_i(wbi_ack_i),
    .wbi_cyc_o(wbi_cyc_o),
    .wbi_err_i(wbi_err_i),
    .wbd_dat_i(wbd_dat_i),
    .wbd_dat_o(wbd_dat_o),
    .wbd_adr_o(wbd_adr_o),
    .wbd_we_o (wbd_we_o),
    .wbd_ack_i(wbd_ack_i),
    .wbd_stb_o(wbd_stb_o),
    .wbd_cyc_o(wbd_cyc_o),
    .wbd_err_i(wbd_err_i),
    .int0_i   (int0_i),
    .int1_i   (int1_i),
    .p0_i     (p0_i),
    .p0_o     (p0_o),
    .p1_i     (p1_i),
    .p1_o     (p1_o),
    .p2_i     (p2_i),
    .p2_o     (p2_o),
    .p3_i     (p3_i),
    .p3_o     (p3_o),
    .rxd_i    (rxd_i),
    .txd_o    (txd_o),
    .t0_i     (t0_i),
    .t1_i     (t1_i),
    .t2_i     (t2_i),
    .t2ex_i   (t2ex_i),
    .ea_in    (ea_in)
  );

  // Top-level waveform observation probes (WBS 1.1-1.8 / P-04)
  wire [15:0] dbg_pc_buf   = dut.oc8051_memory_interface1.pc_buf;
  wire [2:0]  dbg_op_pos   = dut.oc8051_memory_interface1.op_pos;
  wire [15:0] dbg_cur_pc   = dbg_pc_buf - 16'h0008 + {13'h0, dbg_op_pos};
  wire [15:0] dbg_pc_reg   = dut.pc;
  wire [7:0]  dbg_op1      = dut.op1_n;
  wire [7:0]  dbg_op2      = dut.op2_n;
  wire [7:0]  dbg_op3      = dut.op3_n;
  wire [1:0]  dbg_op_len   = dut.oc8051_memory_interface1.op_length;
  wire [1:0]  dbg_state    = dut.oc8051_decoder1.state;
  wire        dbg_rd       = dut.rd;
  wire        dbg_mem_wait = dut.mem_wait;
  wire        dbg_wait_dat = dut.wait_data;
  wire [3:0]  dbg_alu_op   = dut.alu_op;
  wire [7:0]  dbg_src1     = dut.src1;
  wire [7:0]  dbg_src2     = dut.src2;
  wire [7:0]  dbg_des_acc  = dut.des_acc;
  wire [7:0]  dbg_acc      = dut.acc;
  wire [7:0]  dbg_b        = dut.oc8051_sfr1.b_reg;
  wire [7:0]  dbg_psw      = dut.oc8051_sfr1.psw;
  wire [7:0]  dbg_sp       = dut.sp;
  wire [15:0] dbg_dptr     = {dut.dptr_hi, dut.dptr_lo};
  wire        dbg_ram_wr   = dut.oc8051_ram_top1.wr;
  wire [7:0]  dbg_wr_addr  = dut.wr_addr;
  wire [7:0]  dbg_wr_dat   = dut.wr_dat;
  wire [7:0]  dbg_ram30    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h30];
  wire [7:0]  dbg_ram31    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h31];
  wire [7:0]  dbg_ram32    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h32];
  wire [7:0]  dbg_ram33    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h33];
  wire [7:0]  dbg_ram34    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h34];
  wire [7:0]  dbg_ram40    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h40];
  wire [7:0]  dbg_r0       = dut.oc8051_ram_top1.oc8051_idata.buff[8'h00];
  wire [7:0]  dbg_r2       = dut.oc8051_ram_top1.oc8051_idata.buff[8'h02];
  wire [7:0]  dbg_stk08    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h08];
  wire [7:0]  dbg_stk09    = dut.oc8051_ram_top1.oc8051_idata.buff[8'h09];
  wire [7:0]  dbg_p0       = p0_o;
  wire [7:0]  dbg_p1       = p1_o;

  reg dbg_booted;
  reg [7:0] max_sp;
  reg [7:0] prev_acc, prev_psw, prev_sp, prev_p0, prev_p1;
  reg [7:0] prev_ram30, prev_ram31, prev_ram34, prev_ram40;

  // 50 MHz clock
  initial begin
    wb_clk_i = 1'b0;
    forever #10 wb_clk_i = ~wb_clk_i;
  end

  // External ROM responder (0-wait-state pipelined, identical to oc8051_xrom DELAY=0)
  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
      wbi_dat_i <= 32'h0000_0000;
      wbi_ack_i <= 1'b0;
    end else if (wbi_stb_o) begin
      wbi_dat_i <= {rom_mem[wbi_adr_o + 16'h3], rom_mem[wbi_adr_o + 16'h2],
                    rom_mem[wbi_adr_o + 16'h1], rom_mem[wbi_adr_o]};
      wbi_ack_i <= 1'b1;
    end else begin
      wbi_ack_i <= 1'b0;
    end
  end

  // Dummy XRAM responder
  always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
      wbd_ack_i <= 1'b0;
      wbd_dat_i <= 8'h00;
    end else begin
      wbd_ack_i <= wbd_stb_o;
      wbd_dat_i <= 8'h00;
    end
  end

  // Runtime arguments & files
  reg [8*256-1:0] rom_file;
  reg [8*256-1:0] vcd_file;
  reg [8*256-1:0] trace_file;
  reg [8*64-1:0]  test_name;
  integer trace_fd;
  integer cyc;
  integer done_seen;
  integer settle_cnt;
  integer errors;

  initial begin
    if (!$value$plusargs("ROM_FILE=%s", rom_file))     rom_file = "firmware/asm/test_a_arith.in";
    if (!$value$plusargs("VCD_FILE=%s", vcd_file))     vcd_file = "traces/test_a.vcd";
    if (!$value$plusargs("TRACE_FILE=%s", trace_file)) trace_file = "reports/test_a_trace.csv";
    if (!$value$plusargs("TEST_NAME=%s", test_name))   test_name = "test_a";

    for (idx = 0; idx < 65536; idx = idx + 1)
      rom_mem[idx] = 8'h00;
    $readmemh(rom_file, rom_mem);

    for (idx = 0; idx < 257; idx = idx + 1)
      dut.oc8051_ram_top1.oc8051_idata.buff[idx] = 8'h00;

    $dumpfile(vcd_file);
    $dumpvars(0, tb_8051_day1);

    trace_fd = $fopen(trace_file, "w");
    $fwrite(trace_fd,
      "cycle,time_ns,booted,pc_buf,op_pos,cur_pc,pc_reg,wbi_adr,state,rd,mem_wait,wait_data,op1,op2,op3,op_len,alu_op,src1,src2,des_acc,acc,b,psw,sp,dptr,ram_wr,wr_addr,wr_dat,ram30,ram31,ram32,ram33,ram34,ram40,r0,r2,stk08,stk09,p0,p1\n");

    wb_rst_i   = 1'b1;
    int0_i     = 1'b0;
    int1_i     = 1'b0;
    p0_i       = 8'h00;
    p1_i       = 8'h00;
    p2_i       = 8'h00;
    p3_i       = 8'h00;
    rxd_i      = 1'b1;
    t0_i       = 1'b0;
    t1_i       = 1'b0;
    t2_i       = 1'b0;
    t2ex_i     = 1'b0;
    dbg_booted = 1'b0;
    max_sp     = 8'h07;
    cyc        = 0;
    done_seen  = 0;
    settle_cnt = 0;
    errors     = 0;

    repeat (5) @(posedge wb_clk_i);
    @(negedge wb_clk_i);
    wb_rst_i = 1'b0;

    prev_acc   = dbg_acc;
    prev_psw   = dbg_psw;
    prev_sp    = dbg_sp;
    prev_p0    = dbg_p0;
    prev_p1    = dbg_p1;
    prev_ram30 = dbg_ram30;
    prev_ram31 = dbg_ram31;
    prev_ram34 = dbg_ram34;
    prev_ram40 = dbg_ram40;

    $display("[TB_MONITOR] Test=%0s | Reset released at time=%0t | PC=%04h SP=%02h ACC=%02h PSW=%02h",
             test_name, $time, dbg_pc_reg, dbg_sp, dbg_acc, dbg_psw);
  end

  always @(negedge wb_clk_i) begin
    if (!wb_rst_i) begin
      cyc = cyc + 1;
      if (!dbg_booted && (dbg_pc_buf >= 16'h0008))
        dbg_booted = 1'b1;
      if (dbg_sp > max_sp)
        max_sp = dbg_sp;

      $fwrite(trace_fd,
        "%0d,%0t,%0d,%04h,%0d,%04h,%04h,%04h,%0d,%0d,%0d,%0d,%02h,%02h,%02h,%0d,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%04h,%0d,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h\n",
        cyc, $time, dbg_booted, dbg_pc_buf, dbg_op_pos, dbg_cur_pc, dbg_pc_reg, wbi_adr_o,
        dbg_state, dbg_rd, dbg_mem_wait, dbg_wait_dat,
        dbg_op1, dbg_op2, dbg_op3, dbg_op_len,
        dbg_alu_op, dbg_src1, dbg_src2, dbg_des_acc,
        dbg_acc, dbg_b, dbg_psw, dbg_sp, dbg_dptr,
        dbg_ram_wr, dbg_wr_addr, dbg_wr_dat,
        dbg_ram30, dbg_ram31, dbg_ram32, dbg_ram33, dbg_ram34, dbg_ram40,
        dbg_r0, dbg_r2, dbg_stk08, dbg_stk09, dbg_p0, dbg_p1);

      if (dbg_booted && (dbg_acc !== prev_acc || dbg_psw !== prev_psw || dbg_sp !== prev_sp ||
          dbg_p0 !== prev_p0 || dbg_p1 !== prev_p1 ||
          dbg_ram30 !== prev_ram30 || dbg_ram31 !== prev_ram31 ||
          dbg_ram34 !== prev_ram34 || dbg_ram40 !== prev_ram40)) begin
        $display("[TB_DATA] cyc=%0d t=%0t cur_pc=%04h op=%02h | ACC=%02h PSW=%02h SP=%02h R0=%02h R2=%02h RAM[30..34]=%02h,%02h,%02h,%02h,%02h RAM[40]=%02h P0=%02h P1=%02h",
          cyc, $time, dbg_cur_pc, dbg_op1,
          dbg_acc, dbg_psw, dbg_sp, dbg_r0, dbg_r2,
          dbg_ram30, dbg_ram31, dbg_ram32, dbg_ram33, dbg_ram34, dbg_ram40, dbg_p0, dbg_p1);
      end

      prev_acc   = dbg_acc;
      prev_psw   = dbg_psw;
      prev_sp    = dbg_sp;
      prev_p0    = dbg_p0;
      prev_p1    = dbg_p1;
      prev_ram30 = dbg_ram30;
      prev_ram31 = dbg_ram31;
      prev_ram34 = dbg_ram34;
      prev_ram40 = dbg_ram40;

      if (dbg_booted && !done_seen && (p1_o == 8'h7F)) begin
        done_seen = 1;
        $display("[TB_MONITOR] cyc=%0d t=%0t Sentinel P1=7Fh observed; settling 6 cycles...", cyc, $time);
      end

      if (done_seen) begin
        settle_cnt = settle_cnt + 1;
        if (settle_cnt >= 6) begin
          // Run test-specific self-checks
          if (test_name == "hello") begin
            if (dbg_p0 !== 8'h55) begin
              $display("[TB_ERROR] hello: P0 expected 55h, got %02h", dbg_p0);
              errors = errors + 1;
            end
            if (dbg_ram30 !== 8'hAA) begin
              $display("[TB_ERROR] hello: RAM[30h] expected AAh, got %02h", dbg_ram30);
              errors = errors + 1;
            end
            if (dbg_acc !== 8'hAA) begin
              $display("[TB_ERROR] hello: ACC expected AAh, got %02h", dbg_acc);
              errors = errors + 1;
            end
          end else if (test_name == "test_a") begin
            if (dbg_ram30 !== 8'h08) begin
              $display("[TB_ERROR] test_a (Gate H1 Test A): RAM[30h] expected 08h, got %02h", dbg_ram30);
              errors = errors + 1;
            end
            if (dbg_ram31 !== 8'h09) begin
              $display("[TB_ERROR] test_a: RAM[31h] expected 09h, got %02h", dbg_ram31);
              errors = errors + 1;
            end
            if (dbg_ram32 !== 8'h07) begin
              $display("[TB_ERROR] test_a: RAM[32h] expected 07h, got %02h", dbg_ram32);
              errors = errors + 1;
            end
            if (dbg_ram33 !== 8'h03) begin
              $display("[TB_ERROR] test_a: RAM[33h] expected 03h, got %02h", dbg_ram33);
              errors = errors + 1;
            end
            if (dbg_ram34 !== 8'hC0) begin
              $display("[TB_ERROR] test_a: RAM[34h] (PSW) expected C0h, got %02h", dbg_ram34);
              errors = errors + 1;
            end
            if (dbg_acc !== 8'h03 || dbg_psw !== 8'hC0 || dbg_sp !== 8'h07) begin
              $display("[TB_ERROR] test_a: Final ACC=%02h(exp 03h) PSW=%02h(exp C0h) SP=%02h(exp 07h)",
                       dbg_acc, dbg_psw, dbg_sp);
              errors = errors + 1;
            end
          end else if (test_name == "test_b") begin
            if (dbg_ram30 !== 8'h0C) begin
              $display("[TB_ERROR] test_b (DJNZ loop): RAM[30h] expected 0Ch, got %02h", dbg_ram30);
              errors = errors + 1;
            end
            if (dbg_r2 !== 8'h00) begin
              $display("[TB_ERROR] test_b: R2 expected 00h, got %02h", dbg_r2);
              errors = errors + 1;
            end
            if (dbg_ram31 !== 8'h16) begin
              $display("[TB_ERROR] test_b (LCALL/RET): RAM[31h] expected 16h, got %02h", dbg_ram31);
              errors = errors + 1;
            end
            if (dbg_ram40 !== 8'h16) begin
              $display("[TB_ERROR] test_b (Indirect @R0): RAM[40h] expected 16h, got %02h", dbg_ram40);
              errors = errors + 1;
            end
            if (max_sp !== 8'h09 || dbg_sp !== 8'h07) begin
              $display("[TB_ERROR] test_b (Stack): max_sp=%02h(exp 09h) final_sp=%02h(exp 07h)",
                       max_sp, dbg_sp);
              errors = errors + 1;
            end
            if (dbg_stk08 !== 8'h11 || dbg_stk09 !== 8'h00) begin
              $display("[TB_ERROR] test_b (Return addr on stack): stk08=%02h stk09=%02h (exp 11h, 00h)",
                       dbg_stk08, dbg_stk09);
              errors = errors + 1;
            end
          end

          $display("[TB_MONITOR] Summary Test=%0s cyc=%0d max_sp=%02h stk08=%02h stk09=%02h RAM30=%02h RAM31=%02h RAM34=%02h RAM40=%02h ACC=%02h PSW=%02h SP=%02h",
            test_name, cyc, max_sp, dbg_stk08, dbg_stk09,
            dbg_ram30, dbg_ram31, dbg_ram34, dbg_ram40, dbg_acc, dbg_psw, dbg_sp);

          $fclose(trace_fd);
          if (errors == 0) begin
            $display("[TB_INFO] Simulation Finished!");
            $display("[FINISH] PASS");
          end else begin
            $display("[FINISH] FAIL errors=%0d", errors);
          end
          $finish;
        end
      end else if (cyc >= 400) begin
        $display("[TB_ERROR] Timeout after %0d cycles without sentinel P1=7Fh", cyc);
        $fclose(trace_fd);
        $display("[FINISH] FAIL timeout");
        $finish;
      end
    end
  end

endmodule
