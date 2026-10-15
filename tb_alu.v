`timescale 1ns / 1ps
//
// CONNECTIONS
//   Calls     : alu.v (module alu)
//   Called by : nobody - this is a testbench (top of simulation)
// =====================================================================
// FILE: tb_alu.v
// MODULE-LEVEL TEST 1: the ALU on its own (no clock needed).
// Part A: directed tests of every ALU operation in the project plan,
//         plus the Zero flag and the Carry / no-borrow convention.
// Part B: exhaustive sweep - every operation is compared with a
//         behavioural model for ALL 256 combinations of a and b.
// =====================================================================
module tb_alu;
    reg  [3:0] a, b;
    reg  [2:0] alu_ctrl;
    wire [3:0] result;
    wire       carry, zero;

    integer errors = 0;
    integer tests  = 0;

    // CALLS: module alu from file alu.v
    alu DUT (.a(a), .b(b), .alu_ctrl(alu_ctrl),
             .result(result), .carry(carry), .zero(zero));

    // apply one test and compare with the expected values
    task test;
        input [8*12:1] name;
        input [3:0] in_a, in_b;
        input [2:0] op;
        input [3:0] exp_result;
        input       exp_carry;
        input       exp_zero;
        begin
            a = in_a; b = in_b; alu_ctrl = op;
            #10;
            tests = tests + 1;
            if (result === exp_result && carry === exp_carry && zero === exp_zero)
                $display("PASS %0s a=%b b=%b -> result=%b carry=%b zero=%b",
                         name, a, b, result, carry, zero);
            else begin
                $display("FAIL %0s a=%b b=%b -> result=%b carry=%b zero=%b",
                         name, a, b, result, carry, zero);
                $display("     expected result=%b carry=%b zero=%b",
                         exp_result, exp_carry, exp_zero);
                errors = errors + 1;
            end
        end
    endtask

    // sweep one operation over all 16 x 16 operand pairs
    task sweep;
        input [8*8:1] name;
        input [2:0]   op;
        integer x, y, bad;
        reg [4:0] t;
        reg [3:0] exp_r;
        reg       exp_c;
        begin
            bad = 0;
            for (x = 0; x < 16; x = x + 1)
                for (y = 0; y < 16; y = y + 1) begin
                    a = x; b = y; alu_ctrl = op;
                    #1;
                    exp_c = 1'b0;
                    case (op)
                        3'd0: begin t = x + y; exp_r = t[3:0]; exp_c = t[4]; end
                        3'd1: begin exp_r = x - y; exp_c = (x >= y); end
                        3'd2: exp_r = a & b;
                        3'd3: exp_r = a | b;
                        3'd4: exp_r = a ^ b;
                        3'd5: exp_r = ~a;
                        default: exp_r = b;
                    endcase
                    if (result !== exp_r || carry !== exp_c ||
                        zero !== (exp_r == 4'b0000))
                        bad = bad + 1;
                end
            tests = tests + 1;
            if (bad == 0)
                $display("PASS sweep %0s: all 256 operand pairs correct", name);
            else begin
                $display("FAIL sweep %0s: %0d of 256 pairs wrong", name, bad);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
    end

    initial begin
        $display("\n===== tb_alu: ALU module test =====");
        $display("--- Part A: directed tests ---");
        //    name           a        b       ctrl   result    C  Z
        test("ADD 5+3     ", 4'b0101, 4'b0011, 3'd0, 4'b1000, 0, 0);
        test("ADD 15+1    ", 4'b1111, 4'b0001, 3'd0, 4'b0000, 1, 1);
        test("SUB 5-3     ", 4'b0101, 4'b0011, 3'd1, 4'b0010, 1, 0);
        test("SUB 3-5     ", 4'b0011, 4'b0101, 3'd1, 4'b1110, 0, 0);
        test("SUB 7-7     ", 4'b0111, 4'b0111, 3'd1, 4'b0000, 1, 1);
        test("AND         ", 4'b1100, 4'b1010, 3'd2, 4'b1000, 0, 0);
        test("OR          ", 4'b1100, 4'b1010, 3'd3, 4'b1110, 0, 0);
        test("XOR         ", 4'b1100, 4'b1010, 3'd4, 4'b0110, 0, 0);
        test("XOR to zero ", 4'b0110, 4'b0110, 3'd4, 4'b0000, 0, 1);
        test("NOT 0101    ", 4'b0101, 4'b0000, 3'd5, 4'b1010, 0, 0);
        test("PASS b      ", 4'b0000, 4'b1001, 3'd6, 4'b1001, 0, 0);

        $display("--- Part B: exhaustive sweep ---");
        sweep("ADD", 3'd0);
        sweep("SUB", 3'd1);
        sweep("AND", 3'd2);
        sweep("OR",  3'd3);
        sweep("XOR", 3'd4);
        sweep("NOT", 3'd5);
        sweep("PASS", 3'd6);

        if (errors == 0)
            $display("tb_alu PASSED: %0d of %0d tests OK\n", tests, tests);
        else
            $display("tb_alu FAILED: %0d of %0d tests failed\n", errors, tests);
        $finish;
    end
endmodule
