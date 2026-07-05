module fifo_dualport_with_pipelined_sram #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_i,
    input  logic             wr_en_i,
    input  logic             rd_en_i,
    input  logic [WIDTH-1:0] data_i,
    output logic [WIDTH-1:0] data_o,
    output logic             empty_o,
    output logic             full_o
);

    localparam int LATENCY = 5;
    localparam int POINTER_WIDTH = $clog2(DEPTH);
    localparam int COUNTER_WIDTH = $clog2(DEPTH+1);
    localparam int MAX_PTR = POINTER_WIDTH'(DEPTH-1);
    localparam int LATENCY_COUNTER_WIDTH = $clog2(LATENCY);
    localparam int FIFO_COUNTER_WIDTH = $clog2((LATENCY*2)+1);

    logic [COUNTER_WIDTH - 1:0] sram_cnt;
    logic [POINTER_WIDTH - 1:0] wr_ptr;
    logic [POINTER_WIDTH - 1:0] wr_ptr_reg;
    logic [POINTER_WIDTH - 1:0] rd_ptr;
    logic [POINTER_WIDTH - 1:0] rd_ptr_reg;

    logic [FIFO_COUNTER_WIDTH - 1:0] input_buf_cnt;
    logic [FIFO_COUNTER_WIDTH - 1:0] output_buf_cnt;

    logic total_bypass_mode;
    logic sram_only_bypass_mode;

    logic sram_wen;
    logic sram_ren;

    logic sram_full;
    logic sram_empty;
    logic sram_wr_busy;
    logic sram_rd_busy;
    logic sram_data_vld;

    logic input_buf_pop;
    logic input_buf_push;
    logic input_buf_full;
    logic input_buf_empty;
    logic input_buf_wr_ready;
    logic input_buf_rd_ready;

    logic output_buf_pop;
    logic output_buf_push;
    logic output_buf_full;
    logic output_buf_empty;
    logic output_buf_wr_ready;
    logic output_buf_rd_ready;

    logic [WIDTH-1:0] sram_data_o;
    logic [WIDTH-1:0] input_buf_data_o;
    logic [WIDTH-1:0] out_buf_data_i;

    logic [LATENCY-1:0] sram_wr_latency_shift;
    logic [LATENCY_COUNTER_WIDTH - 1:0] sram_writes_in_progress_cnt;
    logic [LATENCY-1:0] sram_rd_latency_shift;
    logic [LATENCY_COUNTER_WIDTH - 1:0] sram_reads_in_progress_cnt;

    sram_dualport_latency_5 #(
        .WIDTH ( WIDTH ),
        .DEPTH ( DEPTH )
    ) i_mem (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .wen_i   (sram_wen),
        .ren_i   (sram_ren),
        .waddr_i (wr_ptr_reg),
        .raddr_i (rd_ptr_reg),
        .data_i  (input_buf_data_o),
        .data_o  (sram_data_o),
        .vld_o   (sram_data_vld)
    );

    flip_flop_fifo_with_counter #(
        .width(WIDTH),
        .depth(LATENCY*2)
    ) buffer_in (
        .clk(clk_i),
        .rst(rst_i),
        .push(input_buf_push),
        .pop(input_buf_pop),
        .write_data(data_i),
        .read_data(input_buf_data_o),
        .cnt(input_buf_cnt),
        .empty(input_buf_empty),
        .full(input_buf_full)
    );

    flip_flop_fifo_with_counter #(
        .width(WIDTH),
        .depth(LATENCY*2)
    ) buffer_out (
        .clk(clk_i),
        .rst(rst_i),
        .push(output_buf_push),
        .pop(output_buf_pop),
        .write_data(out_buf_data_i),
        .read_data(data_o),
        .cnt(output_buf_cnt),
        .empty(output_buf_empty),
        .full(output_buf_full)
    );

    always_ff @(posedge clk_i) begin    :   sram_memory_counter
        if (rst_i)                      sram_cnt <= '0;
        else if (sram_wen & ~sram_ren)  sram_cnt <= sram_cnt + 1'b1;
        else if (~sram_wen & sram_ren)  sram_cnt <= sram_cnt - 1'b1;
    end :   sram_memory_counter

    always_ff @(posedge clk_i) begin    :   sram_shift_counters_logic
        if (rst_i)  begin
            sram_wr_latency_shift <= '0;
            sram_rd_latency_shift <= '0;
        end
        else begin
            sram_wr_latency_shift <= {sram_wen, sram_wr_latency_shift[LATENCY-1:1]};
            sram_rd_latency_shift <= {sram_ren, sram_rd_latency_shift[LATENCY-1:1]};
        end
    end : sram_shift_counters_logic

    always_comb begin   :   sram_busy_flags_logic
        sram_wr_busy = |sram_wr_latency_shift;
        sram_rd_busy = |sram_rd_latency_shift;
    end :   sram_busy_flags_logic

    always_ff @(posedge clk_i) begin    :   actions_in_progress_counter
        if (rst_i)  begin
            sram_reads_in_progress_cnt <= '0;
            sram_writes_in_progress_cnt <= '0;
        end
        else    begin
            sram_reads_in_progress_cnt <= sram_reads_in_progress_cnt +
                                          LATENCY_COUNTER_WIDTH'(sram_ren) -
                                          LATENCY_COUNTER_WIDTH'(sram_rd_latency_shift[0]);

            sram_writes_in_progress_cnt <= sram_writes_in_progress_cnt +
                                           LATENCY_COUNTER_WIDTH'(sram_wen) -
                                           LATENCY_COUNTER_WIDTH'(sram_wr_latency_shift[0]);
        end
    end :   actions_in_progress_counter

    always_comb begin   :   sram_wen_logic
        sram_wen = '0;
        if (input_buf_rd_ready                          &
            !(sram_only_bypass_mode|total_bypass_mode)) begin
            sram_wen = '1;
        end
    end :   sram_wen_logic

    always_comb begin   :   sram_ren_logic
        sram_ren = '0;
        if (!sram_empty                                               &
            output_buf_wr_ready                                       &
            ((output_buf_cnt+sram_reads_in_progress_cnt)<(LATENCY*2)) &
            !(sram_only_bypass_mode|total_bypass_mode)) begin
            sram_ren = '1;
        end
    end :   sram_ren_logic

    always_comb begin   :   bypass_mode_logic
        total_bypass_mode = '0;
        sram_only_bypass_mode = '0;
        if (!output_buf_full & sram_empty & !sram_wr_busy & !sram_rd_busy & input_buf_empty)  total_bypass_mode = '1;
        if (!output_buf_full & sram_empty & !sram_wr_busy & !sram_rd_busy & !input_buf_empty) sram_only_bypass_mode = '1;
    end :   bypass_mode_logic

    always_comb begin   :   input_buffer_write_logic
        input_buf_push = '0;
        input_buf_wr_ready = (input_buf_pop | !input_buf_full);
        if (input_buf_wr_ready & !total_bypass_mode) begin
            if (wr_en_i)    input_buf_push = '1;
        end
    end : input_buffer_write_logic

    always_comb begin   :   input_buffer_read_logic
        input_buf_pop = '0;
        input_buf_rd_ready = (!sram_full & !input_buf_empty);
        if (input_buf_rd_ready) begin
            input_buf_pop = '1;
        end
    end : input_buffer_read_logic

    always_comb begin   :   output_buffer_in_data_MUX
        out_buf_data_i = sram_data_o;
        if      (sram_only_bypass_mode) out_buf_data_i = input_buf_data_o;
        else if (total_bypass_mode)     out_buf_data_i = data_i;
    end :   output_buffer_in_data_MUX

    always_comb begin   :   output_buffer_write_logic
        output_buf_push = '0;
        output_buf_wr_ready = (output_buf_full & rd_en_i)|(!output_buf_full);
        if (output_buf_wr_ready)    begin
            if      (sram_data_vld)                          output_buf_push = '1;
            else if (sram_empty & !input_buf_empty)          output_buf_push = '1;
            else if (sram_empty & input_buf_empty & wr_en_i) output_buf_push = '1;
        end
    end : output_buffer_write_logic

    always_comb begin   :   output_buffer_read_logic
        output_buf_pop = '0;
        output_buf_rd_ready = !output_buf_empty;
        if (output_buf_rd_ready)    begin
            if (rd_en_i)    output_buf_pop = '1;
        end
    end : output_buffer_read_logic

    always_comb begin   :   write_pointer_logic
                        wr_ptr = wr_ptr_reg;
        if (sram_wen)   wr_ptr = (wr_ptr==MAX_PTR)? '0 : wr_ptr + 1;
    end :   write_pointer_logic

    always_ff @(posedge clk_i)  begin   :   write_pointer_register
        if (rst_i)  wr_ptr_reg <= '0;
        else        wr_ptr_reg <= wr_ptr;
    end :   write_pointer_register

    always_comb begin   :   read_pointer_logic
                        rd_ptr = rd_ptr_reg;
        if (sram_ren)   rd_ptr = (rd_ptr==MAX_PTR)? '0 : rd_ptr + 1;
    end :   read_pointer_logic

    always_ff @(posedge clk_i)  begin   :   read_pointer_register
        if (rst_i)  rd_ptr_reg <= '0;
        else        rd_ptr_reg <= rd_ptr;
    end :   read_pointer_register

    always_comb begin   :   empty_flag_logic
        sram_empty = (sram_cnt == '0);
        empty_o = output_buf_empty;
    end : empty_flag_logic

    always_comb begin   :   full_flag_logic
        sram_full = sram_cnt == COUNTER_WIDTH'(DEPTH);
        full_o = input_buf_full  &
                 sram_full       &
                 output_buf_full;
    end :   full_flag_logic

endmodule