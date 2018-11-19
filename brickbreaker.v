module BrickBreaker(
		CLOCK_50,
		KEY,
		HEX0,
		// The VGA inputs
		VGA_CLK,
		VGA_HS,
		VGA_VS,
		VGA_BLANK_N,
		VGA_SYNC_N,
		VGA_R,
		VGA_G,
		VGA_B,
		PS2_CLK,
		PS2_DAT
	);
	
	input CLOCK_50;
	input [3:0] KEY;
	output [6:0] HEX0;
	
	output VGA_CLK;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	inout PS2_CLK;
	inout PS2_DAT;
	
	wire resetn;
	assign resetn = KEY[0];
	
	wire [7:0] x;
	wire [6:0] y;
	wire [2:0] colour;
	wire writeEn;
	wire draw;
	
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

	wire store_ram, draw_all_bricks, paddle, enable_black, enable_paddle_move, draw_ball, enable_ball_move;	
	wire [8:0] mouse_x, mouse_y;

	control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.display(HEX0),
		.key_left(~KEY[2]),
		.key_right(~KEY[1]),
		.writeEn(writeEn),
		.store_ram(store_ram),
		.draw(draw),
		.draw_all_bricks(draw_all_bricks),
		.draw_paddle(paddle),
		.enable_black(enable_black),
		.enable_paddle_move(enable_paddle_move),
		.draw_ball(draw_ball),
		.enable_ball_move(enable_ball_move)
	);
	
	datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.store_ram(store_ram),
		.draw_all(draw_all_bricks),
		.draw(draw),
		.draw_paddle(paddle),
		.enable_black(enable_black),
		.enable_paddle_move(enable_paddle_move),
		.mouse_x(mouse_x),
		.key_left(~KEY[2]),
		.key_right(~KEY[1]),
		.draw_ball(draw_ball),
		.enable_ball_move(enable_ball_move),
		.x(x),
		.y(y),
		.colour(colour)
	);
	
	
	mouse_tracker my_mouse(
		.clock(clk),
		.reset(resetn),
		.enable_tracking(1'b1),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.x_pos(mouse_x),
		.y_pos(),
		.left_click(),
		.right_click(),
		.count()
	);
	
	

		
endmodule

module control(
		input clk,
		input resetn,
		input key_left,
		input key_right,
		output [6:0] display,
		output reg writeEn,
		output reg store_ram,
		output reg draw_all_bricks,
		output reg draw,
		output reg draw_paddle,
		output reg enable_black,
		output reg enable_paddle_move,
		output reg draw_ball,
		output reg enable_ball_move
	);

	reg [3:0] current_state, next_state;
	
	hex_decoder h(current_state, display);
	
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
	localparam CLEAR_SCREEN = 4'd12,
				  STORE_INTO_RAM = 4'd0,
				  INITIAL_DRAW = 4'd1,
//				  MOVE_MOUSE = 4'd2,
				  INITIAL_DRAW_PADDLE = 4'd11,
				  ERASE_PADDLE = 4'd3,
				  MOVE_PADDLE = 4'd4,
				  DRAW_PADDLE = 4'd5,
				  WAIT = 4'd10,
				  ERASE_BALL = 4'd6,
				  MOVE_BALL = 4'd7,
				  ERASE_BRICK = 4'd8, // Only when the ball collides with a brick
				  DRAW_BALL = 4'd9;
	
	reg [15:0] clear_counter;
	reg [5:0] ram_counter;
	reg [11:0] draw_all_counter;
	reg [5:0] ball_counter;
	reg [6:0] paddle_counter;
	
	reg [19:0] timer;
	reg [3:0] frame_counter;
	reg [3:0] ball_frame_counter; // To count frame for the ball to move
	
	always @(*)
	begin: state_table
		case (current_state)
			CLEAR_SCREEN: begin
				if (clear_counter == 16'b100101100000000)
					next_state = STORE_INTO_RAM;
				else
					next_state = CLEAR_SCREEN;
			end
			STORE_INTO_RAM: begin
				if (ram_counter == 6'd40) // 40 blocks to store into RAM so 32 clock cycles for that
					next_state = INITIAL_DRAW;
				else
					next_state = STORE_INTO_RAM;
			end
			INITIAL_DRAW: begin
				if (draw_all_counter == 12'b101000000000) // 2560 = 40 bricks * 64 pixels each
					next_state = DRAW_PADDLE;
				else
					next_state = INITIAL_DRAW;
			end
			DRAW_PADDLE: begin
				if (paddle_counter == 7'd64)
					next_state = WAIT;
				else
					next_state = DRAW_PADDLE;
			end
			ERASE_PADDLE: begin
				if (paddle_counter == 7'd64)
					next_state = MOVE_PADDLE;
				else
					next_state = ERASE_PADDLE;
			end
			MOVE_PADDLE: begin
				next_state = DRAW_PADDLE;
			end
			WAIT: begin
				if (frame_counter == 4'b0011 & (key_left | key_right))
					next_state = ERASE_PADDLE;
				else if (ball_frame_counter == 4'b0101)
					next_state = ERASE_BALL;
				else
					next_state = WAIT;
			end
			DRAW_BALL: begin
				if (ball_counter == 5'd4)
					next_state = WAIT;
				else
					next_state = DRAW_BALL;
			end
			ERASE_BALL: begin
				if (ball_counter == 5'd4)
					next_state = MOVE_BALL;
				else
					next_state = ERASE_BALL;
			end
			MOVE_BALL: begin
				next_state = DRAW_BALL;
			end
		endcase	
	end // state_table
	
	always @(*)
	begin: enable_signals
		writeEn = 1'b0;
		store_ram = 1'b0;
		draw_all_bricks = 1'b0;
		draw = 1'b0;
		draw_paddle = 1'b0;
		draw_ball = 1'b0;
		enable_black = 1'b0;
		enable_paddle_move = 1'b0;
		enable_ball_move = 1'b0;
		
		case (current_state)
			STORE_INTO_RAM: begin
				store_ram = 1'b1;
			end
			INITIAL_DRAW: begin
				draw_all_bricks = 1'b1;
				draw = 1'b1;
				writeEn = 1'b1;
			end
			INITIAL_DRAW_PADDLE: begin
				draw_paddle = 1'b1;
				draw = 1'b1;
				writeEn = 1'b1;
			end
			ERASE_PADDLE: begin
				draw_paddle = 1'b1;
				enable_black = 1'b1;
				draw = 1'b1;
				writeEn = 1'b1;
			end
			MOVE_PADDLE: begin
				enable_paddle_move = 1'b1;
			end
			DRAW_PADDLE: begin
				draw_paddle = 1'b1;
				draw = 1'b1;
				writeEn = 1'b1;
			end
			DRAW_BALL: begin
				draw_ball = 1'b1;
				writeEn = 1'b1;
			end
			ERASE_BALL: begin
				draw_ball = 1'b1;
				enable_black = 1'b1;
				writeEn = 1'b1;
			end
			MOVE_BALL: begin
				enable_ball_move = 1'b1;
			end			
		endcase
	end // enable_signals
	
	always @(posedge clk)
	begin: stateFFs
		if (!resetn) begin
			current_state <= CLEAR_SCREEN;
		end
		else begin
			current_state <= next_state;
		end
	end // stateFFs
	
	always @(posedge clk)
		if (!resetn)
			clear_counter <= 16'd0;
		else
		begin
			if (current_state == CLEAR_SCREEN)
				clear_counter <= clear_counter + 1'b1;
			else
				clear_counter <= 16'd0;
		end
	end
	
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

	always @(posedge clk)
	begin: paddle_counting
		if (!resetn)
			paddle_counter <= 7'd0;
		else
		begin
			if (current_state == DRAW_PADDLE | current_state == ERASE_PADDLE)
				paddle_counter <= paddle_counter + 1'b1;
			else
				paddle_counter <= 7'd0;
		end
	end // paddle_counting
	
	always @(posedge clk)
	begin: ball_counting
		if (!resetn)
			ball_counter <= 6'd0;
		else
		begin
			if (current_state == ERASE_BALL | current_state == DRAW_BALL)
				ball_counter <= ball_counter + 1'b1;
			else
				ball_counter <= 6'd0;
		end
	end

	always @(posedge clk)
	begin: frame_counting
		if (!resetn)
		begin
			timer <= 20'b0;
			frame_counter <= 4'b0;
			ball_frame_counter <= 4'b0;
		end
		else
		begin
			if (timer == 20'b11001011011100110101)
			begin
				timer <= 20'b0;
				frame_counter <= frame_counter + 1'b1;
				ball_frame_counter <= ball_frame_counter + 1'b1;
			end
			else
				timer <= timer + 1'b1;
			if (frame_counter == 4'b0011)
				frame_counter <= 4'b0;
			if (ball_frame_counter == 4'b0101)
				ball_frame_counter <= 4'b0;
		end
	end // frame_counting
endmodule

module datapath(
		input clk,
		input resetn,
		input store_ram,
		input draw_all,
		input draw,
		input draw_paddle,
		input enable_black,
		input enable_paddle_move,
		input [8:0] mouse_x,
		input key_right,
		input key_left,
		input draw_ball,
		input enable_ball_move,
		output reg [7:0] x,
		output reg [6:0] y, 
		output reg [2:0] colour
	);
	
	wire [17:0] ram_out;
		
	reg [17:0] ram_info;
	reg [7:0] ram_address;
	reg [5:0] draw_counter;
	reg [1:0] draw_ball_counter;
	
	reg [7:0] paddle_x;
	reg [7:0] ball_x;
	reg [6:0] ball_y;
	reg ball_x_dir, ball_y_dir;
	
	
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
			if (draw == 1'b1)
			begin
				if (draw_counter == 6'b111111)
					draw_counter <= 6'd0;
				else
					draw_counter <= draw_counter + 1'b1;
			end
			else
				draw_counter <= 6'd0;
		end
	end // increment_draw_counter
	
	always @(posedge clk)
	begin: increment_draw_ball_counter
		if (!resetn)
			draw_ball_counter <= 2'b0;
		else
		begin
			if (draw_ball)
			begin
				if (draw_ball_counter == 2'b11)
					draw_ball_counter <= 2'b0;
				else
					draw_ball_counter <= draw_ball_counter + 1'b1;
			end
			else
				draw_ball_counter <= 2'b0;
		end
	end // increment_draw_ball_counter
	
	always @(*)
	begin: decide_where_x_y_colour_come_from
		if (draw_all)
		begin
			x = ram_out[7:0] + draw_counter[3:0];
			y = ram_out[14:8] + draw_counter[5:4];
			colour = ram_out[17:15];
		end
		else if (draw_paddle)
		begin
			x = paddle_x + draw_counter[3:0];
			y = 7'd100 + draw_counter[5:4];
			colour = enable_black ? 3'b000 : 3'b111;
		end
		else if (draw_ball)
		begin
			x = ball_x + draw_ball_counter[0];
			y = ball_y + draw_ball_counter[1];
			colour = enable_black ? 3'b000 : 3'b100;
		end
	end // decide_where_x_y_colour_come_from
	
	always @(posedge clk)
	begin
		if (!resetn)
			paddle_x <= 8'd80;
		else if (enable_paddle_move)
			if (key_left)
				paddle_x <= paddle_x - 1'b1;
			else if (key_right)
				paddle_x <= paddle_x + 1'b1;
	end
	
	always @(posedge clk)
	begin
		if (!resetn)
		begin
			ball_x <= 8'd88;
			ball_y <= 7'd98;
			ball_x_dir <= 1'b1;
			ball_y_dir <= 1'b0;
		end
		else
		begin
			if (enable_ball_move)
			begin
				if (ball_x_dir == 1'b1)
				begin
					if (ball_x == 8'd158) begin
						ball_x_dir <= 1'b0;
						ball_x = 8'd157;
					end
					else
						ball_x <= ball_x + 1'b1;
				end
				else
				begin
					if (ball_x == 8'd0) begin
						ball_x_dir <= 1'b1;
						ball_x = 8'd1;
					end
					else
						ball_x <= ball_x - 1'b1;
				end
				if (ball_y_dir == 1'b1)
				begin
					if (ball_y < 7'd118)
						ball_y <= ball_y + 1'b1;
				end
				else
				begin
					if (ball_y == 7'd0) begin
						ball_y_dir <= 1'b1;
						ball_y = 7'd1;
					end
					else
						ball_y <= ball_y - 1'b1;
				end
			end
		end
	end
endmodule

