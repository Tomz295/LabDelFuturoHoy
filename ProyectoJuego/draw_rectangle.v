`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:59:27 07/23/2018 
// Design Name: 
// Module Name:    draw_rectangle 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module draw_rectangle(
    input [9:0] x0,
    input [9:0] x1,
    input [8:0] y0,
    input [8:0] y1,
    input [9:0] CounterX,
    input [8:0] CounterY,
    output drawBool
    );


assign drawBool = (CounterX >= x0) && (CounterX <= x1) && (CounterY >= y0) && (CounterY <= y1);

endmodule
