`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tomás L.
// 
// Create Date:    13:04:02 07/23/2018 
// Design Name: 
// Module Name:    MainGame 
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
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module MainGame(clk, vga_hsync, vga_vsync, vga_red, vga_green, vga_blue, clk, PS2_CLK,	PS2_DATA);//, SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO,
	//SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B);
input clk;
output vga_hsync, vga_vsync, vga_red, vga_green, vga_blue;//, SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO, SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B;
input PS2_CLK, PS2_DATA;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;
/*
wire 	SPI_MISO;
wire	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
wire 	SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B;
*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////				 
//CLOCKS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg clk_25;
always@(posedge clk)
clk_25 <= ~clk_25;

reg clk_maxspeed;
integer auxclock1 = 0;
always@(posedge clk_25)
begin
	if(auxclock1 >= 4000)
	begin
		auxclock1 <= 0;
		clk_maxspeed <= ~clk_maxspeed;
	end
	else
	auxclock1 <= auxclock1 + 1;
end

reg clk_normalspeed;
integer auxclocknormal = 0;
always@(posedge clk_maxspeed)
begin
	if(auxclocknormal >= 4)
	begin
		auxclocknormal <= 0;
		clk_normalspeed <= ~clk_normalspeed;
	end
	else
	auxclocknormal <= auxclocknormal + 1;
end

reg clk_chargravity;
integer auxclockjump0 = 0;
always@(posedge clk_maxspeed)
begin
	if(auxclockjump0 >= 40)
	begin
		auxclockjump0 <= 0;
		clk_chargravity <= ~clk_chargravity;
	end
	else
	auxclockjump0 <= auxclockjump0 + 1;
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//KEYS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire moveup;
Keyboard UpKeyPress( clk, PS2_CLK, PS2_DATA, 8'h75,moveup);

wire movedown;
Keyboard downKeyPress( clk, PS2_CLK, PS2_DATA, 8'h72,movedown);

wire moveright;
Keyboard rightKeyPress( clk, PS2_CLK, PS2_DATA, 8'h74,moveright);

wire moveleft;
Keyboard leftKeyPress( clk, PS2_CLK, PS2_DATA, 8'h6B,moveleft);

wire Pkey;
Keyboard PKeyPress( clk, PS2_CLK, PS2_DATA, 8'h4D,Pkey);

wire Spacebar;
Keyboard SpacePress( clk, PS2_CLK, PS2_DATA, 8'h29,Spacebar);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//MODULO DE PANTALLA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
hvsync_generator syncgen(.clk(clk_25), .vga_h_sync(vga_hsync), .vga_v_sync(vga_vsync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
									 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//VARIABLES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////	STAGE			////////
reg [4:0] StageCode = 5'b0;
wire stageRed;
wire stageGreen;
wire stageBlue;

////////	CHARACTER	////////
wire char_hitbox;
wire gotHit;
integer char_posY = 160;
integer char_YspeedModule = 0;
reg char_YspeedDirection = 0;

//respawn points
integer res_char_posY = 160;
integer res_stage_posX = 0;
integer res_stage_posY = 0;

//jumpClock
reg clk_charjump;

//direction facing related stuff
reg looking_left = 0;

//character screen limits
wire char_bottomlimit = (char_posY > 450);
wire char_toplimit = (char_posY < 94);

//touching ground check
wire char_grounded_check0;
wire char_grounded_check1;
wire char_grounded_check = char_grounded_check0 || char_grounded_check1;

//touching ceiling check
wire char_ceiling_check0;
wire char_ceiling_check1;
wire char_touch_ceiling = char_ceiling_check0 || char_ceiling_check1;

//left collision check check
wire char_leftcoll_check0;
wire char_leftcoll_check1;
wire char_leftcoll_check2;
wire char_leftcollision = char_leftcoll_check0 || char_leftcoll_check1 || char_leftcoll_check2;

//right collision check check
wire char_rightcoll_check0;
wire char_rightcoll_check1;
wire char_rightcoll_check2;
wire char_rightcollision = char_rightcoll_check0 || char_rightcoll_check1 || char_rightcoll_check2;

wire char_grounded = char_grounded_check || (char_leftcollision && moveleft) || (char_rightcollision && moveright);

////////	STAGEDOORS	////////
wire resetPulse1;
wire [31:0] new_posX1;
wire [4:0] newStageCode1;

wire resetPulse2;
wire [31:0] new_posX2;
wire [4:0] newStageCode2;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//STAGE DATA
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
always@(posedge resetPulseAny)
begin
	begin
		res_char_posY = char_posY;
		res_stage_posY = stage_posY;
		res_stage_posX = stage_posX;
	end
end
*/
wire resetPulseAny;

integer stage_posX = 0;
integer stage_posY = 0;

reg res_aux01 = 0;

wire [6:0] invul_time = 7'd120; //max 127
reg [6:0] res_invulnerability = 6'd40;
always@(posedge clk_normalspeed)
begin
	if(res_aux01)
	begin
		res_invulnerability = 0;
	end
	if(res_invulnerability <= invul_time)
	begin
		res_invulnerability = res_invulnerability + 1;
	end
end

always@(posedge clk)
begin
	if(gotHit && res_invulnerability >= invul_time)
		res_aux01 = 1;
	else if(stage_posY == res_stage_posY && char_posY == res_char_posY && stage_posX == res_stage_posX)
		res_aux01 = 0;
end

always@(posedge clk_normalspeed)
begin
	if(res_aux01)
		stage_posX = res_stage_posX;
	else if(resetPulseAny) begin
		res_char_posY = char_posY;
		res_stage_posY = stage_posY;
		if(resetPulse1)
		begin
			StageCode = newStageCode1;
			res_stage_posX = new_posX1 - 32'd305;
			stage_posX = res_stage_posX;
		end else if(resetPulse2)
		begin
			StageCode = newStageCode2;
			res_stage_posX = new_posX2 - 32'd305;
			stage_posX = res_stage_posX;
		end
	end else begin
		if(moveleft && !char_leftcollision)
		begin
		stage_posX = stage_posX - 1;
		looking_left <= 1;
		end
		else if(moveright && !char_rightcollision)
		begin
		stage_posX = stage_posX + 1;
		looking_left <= 0;
		end
	end
end

//integer stage_posY = 0;
always@(posedge clk_charjump)
begin
	if(res_aux01)
		stage_posY = res_stage_posY;
	else if(char_bottomlimit)
	begin
		stage_posY = stage_posY + 1;
	end else if(char_toplimit && stage_posY > 1)// && stage_posY < 32'hFFFFF)
		stage_posY = stage_posY - 1;
end


StageBuilder currentStage(clk_25, stage_posX, stage_posY, StageCode, CounterX, CounterY, stageRed, stageBlue, stageGreen, StageAny);
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DOORS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire drawAnyDoor01;
DoorModule door01(clk_25, StageCode, 1'd0, stage_posX, stage_posY, char_posY, CounterX, CounterY, drawR1, drawG1, drawB1, drawAnyDoor01, newStageCode1, resetPulse1, new_posX1);

DoorModule door02(clk_25, StageCode, 1'd1, stage_posX, stage_posY, char_posY, CounterX, CounterY, drawR2, drawG2, drawB2, drawAnyDoor02, newStageCode2, resetPulse2, new_posX2);

assign resetPulseAny = resetPulse1 || resetPulse2;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//MAIN CHARACTER STUFF
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//integer char_posY = 160;
//integer char_YspeedModule = 0;
//reg char_YspeedDirection = 0;

//TOUCHING GROUND CHECK
StageBuilderSpriteless groundcheck0(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(304), .CounterY(char_posY + 1), .DrawAny(char_grounded_check0));

StageBuilderSpriteless groundcheck1(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(334), .CounterY(char_posY + 1), .DrawAny(char_grounded_check1));

//TOUCH CEILING CHECK
StageBuilderSpriteless ceilingcheck0(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(304), .CounterY(char_posY - 63), .DrawAny(char_ceiling_check0));

StageBuilderSpriteless ceilingcheck1(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(334), .CounterY(char_posY - 63), .DrawAny(char_ceiling_check1));


//LEFT COLLISION CHECK
StageBuilderSpriteless leftcollcheck0(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(302), .CounterY(char_posY), .DrawAny(char_leftcoll_check0));

StageBuilderSpriteless leftcollcheck1(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(302), .CounterY(char_posY - 60), .DrawAny(char_leftcoll_check1));

StageBuilderSpriteless leftcollcheck2(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(302), .CounterY(char_posY - 32), .DrawAny(char_leftcoll_check2));


//RIGHT COLLISION CHECK
StageBuilderSpriteless rightcollcheck0(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(335), .CounterY(char_posY), .DrawAny(char_rightcoll_check0));

StageBuilderSpriteless rightcollcheck1(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(335), .CounterY(char_posY - 60), .DrawAny(char_rightcoll_check1));

StageBuilderSpriteless rightcollcheck2(.clk(clk_25), .stage_posX(stage_posX), .stage_posY(stage_posY), .stageCode(StageCode), .CounterX(335), .CounterY(char_posY - 32), .DrawAny(char_rightcoll_check2));

//assign char_grounded_check0 = (DrawAny && (CounterY == char_posY + 1) && (CounterX >= 304 && CounterX <= 334));



//JUMP
always@(posedge clk_chargravity)
begin
	if(char_YspeedDirection)
	begin
		if(char_YspeedModule > 0 && !char_touch_ceiling)
		begin
			char_YspeedModule <= char_YspeedModule - 1;
		end else begin
			char_YspeedDirection <= 0;
		end
	end else begin
		if(char_grounded)
		begin
			if(moveup && !char_touch_ceiling)
			begin
				char_YspeedDirection <= 1;
				char_YspeedModule <= 20;
			end else if(char_grounded_check)
			char_YspeedModule <= 0;
		end else begin
			if(char_YspeedModule >= 20)
			begin
				char_YspeedModule <= 20;
			end else begin
				char_YspeedModule <= char_YspeedModule + 1;
			end
		end
	end
end



integer auxclockjump1 = 0;
always@(posedge clk_maxspeed)
begin
	if(auxclockjump1 >= 21 - char_YspeedModule)
	begin
		auxclockjump1 <= 0;
		clk_charjump <= ~clk_charjump;
	end
	else
	auxclockjump1 <= auxclockjump1 + 1;
end

always@(posedge clk_charjump)
begin
	if(res_aux01)
		char_posY = res_char_posY;
	else if(char_toplimit)
		char_posY = char_posY + 1;
	else if(char_bottomlimit)
		char_posY = char_posY - 1;
	else if(char_YspeedDirection)
	begin
		char_posY = char_posY - 1;
	end else begin
		if(!(char_grounded_check && !char_touch_ceiling))
		char_posY = char_posY + 1;
	end
end

/*
always@(posedge clk_normalspeed)
begin
	if(moveup)
	begin
		char_posY <= char_posY + 1;
	end else if(movedown) begin
		char_posY <= char_posY - 1;
	end
end
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ENEMIES
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire SwordBox;
MobsModule mob0(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, StageCode, CounterX, CounterY, StageAny, 0, DrawMobR, DrawMobG, DrawMobB, DrawAny1, SwordBox);
MobsModule mob1(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, StageCode, CounterX, CounterY, StageAny, 1, DrawMobR2, DrawMobG2, DrawMobB2, DrawAny2, SwordBox);
MobsModule mob2(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, StageCode, CounterX, CounterY, StageAny, 2, DrawMobR3, DrawMobG3, DrawMobB3, DrawAny3, SwordBox);
MobsModule mob3(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, StageCode, CounterX, CounterY, StageAny, 3, DrawMobR4, DrawMobG4, DrawMobB4, DrawAny4, SwordBox);
//MobsModule mob4(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, StageCode, CounterX, CounterY, StageAny, 4, DrawMobR5, DrawMobG5, DrawMobB5, DrawAny5, SwordBox);
//MobsModule mob5(clk, clk_maxspeed, clk_normalspeed, stage_posX, stage_posY, StageCode, CounterX, CounterY, StageAny, 5, DrawMobR6, DrawMobG6, DrawMobB6, DrawAny6, SwordBox);

wire DrawAnyMobR = DrawMobR || DrawMobR2 || DrawMobR3 || DrawMobR4;// || DrawMobR5 || DrawMobR6;
wire DrawAnyMobG = DrawMobG || DrawMobG2 || DrawMobG3 || DrawMobG4;// || DrawMobG5 || DrawMobG6;
wire DrawAnyMobB = DrawMobB || DrawMobB2 || DrawMobB3 || DrawMobB4;// || DrawMobB5 || DrawMobB6;
wire DrawAnyMob = DrawAny1 || DrawAny2 || DrawAny3 || DrawAny4;// || DrawAny5 || DrawAny6;
assign gotHit = DrawAnyMob && char_hitbox;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//WE GOT DEM SWORDS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//reg looking_left;
//wire Spacebar;
reg sword_swing = 0;
reg [10:0] sword_swinging_clock = 100;
wire sword_swinging = (sword_swinging_clock < 30);

always@(posedge clk_normalspeed)
begin
	if(sword_swing)
	begin
		if(sword_swinging_clock > 80)
			begin
				sword_swing = 0;
			end else begin
				sword_swinging_clock = sword_swinging_clock + 1;
			end
	end else if(Spacebar) begin
		sword_swing = 1;
		sword_swinging_clock = 0;
	end
end



wire sword_rectangle_left = (CounterX >= 272) && (CounterX <= 304) && (CounterY >= char_posY-48) && (CounterY <= char_posY-16) && sword_swinging && looking_left;
wire sword_rectangle_right = (CounterX >= 337) && (CounterX <= 369) && (CounterY >= char_posY-48) && (CounterY <= char_posY-16) && sword_swinging && !looking_left;
assign SwordBox = sword_rectangle_left || sword_rectangle_right;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//WE GOT DANK MUSIC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
wire Speaker;
music Music1(clk_25, Speaker);

wire	enable;
wire	done;
wire 	[11:0]	data;
wire 	[3:0]	address;

assign enable = 1;	// enable the DAC module

assign data = Speaker*10;
assign address = 0;	// use DAC A

DAC mod(	clk, enable, done, data, address,
			SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO,
			SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B);

*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//THE REST
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


wire drawAnyDoor = drawAnyDoor01 || drawAnyDoor02;

//wire char_hitbox;
draw_rectangle hitbox32by64(305,336,char_posY-63,char_posY,CounterX,CounterY,char_hitbox);
					
wire R = SwordBox || DrawAnyMobR;

wire G = (char_hitbox) || DrawAnyMobG;

wire B = char_hitbox || DrawAnyMobB;
									 
reg vga_red, vga_green, vga_blue;
always @(posedge clk)
begin
  vga_red <= (R || stageRed || drawAnyDoor) & inDisplayArea;
  
  vga_green <= (G || stageGreen || drawAnyDoor) & inDisplayArea;
  
  vga_blue <= (B || stageBlue) & inDisplayArea;
end	
endmodule
