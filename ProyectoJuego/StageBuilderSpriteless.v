`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:18:49 08/08/2018 
// Design Name: 
// Module Name:    StageBuilderSpriteless 
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
module StageBuilderSpriteless(clk, stage_posX, stage_posY, stageCode, CounterX, CounterY, DrawAny);
input clk;
input [31:0] stage_posX;
input [31:0] stage_posY;
input [31:0] CounterX;
input [31:0] CounterY;
input [10:0] stageCode;
output reg DrawAny;


parameter AW = 9; //-- Bits de las direcciones (Adress width)
parameter DW = 32; //-- Bits de los datos (Data witdh)
wire [AW-1: 0] addr;  //-- Bus de direcciones
wire [DW-1: 0] data;  //-- Bus de datos
genrom 
  #( .ROMFILE("StageData.list"),
	  .AW(AW),
     .DW(DW))
  ROM ( .clk(clk),
        .addr(addr),
        .data(data));

wire [31:0] data_index = 32'd32 * stageCode;
wire [31:0] CounterY32Block = (CounterY + stage_posY);
wire [31:0] CounterX32Block = (CounterX + stage_posX);

assign addr = (CounterY32Block[9:5] + data_index);
reg [31:0] aux_data;
always@(posedge clk)
begin
if(CounterX32Block[21:10] < 5'd0 || CounterX32Block[21:10] > 5'd32 || CounterY32Block[21:10] < 5'd0 || CounterY32Block[21:10] > 5'd32)
	DrawAny <= 1;
	else
	begin
	DrawAny <= data[5'd31 - CounterX32Block[9:5]];
	end
end



endmodule
