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
    localparam int latency = 5;

    localparam int ptr_depth     = $clog2(DEPTH);
    localparam int lts_cnt_depth = $clog2(latency);

    localparam int max_ptr = DEPTH-1;

    logic [lts_cnt_depth-1:0]   wr_lts_cnt;
    logic [lts_cnt_depth-1:0]   rd_lts_cnt;
    logic [ptr_depth-1:0] wr_ptr;
    logic [ptr_depth-1:0] wr_ptr_reg;

    logic [ptr_depth-1:0] rd_ptr;
    logic [ptr_depth-1:0] rd_ptr_reg;

    logic [    WIDTH-1:0] sram_data_out;
    logic [    WIDTH-1:0] sram_data_in;

    logic                 sram_valid_out;
    logic                 sram_wen_in;
    logic                 sram_ren_in;
    logic wr_reached;
    logic rd_reached;
    logic write_done;

    sram_dualport_latency_5 #(
        .WIDTH ( WIDTH ),
        .DEPTH ( DEPTH )
    ) i_mem (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .wen_i   (sram_wen_in),
        .ren_i   (sram_ren_in),
        .waddr_i (wr_ptr_reg),
        .raddr_i (rd_ptr_reg),
        .data_i  (data_i),
        .data_o  (data_o),
        .vld_o   (sram_valid_out)
    );

    always_comb begin   :   wen_logic
        sram_wen_in = '0;
        if (wr_en_i & (wr_ptr_reg<=max_ptr))    sram_wen_in = 1'b1;
    end :   wen_logic

    always_comb begin   :   ren_logic
        sram_ren_in = '0;
        if (rd_en_i & (rd_ptr_reg<wr_ptr_reg))        sram_ren_in = '1;
        if (write_done&!rd_reached) sram_ren_in = '1;
    end :   ren_logic

    always_comb begin   :   write_pointer_logic
        wr_ptr = wr_ptr_reg;
        if ((rd_ptr_reg==wr_ptr_reg)&(wr_ptr_reg != 0)) wr_ptr = '0;
        else if (wr_en_i & (wr_ptr_reg <=max_ptr))      wr_ptr = wr_ptr + 1'b1;
    end :   write_pointer_logic

    always_ff @(posedge clk_i) begin   :   write_pointer_register
        if (rst_i)  wr_ptr_reg <= '0;
        else        wr_ptr_reg <= wr_ptr;
    end :   write_pointer_register

    always_comb begin   :   read_pointer_logic
        rd_ptr = rd_ptr_reg;
        if ((rd_ptr_reg==wr_ptr_reg)&(rd_ptr_reg != 0)) rd_ptr = '0;
        else if (rd_en_i & wr_ptr_reg != 0)             rd_ptr = rd_ptr + 1'b1;
    end :   read_pointer_logic

    always_ff @(posedge clk_i) begin   :   read_pointer_register
        if (rst_i)  rd_ptr_reg <= '0;
        else        rd_ptr_reg <= rd_ptr;
    end :   read_pointer_register

    always_ff @(posedge clk_i) begin    :   write_latency_counter
        if (rst_i)                    wr_lts_cnt <= '0;
        else if (wr_lts_cnt >= latency)  wr_lts_cnt <= '0;
        else if (wr_reached)          wr_lts_cnt <= wr_lts_cnt + 1'b1;
    end :   write_latency_counter

    always_ff @(posedge clk_i) begin    :   read_latency_counter
        if (rst_i)                      rd_lts_cnt <= '0;
        else if (rd_lts_cnt >= latency) rd_lts_cnt <= '0;
        else if (rd_reached)            rd_lts_cnt <= rd_lts_cnt + 1'b1;
    end :   read_latency_counter

    always_ff @(posedge clk_i) begin    :   write_done_register
        if (rst_i)                       write_done <= '0;
        else if (wr_en_i)                write_done <= '0;
        else if (wr_lts_cnt >= latency)  write_done <= '1;
    end :   first_write_register

    always_ff @(posedge clk_i)  begin   :   write_state_reg
        if (rst_i)    begin
            wr_reached <= '0;
        end
        else if (wr_en_i&!wr_reached)   begin
            wr_reached <= 1'b1;
        end
        if (wr_lts_cnt >= latency)   begin
            wr_reached <= '0;
        end
    end :   write_state_reg

    always_ff @(posedge clk_i)  begin   :   read_state_reg
        if (rst_i)    begin
            rd_reached <= '0;
        end
        else if (rd_en_i&!rd_reached)   begin
            rd_reached <= 1'b1;
        end
        if (rd_lts_cnt >= latency)   begin
            rd_reached <= '0;
        end
    end :   read_state_reg

    always_comb begin   :   output_flags_logic
        full_o  = ((wr_ptr_reg-rd_ptr_reg)==(max_ptr+1));
        empty_o = (!sram_valid_out);
    end :   output_flags_logic

endmodule
