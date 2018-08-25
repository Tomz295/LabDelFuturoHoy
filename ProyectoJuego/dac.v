`timescale 1ns / 1ps

module DAC(
	clk, enable, done, data, address,
	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO,
	SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B);

	// input and outputs
	input 	clk, enable, SPI_MISO;
	output	done;			// goes high for one clock cycle when done
	input 	[11:0]	data;		// desired DAC value
	input 	[3:0]	address;	// DAC want to use
	output 	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
	output 	SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B;

	wire 	clk, enable, SPI_MISO;
	reg	done;
	wire 	[11:0]	data;
	wire 	[3:0]	address;
	reg 	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
	reg 	SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B;

	// internal variables
	reg [2:0] 	Cs = 0;
	reg [31:0]	send;
	reg [5:0]	bit_pos = 32;	

	always @(posedge clk) begin
		// when enable is on
		if (enable == 1) begin
			// disable other SPI devices
			SPI_SS_B 	<= 1;
			AMP_CS 		<= 1;
			AD_CONV 		<= 0;
			SF_CE0 		<= 1;
			FPGA_INIT_B <= 1;

			case (Cs)
				0:	begin
						// initial
						DAC_CS 	<= 1;
						SPI_MOSI <= 0;
						SPI_SCK	<= 0;
						DAC_CLR	<= 1;
						done 		<= 0;
						Cs <= Cs + 1;
					end
				1: begin
						// set data to be sent
						send <= {8'b00000000, 4'b0011, address, data, 4'b0000};

						// set for next
						bit_pos <= 32;
						Cs <= Cs + 1;
					end
				2: begin
						// start sending
						DAC_CS 	<= 0;

						// lower clock
						SPI_SCK	<= 0;

						// set data pin
						SPI_MOSI <= send[bit_pos-1];
						bit_pos <= bit_pos - 1;
						Cs <= Cs + 1;
					end
				3: begin
						// rise spi clock
						if (bit_pos > 0) begin
							SPI_SCK <= 1;
							Cs <= 2;
						end else begin
							SPI_SCK <= 1;
							Cs <= Cs + 1;
						end
					end
				4: begin
						SPI_SCK <= 0;
						Cs <= Cs + 1;
					end
				5: begin
						DAC_CS <= 1;
						Cs <= Cs + 1;
					end
				6: begin
						done <= 1;	// send done signal
						Cs <= Cs + 1;
					end
				7: begin
						done <= 0;	// go back to loop
						Cs <= 1;
					end
				default: begin
						DAC_CS 	<= 1;
						SPI_MOSI <= 0;
						SPI_SCK	<= 0;
						DAC_CLR	<= 1;
					end
			endcase
		end else begin
			// reset
			DAC_CS 	<= 1;
			SPI_MOSI <= 0;
			SPI_SCK	<= 0;
			DAC_CLR	<= 1;
			done 		<= 0;
			Cs 		<= 0;
			bit_pos 	<= 32;
		end
	end
endmodule