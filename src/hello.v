module hello (
    input wire a,
    output wire b
);

    assign b = ~a;
    
endmodule