module BrickBreaker(
		CLOCK_50,
		KEY,
		// The VGA inputs
		VGA_CLK,
		VGA_HS,
		VGA_VS,
		VGA_BLANK_N,
		VGA_SYNC_N,
		VGA_R,
		VGA_G,
		VGA_B
	);
	
	input CLOCK_50;
	input [3:0] KEY;
	
	output VGA_CLK;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	
	wire resetn;
	assign resetn = KEY[0];
	
	wire [7:0] x;
	wire [6:0] y;
	wire [2:0] colour;
	wire writeEn;
	
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	wire store_ram;	
	
	control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.store_ram(store_ram)
	);
	
	datapath d0();
		
endmodule

module control(
		input clk,
		input resetn,
		output reg store_ram
	);

	reg current_state, next_state;
	
	
	
	/* FSM States
	 *
	 * So here's the idea for the states.
	 * First state, we draw everything: all the bricks, the ball at it's initial position,
	 * and the paddle at its initial position.
	 *
	 * Then we enter the second state, third state, MOVE_MOUSE, ERASE_PADDLE, MOVE_PADDLE, DRAW_PADDLE: 
	 * since the mouse can move at any time, we should consistently be in this state such 
	 * that we can redraw the paddle where the mouse is.
	 * 
	 * This loop can be interrupted when we reach 15 (or some other number) of frames, where
	 * we then move the ball, potentially detect a collision, make the ball bounce off, and so on.
	 */
	localparam STORE_INTO_RAM = 4'd0
				  INITIAL_DRAW = 4'd1,
				  MOVE_MOUSE = 4'd2,
				  ERASE_PADDLE = 4'd3,
				  MOVE_PADDLE = 4'd4,
				  DRAW_PADDLE = 4'd5,
				  ERASE_BALL = 4'd6,
				  MOVE_BALL = 4'd7,
				  ERASE_BRICK = 4'd8, // Only when the ball collides with a brick
				  DRAW_BALL = 4'd9;
	
	always @(*)
	begin: state_table
		case (current_state)
			STORE_INTO_RAM: begin
				if (ram_counter == 5'd31) // 32 blocks to store into RAM so 32 clock cycles for that
					next_state = INITIAL_DRAW;
				else
					next_State = STORE_INTO_RAM;
			end
		endcase	
	end // state_table
	
	always @(*)
	begin: enable_signals
		store_ram = 1'b0;
		case (current_state)
			STORE_INTO_RAM: begin
				store_ram = 1'b1;
			end
		endcase
	end // enable_signals
	
	always @(posedge clk)
	begin: stateFFs
		if (!resetn) begin
			current_state <= STORE_INTO_RAM;
		end
	end // stateFFs
	

endmodule

module datapath(
		input clk,
		input store_ram
	);

endmodule
