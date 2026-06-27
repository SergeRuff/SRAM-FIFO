//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module one_bit_wide_circular_buffer
# (
    parameter depth = 8
)
(
    input  clk,
    input  rst,

    input  in_data,
    output out_data
);

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [depth - 1:0] data;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            data <= '0;
        else
            data [ptr] <= in_data;

    assign out_data = data [ptr];

endmodule

//----------------------------------------------------------------------------

module circular_buffer
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);

    localparam pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    logic [pointer_width - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            ptr <= '0;
        else
            ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;

    //------------------------------------------------------------------------

    logic [width - 1:0] data [0: depth - 1];

    always_ff @ (posedge clk)
        data [ptr] <= in_data;

    assign out_data  = data [ptr];

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module circular_buffer_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                      clk,
    input                      rst,

    input                      in_valid,
    input        [width - 1:0] in_data,

    output logic               out_valid,
    output logic [width - 1:0] out_data
);

    // Task:
    // Implement a variant of a circular buffer module
    // with support for valid interface.

    localparam                       pointer_width = $clog2 (depth);
    localparam [pointer_width - 1:0] max_ptr       = pointer_width' (depth - 1);

    logic      [pointer_width - 1:0] ptr;
    logic      [        width - 1:0] data       [0: depth - 1];
    logic      [        depth - 1:0] valid_reg;

    always_ff @ (posedge clk or posedge rst)    begin   :   pointer_counter
        if (rst) ptr <= '0;
        else     ptr <= ( ptr == max_ptr ) ? '0 : ptr + 1'b1;
    end :   pointer_counter

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)   begin   :   valid_register
        if (rst)    valid_reg      <= '0;
        else        valid_reg[ptr] <= in_valid;
    end :   valid_register

    always_ff @(posedge clk) begin  :   data_register
        data[ptr]   <= in_data;
    end :   data_register

    always_comb begin   : output_MUX
        out_data    = data[ptr];
        out_valid   = valid_reg[ptr];
    end : output_MUX

endmodule
