`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tomás L.
// 
// Create Date:    14:43:36 08/09/2018 
// Design Name: 
// Module Name:    MobsModule 
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
module MobsModule(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, stageCode, CounterX, CounterY, StageAny, mobNumber, DrawR, DrawG, DrawB, drawMob, SwordBox);
input clk;
input clk_maxspeed;
input clk_normalspeed;
input [31:0] stage_posX;
input [31:0] stage_posY;
input [31:0] CounterX;
input [31:0] CounterY;
input StageAny;
input [10:0] stageCode;
input [10:0] mobNumber;
input SwordBox;
output reg DrawR;
output reg DrawG;
output reg DrawB;
output wire drawMob;

reg sprite_number = 0;
integer clock_aux0 = 0;
always@(posedge clk_normalspeed)
begin
	if(clock_aux0 >= 100)
	begin
		sprite_number = ~sprite_number;
		clock_aux0 = 0;
	end else begin
		clock_aux0 = clock_aux0 + 1;
	end
end




parameter AWdat = 6; //-- Bits de las direcciones (Adress width)
parameter DWdat = 11; //-- Bits de los datos (Data witdh)
wire [AWdat-1: 0] addr;  //-- Bus de direcciones
wire [DWdat-1: 0] data;  //-- Bus de datos
genrom 
  #( .ROMFILE("MobData.list"),
	  .AW(AWdat),
     .DW(DWdat))
  ROM ( .clk(clk),
        .addr(addr),
        .data(data));

assign addr = stageCode * 3'd4 + mobNumber;
wire [31:0] mob_spawnposX_data = data[4:0] * 32; //X -> 5 primeros bits
wire [31:0] mob_spawnposY_data = data[9:5] * 32; //Y -> 5 segundos bits
wire [31:0] mob_spawnposX = mob_spawnposX_data - stage_posX;
wire [31:0] mob_spawnposY = mob_spawnposY_data - stage_posY;
wire mob_spawn_onScreen = (mob_spawnposX >= 0) && (mob_spawnposX <= 608) && (mob_spawnposY >= 32) && (mob_spawnposY <= 480);
draw_rectangle square32by32(mob_spawnposX,mob_spawnposX+32,mob_spawnposY-32,mob_spawnposY,CounterX,CounterY,drawSpawn);

integer mob_posX = 1060;
wire [31:0] mob_realposX = mob_posX - stage_posX;
integer mob_posY = 1060;
wire [31:0] mob_realposY = mob_posY - stage_posY;
reg mob_lookingleft = 1;
wire mob_type = data[10];
wire mob_onScreen = (mob_realposX >= 32'd0) && (mob_realposX <= 640) && (mob_realposY >= 0) && (mob_realposY <= 512);
reg mob_alive = 1;
reg [10:0] current_stage = 11'd0;
always@(posedge clk)
begin
	if(drawMob && SwordBox) begin
		mob_alive = 0;
	end else if(stageCode != current_stage)begin
		mob_alive = 1;
		current_stage = stageCode;
	end
end

//Collisions
//StageBuilderSpriteless Floorcollisions1(clk, stage_posX, stage_posY, stageCode, mob_realposX + 1, mob_realposY + 1, floor_check0); //replace Counters with mob positions to check
//wire floor_check0 = (CounterX === (mob_realposX + 1)) && (CounterY === mob_realposY) && StageAny;

//StageBuilderSpriteless Floorcollisions2(clk, stage_posX, stage_posY, stageCode, mob_realposX + 31, mob_realposY + 1, floor_check1);
//wire floor_check1 = (CounterX === (mob_realposX + 31)) && (CounterY === mob_realposY) && StageAny;


reg floor_check0 = 0;
reg floor_check1 = 0;
reg left_check = 0;
reg right_check = 0;
reg top_check = 0;
always@(posedge clk)
begin
	if((CounterX == (mob_realposX + 1)) && (CounterY == mob_realposY))
	begin
		floor_check0 = StageAny;
	end
	if((CounterX == (mob_realposX + 31)) && (CounterY == mob_realposY))
	begin
		floor_check1 = StageAny;
	end
	if((CounterX == mob_realposX) && (CounterY == (mob_realposY - 16)))
	begin
		left_check = StageAny;
	end
	if((CounterX == (mob_realposX + 32)) && (CounterY == (mob_realposY - 16)))
	begin
		right_check = StageAny;
	end
	if((CounterX == (mob_realposX + 16)) && (CounterY == (mob_realposY - 32)))
	begin
		top_check = StageAny;
	end
end

wire floor_check = floor_check0 || floor_check1;
//StageBuilderSpriteless Leftcollisions(clk, stage_posX, stage_posY, stageCode, mob_realposX, mob_realposY - 16, left_check);
//wire left_check = (CounterX == mob_realposX) && (CounterY == mob_realposY - 16) && StageAny;

//StageBuilderSpriteless Rightcollisions(clk, stage_posX, stage_posY, stageCode, mob_realposX + 32, mob_realposY - 16, right_check);
//StageBuilderSpriteless Floorcollisions(clk, stage_posX, stage_posY, stageCode, mob_realposX + 16, mob_realposY - 32, top_check);

//Sprites
parameter AW = 7; //-- Bits de las direcciones (Adress width)
parameter DW = 32; //-- Bits de los datos (Data witdh)
wire [AW-1: 0] sprite_addr;  //-- Bus de direcciones
wire [DW-1: 0] dataR;  //-- Bus de datos
genrom 
  #( .ROMFILE("MobSpritesR.list"), .AW(AW), .DW(DW))
  ROMR ( .clk(clk), .addr(sprite_addr), .data(dataR));
  
wire [DW-1: 0] dataG;
genrom 
  #( .ROMFILE("MobSpritesG.list"), .AW(AW), .DW(DW))
  ROMG ( .clk(clk), .addr(sprite_addr), .data(dataG));
  
wire [DW-1: 0] dataB;
genrom 
  #( .ROMFILE("MobSpritesB.list"), .AW(AW), .DW(DW))
  ROMB ( .clk(clk), .addr(sprite_addr), .data(dataB));
  
//DRAW
wire [4:0] CounterYSprite = (CounterY + stage_posY - mob_posY);
wire [4:0] CounterXSprite = (CounterX + stage_posX - mob_posX);
assign drawMob = (CounterX >= mob_realposX) && (CounterX < mob_realposX + 32) && (CounterY <= mob_realposY) && (CounterY >= mob_realposY - 32) && mob_alive;
assign sprite_addr = (CounterYSprite) + (64 * mob_type) + (32 * sprite_number);

reg [31:0] CounterXFixed;
always@(posedge clk)
begin
	if(mob_lookingleft)
		CounterXFixed = 32'd32 - CounterXSprite;
	else
		CounterXFixed = CounterXSprite;
end

always@(posedge clk)
begin
	DrawR = (dataR[CounterXFixed] && drawMob);
	DrawG = dataG[CounterXFixed] && drawMob;
	DrawB = dataB[CounterXFixed] && drawMob;
end
  
/*
MOB TYPES BASED ON mob_type VALUES
0 -> slime
1 -> spider

*/
integer aux_clock1 = 0;
integer movement_clock1 = 0;
integer jump_clock1 = 0;
reg mob_jump = 0;

wire slime = ~mob_type;
wire spider = mob_type;

reg [4:0] currentStageCode = 5'd0;
wire sameStage = (stageCode == currentStageCode);
always@(posedge clk_maxspeed)
begin
	if(mob_onScreen && sameStage) begin
			if(mob_alive)begin
				if( (((aux_clock1 >= 8000) && slime) || ((aux_clock1 >= 1500) && spider)) && floor_check)//Jump Frecuency
				begin
					mob_jump = 1;
					aux_clock1 = 0;
				end else begin
					aux_clock1 = aux_clock1 + 1;
				end
				if(((movement_clock1 >= 20) && slime) || ((movement_clock1 >= 6) && spider))//Movement Speed
				begin
					movement_clock1 = 0;
					if(mob_jump)//	JUMP
					begin
						if( ( ((jump_clock1 >= 55) && slime) || ((jump_clock1 >= 19) && spider) ) || top_check) //Jump Duration
						begin
							mob_jump = 0;
							jump_clock1 = 0;
						end else begin
							jump_clock1 = jump_clock1 + 1;
							mob_posY = mob_posY - 1;
						end
					end else if(!floor_check)
					begin
						mob_posY = mob_posY + 1;
					end
					if(!floor_check)//MOVE ONLY WHILE JUMPING
					begin
						if(mob_realposX > 304 && !left_check)
						begin
							mob_lookingleft = 1;
							mob_posX = mob_posX - 1;
						end
						else if(mob_realposX < 304 && !right_check)
						begin
							mob_lookingleft = 0;
							mob_posX = mob_posX + 1;
						end
					end
				end else
				movement_clock1 = movement_clock1 + 1;
			end
	end else if(!mob_spawn_onScreen || !sameStage)
	begin
	currentStageCode = stageCode;
	mob_posX = mob_spawnposX_data;
	mob_posY = mob_spawnposY_data;
	end
end

endmodule
