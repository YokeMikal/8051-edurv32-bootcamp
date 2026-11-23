`timescale 1ns/10ps
`include "oc8051_defines.v"

module tb_8051_day2;

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

  // External Data RAM interface (stubbed clean)
  reg  [7:0]  wbd_dat_i;
  wire [7:0]  wbd_dat_o;
  wire [15:0] wbd_adr_o;
  wire        wbd_we_o;
  reg         wbd_ack_i;
  wire        wbd_stb_o;
  wire        wbd_cyc_o;
  wire        wbd_err_i = 1'b0;

  // Peripherals & control (NOTE: int0_i / int1_i are active-low on oc8051_int, keep idle HIGH!)
  reg         int0_i;
  reg         int1_i;
  reg  [7:0]  p0_i, p1_i, p2_i, p3_i;
  wire [7:0]  p0_o, p1_o, p2_o, p3_o;
  reg         rxd_i;
  wire        txd_o;
  reg         t0_i, t1_i, t2_i, t2ex_i;
  wire        ea_in = 1'b0;

  reg [7:0] rom_mem [0:65535];
  integer idx;

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

  // Hierarchical observation probes (WBS 2.1 - 2.4 / E05 - E07)
  wire [15:0] dbg_pc_buf    = dut.oc8051_memory_interface1.pc_buf;
  wire [2:0]  dbg_op_pos    = dut.oc8051_memory_interface1.op_pos;
  wire [15:0] dbg_cur_pc    = dbg_pc_buf - 16'h0008 + {13'h0, dbg_op_pos};
  wire [15:0] dbg_pc_reg    = dut.pc;
  wire [7:0]  dbg_op1       = dut.op1_n;
  wire [7:0]  dbg_acc       = dut.acc;
  wire [7:0]  dbg_psw       = dut.oc8051_sfr1.psw;
  wire [7:0]  dbg_sp        = dut.sp;
  wire        dbg_rmw       = dut.rmw;
  wire [3:0]  dbg_prescaler = dut.oc8051_sfr1.prescaler;
  wire        dbg_pres_ow   = dut.oc8051_sfr1.pres_ow;
  wire [7:0]  dbg_tmod      = dut.oc8051_sfr1.oc8051_tc1.tmod;
  wire [7:0]  dbg_tl0       = dut.oc8051_sfr1.oc8051_tc1.tl0;
  wire [7:0]  dbg_th0       = dut.oc8051_sfr1.oc8051_tc1.th0;
  wire [7:0]  dbg_tcon      = dut.oc8051_sfr1.tcon;
  wire        dbg_tr0       = dbg_tcon[4];
  wire        dbg_tf0       = dbg_tcon[5];
  wire [7:0]  dbg_ie        = dut.oc8051_sfr1.ie;
  wire        dbg_intr      = dut.intr;
  wire [7:0]  dbg_int_vec   = dut.int_src;
  wire        dbg_int_ack   = dut.int_ack;
  wire        dbg_int_proc  = dut.oc8051_sfr1.oc8051_int1.int_proc;
  wire [1:0]  dbg_int_dept  = dut.oc8051_sfr1.oc8051_int1.int_dept;
  wire        dbg_reti      = dut.oc8051_sfr1.oc8051_int1.reti;
  wire [7:0]  dbg_ram20     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h20];
  wire [7:0]  dbg_ram30     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h30];
  wire [7:0]  dbg_ram31     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h31];
  wire [7:0]  dbg_ram32     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h32];
  wire [7:0]  dbg_stk08     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h08];
  wire [7:0]  dbg_stk09     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h09];
  wire [7:0]  dbg_stk0a     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h0A];
  wire [7:0]  dbg_stk0b     = dut.oc8051_ram_top1.oc8051_idata.buff[8'h0B];

  reg        dbg_booted;
  reg [7:0]  max_sp;
  reg [7:0]  prev_p0, prev_p3, prev_tl0, prev_tcon, prev_sp, prev_acc, prev_ram30, prev_ram31, prev_ram32;
  reg        prev_tf0, prev_intr, prev_ack, prev_reti, prev_proc;
  integer    p0_stage;
  integer    pres_ow_cnt, tf0_rise_cnt;
  integer    intr_cnt, vec0b_seen, ack_cnt, reti_cnt;

  // 50 MHz clock
  initial begin
    wb_clk_i = 1'b0;
    forever #10 wb_clk_i = ~wb_clk_i;
  end

  // External ROM responder (0-wait-state pipelined)
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
    if (!$value$plusargs("ROM_FILE=%s", rom_file))     rom_file = "firmware/asm/test_e05_gpio.in";
    if (!$value$plusargs("VCD_FILE=%s", vcd_file))     vcd_file = "traces/e05_gpio.vcd";
    if (!$value$plusargs("TRACE_FILE=%s", trace_file)) trace_file = "reports/e05_gpio_trace.csv";
    if (!$value$plusargs("TEST_NAME=%s", test_name))   test_name = "e05_gpio";

    for (idx = 0; idx < 65536; idx = idx + 1)
      rom_mem[idx] = 8'h00;
    $readmemh(rom_file, rom_mem);

    for (idx = 0; idx < 257; idx = idx + 1)
      dut.oc8051_ram_top1.oc8051_idata.buff[idx] = 8'h00;

    $dumpfile(vcd_file);
    $dumpvars(0, tb_8051_day2);

    trace_fd = $fopen(trace_file, "w");
    $fwrite(trace_fd,
      "cycle,time_ns,booted,cur_pc,pc_reg,op1,acc,psw,sp,p0_o,p1_o,p3_o,rmw,prescaler,pres_ow,tmod,tl0,th0,tcon,tr0,tf0,ie,intr,int_vec,int_ack,int_proc,int_dept,reti,ram20,ram30,ram31,ram32,stk08,stk09,stk0a,stk0b\n");

    wb_rst_i   = 1'b1;
    int0_i     = 1'b1; // Active-low external interrupt idle HIGH
    int1_i     = 1'b1;
    p0_i       = 8'hC3; // Distinct from latch A9h to prove rmw=0 reads pin vs rmw=1 reads latch
    p1_i       = 8'h00;
    p2_i       = 8'hA5; // Pin pattern read by E05
    p3_i       = 8'h00;
    rxd_i      = 1'b1;
    t0_i       = 1'b0;
    t1_i       = 1'b0;
    t2_i       = 1'b0;
    t2ex_i     = 1'b0;

    dbg_booted   = 1'b0;
    max_sp       = 8'h07;
    cyc          = 0;
    done_seen    = 0;
    settle_cnt   = 0;
    errors       = 0;
    p0_stage     = 0;
    pres_ow_cnt  = 0;
    tf0_rise_cnt = 0;
    intr_cnt     = 0;
    vec0b_seen   = 0;
    ack_cnt      = 0;
    reti_cnt     = 0;

    repeat (5) @(posedge wb_clk_i);
    @(negedge wb_clk_i);
    wb_rst_i = 1'b0;

    prev_p0    = p0_o;
    prev_p3    = p3_o;
    prev_tl0   = dbg_tl0;
    prev_tcon  = dbg_tcon;
    prev_sp    = dbg_sp;
    prev_acc   = dbg_acc;
    prev_ram30 = dbg_ram30;
    prev_ram31 = dbg_ram31;
    prev_ram32 = dbg_ram32;
    prev_tf0   = dbg_tf0;
    prev_intr  = dbg_intr;
    prev_ack   = dbg_int_ack;
    prev_reti  = dbg_reti;
    prev_proc  = dbg_int_proc;

    $display("[TB_MONITOR] Test=%0s | Reset released at time=%0t | p0_i=%02h p2_i=%02h int0_i=%b int1_i=%b",
             test_name, $time, p0_i, p2_i, int0_i, int1_i);
  end

  always @(negedge wb_clk_i) begin
    if (!wb_rst_i) begin
      cyc = cyc + 1;
      if (!dbg_booted && (dbg_pc_buf >= 16'h0008))
        dbg_booted = 1'b1;
      if (dbg_sp > max_sp)
        max_sp = dbg_sp;

      $fwrite(trace_fd,
        "%0d,%0t,%0d,%04h,%04h,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%0d,%0d,%0d,%02h,%02h,%02h,%02h,%0d,%0d,%02h,%0d,%02h,%0d,%0d,%0d,%0d,%02h,%02h,%02h,%02h,%02h,%02h,%02h,%02h\n",
        cyc, $time, dbg_booted, dbg_cur_pc, dbg_pc_reg, dbg_op1,
        dbg_acc, dbg_psw, dbg_sp, p0_o, p1_o, p3_o, dbg_rmw,
        dbg_prescaler, dbg_pres_ow, dbg_tmod, dbg_tl0, dbg_th0, dbg_tcon, dbg_tr0, dbg_tf0,
        dbg_ie, dbg_intr, dbg_int_vec, dbg_int_ack, dbg_int_proc, dbg_int_dept, dbg_reti,
        dbg_ram20, dbg_ram30, dbg_ram31, dbg_ram32, dbg_stk08, dbg_stk09, dbg_stk0a, dbg_stk0b);

      // Sequence tracking for E05
      if (test_name == "e05_gpio") begin
        if (p0_stage == 0 && p0_o == 8'h5A) p0_stage = 1;
        else if (p0_stage == 1 && p0_o == 8'h5B) p0_stage = 2;
        else if (p0_stage == 2 && p0_o == 8'h59) p0_stage = 3;
        else if (p0_stage == 3 && p0_o == 8'hA9) p0_stage = 4;

        if (p0_o !== prev_p0 || p3_o !== prev_p3 || dbg_ram30 !== prev_ram30 || dbg_ram31 !== prev_ram31) begin
          $display("[TB_E05] cyc=%0d t=%0t cur_pc=%04h op=%02h rmw=%0d | P0_o=%02h P3_o=%02h ACC=%02h RAM30=%02h RAM31=%02h",
            cyc, $time, dbg_cur_pc, dbg_op1, dbg_rmw, p0_o, p3_o, dbg_acc, dbg_ram30, dbg_ram31);
        end
      end

      // Event tracking for E06
      if (dbg_pres_ow)
        pres_ow_cnt = pres_ow_cnt + 1;
      if (!prev_tf0 && dbg_tf0) begin
        tf0_rise_cnt = tf0_rise_cnt + 1;
        if (test_name == "e06_timer")
          $display("[TB_E06_OVF] cyc=%0d t=%0t Overflow #%0d | TL0=%02h TH0=%02h TCON=%02h",
            cyc, $time, tf0_rise_cnt, dbg_tl0, dbg_th0, dbg_tcon);
      end
      if (test_name == "e06_timer" && (dbg_tl0 !== prev_tl0 || p0_o !== prev_p0 || dbg_ram32 !== prev_ram32)) begin
        $display("[TB_E06] cyc=%0d t=%0t pres_ow=%0d | TR0=%0d TF0=%0d TL0=%02h P0_o=%02h RAM[30..32]=%02h,%02h,%02h",
          cyc, $time, dbg_pres_ow, dbg_tr0, dbg_tf0, dbg_tl0, p0_o, dbg_ram30, dbg_ram31, dbg_ram32);
      end

      // Event tracking for E07
      if (!prev_intr && dbg_intr) begin
        intr_cnt = intr_cnt + 1;
        if (dbg_int_vec == 8'h0B)
          vec0b_seen = 1;
      end
      if (!prev_ack && dbg_int_ack)
        ack_cnt = ack_cnt + 1;
      if (!prev_reti && dbg_reti)
        reti_cnt = reti_cnt + 1;

      if (test_name == "e07_irq" && (
          dbg_intr !== prev_intr || dbg_int_ack !== prev_ack || dbg_int_proc !== prev_proc ||
          dbg_reti !== prev_reti || dbg_sp !== prev_sp || dbg_ram31 !== prev_ram31 ||
          dbg_ram32 !== prev_ram32 || p0_o !== prev_p0)) begin
        $display("[TB_E07] cyc=%0d t=%0t pc_reg=%04h op=%02h | intr=%0d vec=%02h ack=%0d proc=%0d reti=%0d SP=%02h ACC=%02h PSW=%02h RAM20=%02h RAM30..32=%02h,%02h,%02h",
          cyc, $time, dbg_pc_reg, dbg_op1, dbg_intr, dbg_int_vec, dbg_int_ack, dbg_int_proc, dbg_reti,
          dbg_sp, dbg_acc, dbg_psw, dbg_ram20, dbg_ram30, dbg_ram31, dbg_ram32);
      end

      prev_p0    = p0_o;
      prev_p3    = p3_o;
      prev_tl0   = dbg_tl0;
      prev_tcon  = dbg_tcon;
      prev_sp    = dbg_sp;
      prev_acc   = dbg_acc;
      prev_ram30 = dbg_ram30;
      prev_ram31 = dbg_ram31;
      prev_ram32 = dbg_ram32;
      prev_tf0   = dbg_tf0;
      prev_intr  = dbg_intr;
      prev_ack   = dbg_int_ack;
      prev_reti  = dbg_reti;
      prev_proc  = dbg_int_proc;

      if (dbg_booted && !done_seen && (p1_o == 8'h7F)) begin
        done_seen = 1;
        $display("[TB_MONITOR] cyc=%0d t=%0t Sentinel P1=7Fh observed; settling 6 cycles...", cyc, $time);
      end

      if (done_seen) begin
        settle_cnt = settle_cnt + 1;
        if (settle_cnt >= 6) begin
          if (test_name == "e05_gpio") begin
            if (p0_stage !== 4) begin
              $display("[TB_ERROR] e05_gpio: Expected P0_o sequence 5A->5B->59->A9, stage=%0d", p0_stage);
              errors = errors + 1;
            end
            if (p0_o !== 8'hA9 || p3_o !== 8'h3C) begin
              $display("[TB_ERROR] e05_gpio: Expected P0_o=A9h P3_o=3Ch, got P0_o=%02h P3_o=%02h", p0_o, p3_o);
              errors = errors + 1;
            end
            if (dbg_ram30 !== 8'hA5 || dbg_ram31 !== 8'hC3) begin
              $display("[TB_ERROR] e05_gpio: Expected RAM[30h]=A5h RAM[31h]=C3h, got %02h, %02h", dbg_ram30, dbg_ram31);
              errors = errors + 1;
            end
          end else if (test_name == "e06_timer") begin
            if (tf0_rise_cnt < 2) begin
              $display("[TB_ERROR] e06_timer: Expected >=2 TF0 overflows, got %0d", tf0_rise_cnt);
              errors = errors + 1;
            end
            if (dbg_ram30 !== 8'hFC || dbg_ram31 !== 8'hFC || dbg_ram32 !== 8'h02) begin
              $display("[TB_ERROR] e06_timer: Expected RAM[30..32]=FC,FC,02, got %02h,%02h,%02h",
                       dbg_ram30, dbg_ram31, dbg_ram32);
              errors = errors + 1;
            end
            if (p0_o !== 8'h02 || dbg_tr0 !== 1'b0) begin
              $display("[TB_ERROR] e06_timer: Expected P0_o=02h TR0=0, got P0_o=%02h TR0=%0d", p0_o, dbg_tr0);
              errors = errors + 1;
            end
          end else if (test_name == "e07_irq") begin
            if (intr_cnt < 1 || !vec0b_seen || ack_cnt < 1 || reti_cnt < 1) begin
              $display("[TB_ERROR] e07_irq: Expected intr/vec0B/ack/reti, got intr=%0d vec0b=%0d ack=%0d reti=%0d",
                       intr_cnt, vec0b_seen, ack_cnt, reti_cnt);
              errors = errors + 1;
            end
            if (max_sp !== 8'h0B || dbg_sp !== 8'h07 || dbg_int_proc !== 1'b0) begin
              $display("[TB_ERROR] e07_irq: Expected max_sp=0Bh SP=07h int_proc=0, got max_sp=%02h SP=%02h proc=%0d",
                       max_sp, dbg_sp, dbg_int_proc);
              errors = errors + 1;
            end
            if (dbg_ram20 !== 8'h01 || dbg_ram30 !== 8'h01 || dbg_ram31 !== 8'h55 || ((dbg_ram32 & 8'h80) !== 8'h80)) begin
              $display("[TB_ERROR] e07_irq: Expected RAM20=01 RAM30=01 RAM31=55 RAM32.7=1, got %02h,%02h,%02h,%02h",
                       dbg_ram20, dbg_ram30, dbg_ram31, dbg_ram32);
              errors = errors + 1;
            end
            if (p0_o !== 8'hA5 || dbg_stk0a !== 8'h55) begin
              $display("[TB_ERROR] e07_irq: Expected P0_o=A5h stk0a=55h, got P0_o=%02h stk0a=%02h", p0_o, dbg_stk0a);
              errors = errors + 1;
            end
          end

          $display("[TB_MONITOR] Summary Test=%0s cyc=%0d max_sp=%02h stk08..0b=%02h,%02h,%02h,%02h P0_o=%02h P3_o=%02h RAM20=%02h RAM30..32=%02h,%02h,%02h ACC=%02h PSW=%02h SP=%02h pres_ow=%0d tf0_ovf=%0d intr=%0d ack=%0d reti=%0d",
            test_name, cyc, max_sp, dbg_stk08, dbg_stk09, dbg_stk0a, dbg_stk0b,
            p0_o, p3_o, dbg_ram20, dbg_ram30, dbg_ram31, dbg_ram32,
            dbg_acc, dbg_psw, dbg_sp, pres_ow_cnt, tf0_rise_cnt, intr_cnt, ack_cnt, reti_cnt);

          $fclose(trace_fd);
          if (errors == 0) begin
            $display("[TB_INFO] Simulation Finished!");
            $display("[FINISH] PASS");
          end else begin
            $display("[FINISH] FAIL errors=%0d", errors);
          end
          $finish;
        end
      end else if (cyc >= 1500) begin
        $display("[TB_ERROR] Timeout after %0d cycles without sentinel P1=7Fh (pc_reg=%04h P1=%02h int_proc=%0d)",
                 cyc, dbg_pc_reg, p1_o, dbg_int_proc);
        $fclose(trace_fd);
        $display("[FINISH] FAIL timeout");
        $finish;
      end
    end
  end

endmodule
