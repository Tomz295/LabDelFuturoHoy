`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tomás L.
// 
// Create Date:    15:07:06 07/24/2018 
// Design Name: 
// Module Name:    StageBuilder 
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
module StageBuilder(clk, stage_posX, stage_posY, stageCode, CounterX, CounterY, DrawRed, DrawBlue, DrawGreen, DrawAny);
input clk;
input [31:0] stage_posX;
input [31:0] stage_posY;
input [31:0] CounterX;
input [31:0] CounterY;
input [10:0] stageCode;
output reg DrawRed;
output reg DrawBlue;
output reg DrawGreen;
output DrawAny;


StageBuilderSpriteless stagebuild(clk, stage_posX, stage_posY, stageCode, CounterX, CounterY, DrawAny);


parameter AW = 7; //-- Bits de las direcciones (Adress width)
parameter DW = 32; //-- Bits de los datos (Data witdh)
wire [AW-1: 0] addr;  //-- Bus de direcciones
wire [DW-1: 0] dataR;  //-- Bus de datos
genrom 
  #( .ROMFILE("BlockSpritesR.list"), .AW(AW), .DW(DW))
  ROMR ( .clk(clk), .addr(addr), .data(dataR));
  
wire [DW-1: 0] dataG;
genrom 
  #( .ROMFILE("BlockSpritesG.list"), .AW(AW), .DW(DW))
  ROMG ( .clk(clk), .addr(addr), .data(dataG));
  
wire [DW-1: 0] dataB;
genrom 
  #( .ROMFILE("BlockSpritesB.list"), .AW(AW), .DW(DW))
  ROMB ( .clk(clk), .addr(addr), .data(dataB));

wire [1:0] BlockNumber = stageCode[1:0];
/*reg [1:0] BlockNumber;
always@(posedge clk)
begin
case(stageCode)
	default: BlockNumber = 0;
	11'd0: BlockNumber = 0;
	11'd1: BlockNumber = 1;
	11'd2: BlockNumber = 2;
	11'd3: BlockNumber = 3;
endcase
end*/

wire [4:0] CounterYBlockSprite = (CounterY + stage_posY);
wire [4:0] CounterXBlockSprite = (CounterX + stage_posX) - 1'b1;
assign addr = (CounterYBlockSprite) + (32 * BlockNumber);


always@(posedge clk)
begin
	DrawRed = dataR[CounterXBlockSprite] && DrawAny;
	DrawBlue = dataB[CounterXBlockSprite] && DrawAny;
	DrawGreen = dataG[CounterXBlockSprite] && DrawAny;
end

endmodule
