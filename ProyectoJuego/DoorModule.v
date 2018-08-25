`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tomás L.
// 
// Create Date:    14:31:59 07/27/2018 
// Design Name: 
// Module Name:    DoorModule 
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
module DoorModule(clk, stageCode, doorNumber, stage_posX, stage_posY, char_posY, CounterX, CounterY, drawR, drawG, drawB, drawAny, newStageCode, resetPulse, real_new_posX);
input clk;
input [10:0] stageCode;
input doorNumber;
input [31:0] stage_posX;
input [31:0] stage_posY;
input [31:0] char_posY;
input [31:0] CounterX;
input [31:0] CounterY;

output reg drawR = 1;
output reg drawG = 0;
output reg drawB;
output drawAny;
output wire [4:0] newStageCode;
output resetPulse;
output wire [31:0] real_new_posX;

/*
reg [31:0] door_posX;
reg [31:0] door_posY;
reg [9:0] door_heigh;
integer new_posX = 0;
assign real_new_posX = new_posX * 32;
reg [31:0] stageData [0:15];
*/

parameter AWdat = 5; //-- Bits de las direcciones (Adress width)
parameter DWdat = 25; //-- Bits de los datos (Data witdh)
wire [AWdat-1: 0] addr;  //-- Bus de direcciones
wire [DWdat-1: 0] data;  //-- Bus de datos
genrom 
  #( .ROMFILE("DoorsData.list"),
	  .AW(AWdat),
     .DW(DWdat))
  ROM ( .clk(clk),
        .addr(addr),
        .data(data));

assign addr = (2 * stageCode) + doorNumber;
//assign addr = doorNumber
wire [31:0] door_posX;
wire [31:0] door_posY;
assign door_posX[9:5] = data[4:0]; 	// X -> PRIMEROS 5
assign door_posY = data[9:5];			// Y -> SEGUNDOS 5
wire [4:0] door_heigh = data[14:10];// HEIGH -> TERCEROS 5
assign newStageCode = data [19:15];	// NEXTSTAGE -> CUARTOS 5
wire [4:0] new_posX = data[24:20];	//nueva posX -> quintos 5
assign real_new_posX = new_posX * 32;


/*
always@(posedge clk)
begin
case (stageCode)
	(5'd0): begin
		case (doorNumber)
		5'd0: begin
			door_posX <= 32'd0;
			door_posY <= 32'd14;
			door_heigh <= 10'd2;
			newStageCode <= 5'd0;
			new_posX <= 32'd30;
		end
		5'd1: begin
			door_posX <= 32'd31;
			door_posY <= 32'd8;
			door_heigh <= 10'd4;
			newStageCode <= 5'd1;
			new_posX <= 32'd1;
		end
		endcase
	end
	(5'd1):begin
		case (doorNumber)
		5'd0: begin
			door_posX <= 32'd0;
			door_posY <= 32'd8;
			door_heigh <= 10'd4;
			newStageCode <= 5'd0;
			new_posX <= 32'd30;
		end
		5'd1: begin
			door_posX <= -32'd64;
			door_posY <= 32'd0;
			door_heigh <= 10'd0;
			newStageCode <= 5'd0;
			new_posX <= 32'd0;
		end
		endcase
	end
endcase
end
*/
wire [31:0] CounterY32Block = (CounterY + stage_posY);
wire [31:0] CounterX32Block = (CounterX + stage_posX) - 2'd2;

/*
always@(posedge clk)
begin
if((5'd31 - CounterX32Block[9:5]) == door_posX)
	drawAny <= 1;
end
*/

wire drawAny = (CounterX32Block[31:5] == door_posX[9:5]) && (CounterY32Block[9:5] < door_posY) && (CounterY32Block[9:5] > (door_posY - door_heigh - 10'd1));

wire resetPulse = ((door_posX - stage_posX) <= 32'd316) && ((door_posX + 32'd32 - stage_posX) >= 32'd324) &&  ((char_posY - 32'd10) <= (door_posY * 32'd32 - stage_posY)) && ((char_posY - 53) >= ((door_posY - door_heigh)  * 32'd32  - stage_posY));


endmodule
