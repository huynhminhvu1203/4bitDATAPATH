`timescale 1ns / 1ps
// =====================================================================
// FILE: mux.v
// 2-input multiplexer (4 bits wide by default). A mux picks ONE input.
//   sel = 0 -> y = d0
//   sel = 1 -> y = d1
//
// The CPU uses this module three times:
//   1. Operand MUX    : ALU input B = register Rs or immediate
//   2. Write-back MUX : register data = ALU result or memory data
//   3. PC MUX         : next PC = PC + 1 or jump address
//
// CONNECTIONS
//   Calls     : nothing (no other modules)
//   Called by : cpu_top.v - 3 times: instances PC_MUX, OPERAND_MUX, WB_MUX
// =====================================================================
module mux2 #(
    parameter WIDTH = 4              // data width (4 bits in this CPU)
)(
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              sel,
    output [WIDTH-1:0] y
);
    assign y = (sel == 1'b1) ? d1 : d0;
endmodule
