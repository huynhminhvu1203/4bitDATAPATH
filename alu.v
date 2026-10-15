`timescale 1ns / 1ps
// =====================================================================
// FILE: alu.v
// The ALU (Arithmetic Logic Unit) does all the calculations.
//
// Interface (as in the project plan):
//   a[3:0], b[3:0], alu_ctrl, result[3:0], carry, zero
//
// This file contains 4 small modules:
//   1. adder_subtractor : ONE shared adder for ADD and SUB (B is XORed
//                         with do_sub and do_sub is the carry-in)
//   2. logic_unit       : does AND, OR, XOR, NOT and PASS (copy b)
//   3. zero_detector    : checks if the result is 0000
//   4. alu              : the main ALU, it joins the 3 parts above
//
// ALU control codes (alu_ctrl):
//   0 = ADD  1 = SUB  2 = AND  3 = OR
//   4 = XOR  5 = NOT  6 = PASS (result = b; used by LDI, MOV,
//                               LOAD and STORE)
//
// CARRY CONVENTION (same in ALU, flag register and testbenches):
//   ADD : carry = 1 when the sum is bigger than 15 (carry-out)
//   SUB : carry = 1 when a >= b, i.e. NO BORROW
//         carry = 0 when a <  b, i.e. a borrow happened
//   (A - B = A + ~B + 1, so the adder carry-out IS the no-borrow flag)
//
// CONNECTIONS
//   Calls     : only modules inside this same file:
//               adder_subtractor, logic_unit, zero_detector
//   Called by : cpu_top.v      - instance ALU
//               tb_alu.v       - instance DUT
// =====================================================================

// ---------------------------------------------------------------------
// MODULE 1: adder_subtractor
// ---------------------------------------------------------------------
module adder_subtractor (
    input  [3:0] a,
    input  [3:0] b,
    input        do_sub,      // 0 = add, 1 = subtract
    output [3:0] result,
    output       carry
);
    wire [3:0] bx       = b ^ {4{do_sub}};                       // flip B when subtracting
    wire [4:0] full_sum = {1'b0, a} + {1'b0, bx} + {4'b0000, do_sub}; // bit 4 = carry
    assign result = full_sum[3:0];   // lower 4 bits are the answer
    assign carry  = full_sum[4];     // ADD: carry-out, SUB: no-borrow
endmodule

// ---------------------------------------------------------------------
// MODULE 2: logic_unit
// ---------------------------------------------------------------------
module logic_unit (
    input      [3:0] a,
    input      [3:0] b,
    input      [2:0] alu_ctrl,
    output reg [3:0] result
);
    always @(*) begin
        case (alu_ctrl)
            3'd2:    result = a & b;     // AND
            3'd3:    result = a | b;     // OR
            3'd4:    result = a ^ b;     // XOR
            3'd5:    result = ~a;        // NOT (only uses a)
            3'd6:    result = b;         // PASS: copy b
            default: result = 4'b0000;
        endcase
    end
endmodule

// ---------------------------------------------------------------------
// MODULE 3: zero_detector
// ---------------------------------------------------------------------
module zero_detector (
    input  [3:0] value,
    output       zero
);
    assign zero = (value == 4'b0000) ? 1'b1 : 1'b0;
endmodule

// ---------------------------------------------------------------------
// MODULE 4: alu (main ALU)
// ---------------------------------------------------------------------
module alu (
    input  [3:0] a,            // operand A (register Rd)
    input  [3:0] b,            // operand B (register Rs or immediate)
    input  [2:0] alu_ctrl,     // which operation to do
    output reg [3:0] result,   // final answer
    output reg       carry,    // carry / no-borrow
    output           zero      // 1 when result = 0000
);
    wire [3:0] arith_result;   // answer from adder_subtractor
    wire       arith_carry;    // carry from adder_subtractor
    wire [3:0] logic_result;   // answer from logic_unit
    wire       do_sub = (alu_ctrl == 3'd1);   // alu_ctrl 1 means SUB

    // CALLS: module adder_subtractor (MODULE 1 in this same file, alu.v)
    adder_subtractor ADDSUB (
        .a(a), .b(b), .do_sub(do_sub),
        .result(arith_result), .carry(arith_carry)
    );

    // CALLS: module logic_unit (MODULE 2 in this same file, alu.v)
    logic_unit LOGIC (
        .a(a), .b(b), .alu_ctrl(alu_ctrl),
        .result(logic_result)
    );

    // choose the final answer
    always @(*) begin
        if (alu_ctrl == 3'd0 || alu_ctrl == 3'd1) begin
            result = arith_result;     // ADD or SUB
            carry  = arith_carry;
        end
        else begin
            result = logic_result;     // AND, OR, XOR, NOT, PASS
            carry  = 1'b0;             // logic ops have no carry
        end
    end

    // CALLS: module zero_detector (MODULE 3 in this same file, alu.v)
    zero_detector ZERO (
        .value(result),
        .zero(zero)
    );
endmodule
