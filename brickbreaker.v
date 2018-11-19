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

	wire store_ram, draw_all_bricks;	
	
	control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.writeEn(writeEn),
		.store_ram(store_ram),
		.draw_all_bricks(draw_all_bricks)
	);
	
	datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.store_ram(store_ram),
		.draw_all(draw_all_bricks),
		.x(x),
		.y(y),
		.colour(colour)
	);
		
endmodule

module control(
		input clk,
		input resetn,
		output reg writeEn,
		output reg store_ram,
		output reg draw_all_bricks
	);

	reg current_state, next_state;
	
	// Bricks will be 16x4 pixels
	
	/* FSM States
	 *
	 * So here's the idea for the states.
	 * First state, we draw everything: all the bricks, the ball at it's initial position,
	 * and the paddle at its initial position.
	 *
	 * Then we enter the second state, third state, ... ERASE_PADDLE, MOVE_PADDLE, DRAW_PADDLE: 
	 * since the mouse can move at any time, we should consistently be in this state such 
	 * that we can redraw the paddle where the mouse is.
	 * 
	 * This loop can be interrupted when we reach 15 (or some other number) of frames, where
	 * we then move the ball, potentially detect a collision, make the ball bounce off, and so on.
	 */
	localparam STORE_INTO_RAM = 4'd0,
				  INITIAL_DRAW = 4'd1,
//				  MOVE_MOUSE = 4'd2,
				  ERASE_PADDLE = 4'd3,
				  MOVE_PADDLE = 4'd4,
				  DRAW_PADDLE = 4'd5,
				  ERASE_BALL = 4'd6,
				  MOVE_BALL = 4'd7,
				  ERASE_BRICK = 4'd8, // Only when the ball collides with a brick
				  DRAW_BALL = 4'd9;
	
	reg [5:0] ram_counter;
	reg [11:0] draw_all_counter;
	
	always @(*)
	begin: state_table
		case (current_state)
			STORE_INTO_RAM: begin
				if (ram_counter == 6'd40) // 40 blocks to store into RAM so 32 clock cycles for that
					next_state = INITIAL_DRAW;
				else
					next_state = STORE_INTO_RAM;
			end
			INITIAL_DRAW: begin
				if (draw_all_counter == 12'b101000000000) // 2560 = 40 bricks * 64 pixels each
					next_state = ERASE_PADDLE;
				else
					next_state = INITIAL_DRAW;
			end
		endcase	
	end // state_table
	
	always @(*)
	begin: enable_signals
		writeEn = 1'b0;
		store_ram = 1'b0;
		draw_all_bricks = 1'b0;
		
		case (current_state)
			STORE_INTO_RAM: begin
				store_ram = 1'b1;
			end
			INITIAL_DRAW: begin
				draw_all_bricks = 1'b1;
				writeEn = 1'b1;
			end
		endcase
	end // enable_signals
	
	always @(posedge clk)
	begin: stateFFs
		if (!resetn) begin
			current_state <= STORE_INTO_RAM;
		end
		else begin
			current_state <= next_state;
		end
	end // stateFFs
	
	always @(posedge clk)
	begin: ram_counting
		if (!resetn)
			ram_counter <= 6'd0;
		else
		begin
			if (current_state == STORE_INTO_RAM)
			begin
				ram_counter <= ram_counter + 1'b1;
			end
			else
				ram_counter <= 6'd0;
		end
	end // ram_counting
	
	always @(posedge clk)
	begin: brick_counting
		if (!resetn)
			draw_all_counter <= 12'd0;
		else
		begin
			if (current_state == INITIAL_DRAW)
				draw_all_counter <= draw_all_counter + 1'b1;
			else
				draw_all_counter <= 12'b0;
		end
	end // brick_counting

endmodule

module datapath(
		input clk,
		input resetn,
		input store_ram,
		input draw_all,
		output reg [7:0] x,
		output reg [6:0] y, 
		output reg [2:0] colour
	);
	
	wire [17:0] ram_out;
		
	reg [17:0] ram_info;
	reg [7:0] ram_address;
	reg [5:0] draw_counter;
	
	ram256x18 storage(
		.data(ram_info),
		.address(ram_address),
		.wren(store_ram),
		.clock(clk),
		.q(ram_out)
	);

	
	/*
	 * ram_info holds all the information, the color, y, x
	 * ram_address holds the address for which the info of a brick will be stored
	 * To generate the bricks, x += 16, once x reaches end of screen, x = 0, y += 8. Address
	 * increments by one each time.
	 */
	always @(posedge clk)
	begin
		if (!resetn)
		begin
			ram_info <= 18'b001000000000000000;
			ram_address <= 8'd0;
		end
		else if (store_ram == 1'b1)
		begin
			// ram_address increment for each brick added into memory
			if (ram_address == 8'd40)
				ram_address <= 8'd0;
			else
				ram_address <= ram_address + 1'b1;
				
			// Cycle through colours for some spice in life
			if (ram_info[17:15] == 3'b111)
				ram_info[17:15] <= 3'b001;
			else
				ram_info[17:15] <= ram_info[17:15] + 1'b1;
				
			if (ram_info[7:0] == 8'd144)
			begin
				ram_info[7:0] <= 8'd0;
				ram_info[14:8] <= ram_info[14:8] + 7'd8;
			end
			else
				ram_info[7:0] <= ram_info[7:0] + 8'd16;
		end
		else if (draw_all) begin
			ram_info <= 18'd0;
			if (draw_counter == 6'b111111) begin
				if (ram_address == 8'd40)
					ram_address <= 8'd0;
				else
					ram_address <= ram_address + 1'b1;
			end
		end
	end

	always @(posedge clk)
	begin: increment_draw_counter
		if (!resetn)
			draw_counter <= 6'd0;
		else
		begin
			if (draw_all)
			begin
				if (draw_counter == 6'b111111)
					draw_counter <= 6'd0;
				else
					draw_counter <= draw_counter + 1'b1;
			end
		end
	end // increment_draw_counter
	
	always @(*)
	begin: decide_where_x_y_colour_come_from
		if (draw_all)
		begin
			x = ram_out[7:0] + draw_counter[3:0];
			y = ram_out[14:8] + draw_counter[5:4];
			colour = ram_out[17:15];
		end
	end // decide_where_x_y_colour_come_from
endmodule
