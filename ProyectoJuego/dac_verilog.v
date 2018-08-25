//////////////////////////////////////////////////////////////////////////////////
// Nombre: DAC Spartan 3E Starter Board - Verilog
// Autor: Ignacio Bugueño
// Fecha: Agosto - 2018
// Email: ignacio.bugueno@live.com
//////////////////////////////////////////////////////////////////////////////////

// Definicion del modulo, donde se declaran entradas y salidas

module dac_verilog(
	clk, enable, done, data,
	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO,
	SPI_SS_B, SF_CE0, FPGA_INIT_B, AD_CONV, AMP_CS);

	// input and outputs
	input clk, enable, SPI_MISO;
	output done; // goes high for one clock cycle when done
	input [11:0] data; // desired DAC value
	output SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
	output SPI_SS_B, SF_CE0, FPGA_INIT_B, AD_CONV, AMP_CS; //disable

	//Conexiones desactivadas en el BUS
	assign SPI_SS_B = 1;
	assign SF_CE0 = 1;
	assign FPGA_INIT_B = 0; //revisar
	assign AMP_CS = 1;
	assign AD_CONV = 0;

	wire clk, enable, SPI_MISO;
	reg done;
	wire [11:0] data;
	wire [3:0] address = 4’b0000; // DAC A
	reg SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;

	// internal variables
	reg [2:0] Cs = 0;
	reg [31:0] send;
	reg [5:0] bit_pos = 32;

	always @(posedge clk) 
	begin
		// when enable is on
		if (enable == 1) 
		begin
			case (Cs)
				0: begin
					// initial
					DAC_CS <= 1;
					SPI_MOSI <= 0;
					SPI_SCK <= 0;
					DAC_CLR <= 1;
					done <= 0;
					Cs <= Cs + 1;
				end
				1: begin
					// set data to be sent
					send <= {8’b00000000, 4’b0011, address, data, 4’b0000};

					// set for next
					bit_pos <= 32;
					Cs <= Cs + 1;
				end
				2: begin
					// start sending
					DAC_CS <= 0;

					// lower clock
					SPI_SCK <= 0;
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
					done <= 1; // send done signal
					Cs <= Cs + 1;
				end
				7: begin
					done <= 0; // go back to loop
					Cs <= 1;
				end
				default: begin
					DAC_CS <= 1;
					SPI_MOSI <= 0;
					SPI_SCK <= 0;
					DAC_CLR <= 1;
				end
			endcase
		end 

		else 
		begin
			// reset
			DAC_CS <= 1;
			SPI_MOSI <= 0;
			SPI_SCK <= 0;
			DAC_CLR <= 1;
			done <= 0;
			Cs <= 0;
			bit_pos <= 32;
		end
	end
endmodule