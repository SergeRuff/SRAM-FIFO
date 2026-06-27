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

endmodule