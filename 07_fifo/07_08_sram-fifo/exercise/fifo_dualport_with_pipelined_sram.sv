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

    sram_dualport_latency_5 #(
        .WIDTH ( WIDTH ),
        .DEPTH ( DEPTH )
    ) i_mem (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .wen_i   (),
        .ren_i   (),
        .waddr_i (),
        .raddr_i (),
        .data_i  (data_i),
        .data_o  (data_o),
        .vld_o   ()
    );

    flip_flop_fifo_with_counter #(
        .width(WIDTH),
        .depth(LATENCY)
    ) buffer_in (
        .clk(clk_i),
        .rst(rst_i),
        .push(),
        .pop(),
        .write_data(),
        .read_data(),
        .empty(),
        .full()
    );

    flip_flop_fifo_with_counter #(
        .width(WIDTH),
        .depth(LATENCY)
    ) buffer_out (
        .clk(clk_i),
        .rst(rst_i),
        .push(),
        .pop(),
        .write_data(),
        .read_data(),
        .empty(),
        .full()
    );

    always_comb begin   :   data_out_MUX

    end :   data_out_MUX

    always_comb begin   :   wen_logic

    end :   wen_logic

    always_comb begin   :   write_pointer_logic

    end :   write_pointer_logic

    always_comb begin   :   write_pointer_register

    end :   write_pointer_register

    always_comb begin   :   read_pointer_logic

    end :   read_pointer_logic

    always_comb begin   :   read_pointer_register

    end :   read_pointer_register

    always_comb begin   :   empty_flag_logic
        
    end : empty_flag_logic
    
    always_comb begin   :   full_flag_logic
        
    end :   full_flag_logic
    

endmodule