module BrickBreaker(
		CLOCK_50,
		KEY,
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR,
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
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output [2:0] LEDR;
	
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

	wire store_ram, draw_all_bricks, paddle, enable_black, enable_paddle_move, draw_ball, enable_ball_move, clear_screen;	
	wire enable_brick_erase, enable_collision_detection, enable_black_brick;
	wire [8:0] mouse_x, mouse_y;

	control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.display(),                      //removed HEX0 from here
		.key_left(~KEY[2]),
		.key_right(~KEY[1]),
		.mouse_x_in(x_coord),
		.writeEn(writeEn),
		.store_ram(store_ram),
		.draw(draw),
		.draw_all_bricks(draw_all_bricks),
		.draw_paddle(paddle),
		.enable_black(enable_black),
		.enable_paddle_move(enable_paddle_move),
		.draw_ball(draw_ball),
		.enable_ball_move(enable_ball_move),
		.clear_screen(clear_screen),
		.enable_collision_detection(enable_collision_detection),
		.enable_brick_erase(enable_brick_erase),
		.enable_black_brick(enable_black_brick)
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
		.mouse_x_in(x_coord),
		.key_left(~KEY[2]),
		.key_right(~KEY[1]),
		.draw_ball(draw_ball),
		.enable_ball_move(enable_ball_move),
		.clear_screen(clear_screen),
		.enable_collision_detection(enable_collision_detection),
		.enable_brick_erase(enable_brick_erase),
		.enable_black_brick(enable_black_brick),
		.x(x),
		.y(y),
		.colour(colour)
	);
	
	wire [8:0] x_coord, y_coord;
	
//	ps2 #(
//			.WIDTH(160),
//			.HEIGHT(120),
//			.BIN(100),
//			.HYSTERESIS(30))
//	mouse1(
//			.start(~KEY[0]),  
//			.reset(~KEY[1]),  
//			.CLOCK_50(CLOCK_50),  
//			.PS2_CLK(PS2_CLK), 
//			.PS2_DAT(PS2_DAT), 
//			.button_left(LEDR[0]),  
//			.button_right(LEDR[1]),  
//			.button_middle(LEDR[2]),  
//			.bin_x(x_coord),
//			.bin_y(y_coord)
//			);
			
			
			////////////////////////////////////////////////////**********************************************************///////////////////////////////////////
			////////////////////////////////////////   HEX displays for testing mouse coordinates, leave in for now, do not need. Same with LEDS. /////////////////
			///////////////////////////////////// module called tester below is what drives mouse so don't touch that//////////////////////////////////////
	  hex_decoder hex0(
	     .hex_digit(x_coord[3:0]),
		  .segments(HEX0)
		  );

    hex_decoder hex1(
	     .hex_digit(x_coord[7:4]),
		  .segments(HEX1)
		  );

    hex_decoder hex2(
	     .hex_digit({3'b0, x_coord[8]}),
		  .segments(HEX2)
		  );

    // Put Y coordinates on hex displays 3-5

    hex_decoder hex3(
	     .hex_digit(y_coord[3:0]),
		  .segments(HEX3)
		  );

    hex_decoder hex4(
	     .hex_digit(y_coord[7:4]),
		  .segments(HEX4)
		  );

    hex_decoder hex5(
	     .hex_digit({3'b0, y_coord[8]}),
		  .segments(HEX5)
		  );
	
	mouse_tracker tester(
	     .clock(CLOCK_50),
		  .reset(KEY[0]),
		  .enable_tracking(1'b1),
		  .PS2_CLK(PS2_CLK),
		  .PS2_DAT(PS2_DAT),
		  .x_pos(x_coord),
		  .y_pos(y_coord),
		  .left_click(LEDR[1]),
		  .right_click(LEDR[0])
		  );
	  

/*	mouse_tracker my_mouse(
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
	
	*/
endmodule

module control(
		input clk,
		input resetn,
		input key_left,
		input key_right,
		input [7:0] mouse_x_in,
		output [6:0] display,
		output reg writeEn,
		output reg store_ram,
		output reg draw_all_bricks,
		output reg draw,
		output reg draw_paddle,
		output reg enable_black,
		output reg enable_paddle_move,
		output reg draw_ball,
		output reg enable_ball_move,
		output reg clear_screen,
		output reg enable_brick_erase,
		output reg enable_collision_detection,
		output reg enable_black_brick
	);

	reg [3:0] current_state, next_state;
	
	reg [7:0] mouse_prev;
	//hex_decoder h(current_state, display);                took out/////////////////
	
	// Bricks will be 16x4 pixels
	
	/* FSM States
	 *
	 * So here's the actual idea for the states
	 * 1. CLEAR_SCREEN draws black over the entire screen, essentially reseting it
	 * 2. STORE_INTO_RAM intializes all the bricks into the 256x18 ram
	 * 3. INITIAL_DRAW draws all the bricks onto the screen
	 * 4. WAIT waits for the time when something can happen by counting frames. Then it hands off to
	 *    either ERASE_PADDLE or ERASE_BALL to trigger a movement in either of those objects
	 * 5. ERASE_PADDLE erases the paddle
	 * 6. MOVE_PADDLE moves the paddle to the mouse coordinate
	 * 7. DRAW_PADDLE draws the paddle onto the screen
	 * 8. ERASE_BALL, MOVE_BALL, DRAW_BALL are analagous
	 * 9. DETECT_COLLISION goes through the ram and checks whether the ball has collided with a brick
	 *    that is hasn't been hit before. i.e. the brick isn't black already
	 * 10. ERASE_BRICK removes a collided brick from view
	 */
	localparam CLEAR_SCREEN = 4'd0,
				  STORE_INTO_RAM = 4'd1,
				  INITIAL_DRAW = 4'd2,
				  ERASE_PADDLE = 4'd3,
				  MOVE_PADDLE = 4'd4,
				  DRAW_PADDLE = 4'd5,
				  WAIT = 4'd6,
				  ERASE_BALL = 4'd7,
				  MOVE_BALL = 4'd8,
				  DRAW_BALL = 4'd9,
				  DETECT_COLLISION = 4'd10,
				  STORE_BLACK_BRICK = 4'd11,
				  ERASE_BRICK = 4'd12;
	
	reg [15:0] clear_counter;    // ensure CLEAR_SCREEN lasts long enough
	reg [5:0] ram_counter; 		  // ensure the storing/checking the ram lasts	
	reg [11:0] draw_all_counter; // ensure that drawing all the bricks lasts
	reg [5:0] ball_counter;		  // ensure drawing ball lasts
	reg [6:0] paddle_counter;    // ensure drawing paddle lasts
	reg [6:0] brick_counter; 	  // ensure erasing brick lasts
	
	reg [19:0] timer;			     // 60 Hz counter
	reg [3:0] frame_counter;	  // Count the frames for the paddle to move
	reg [3:0] ball_frame_counter;// To count frame for the ball to move
	
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
				if (draw_all_counter == 12'd2560) // 2560 = 40 bricks * 64 pixels each
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
				if (frame_counter == 4'b0010) //& (mouse_x_in == mouse_prev))                                    //don't need any condition for mouse apparantely
				//if (frame_counter == 4'b0011 & (key_left | key_right))             //speed of paddle
					next_state = ERASE_PADDLE;
				else if (ball_frame_counter == 4'b0001)                            //speed of ball
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
					next_state = DETECT_COLLISION;
				else
					next_state = ERASE_BALL;
			end
			DETECT_COLLISION: begin
				if (ram_counter == 6'd40)
					next_state = STORE_BLACK_BRICK;
				else
					next_state = DETECT_COLLISION;
			end
			STORE_BLACK_BRICK: begin
				next_state = ERASE_BRICK;
			end
			ERASE_BRICK: begin
				if (brick_counter == 7'd64)
					next_state = MOVE_BALL;
				else
					next_state = ERASE_BRICK;
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
		clear_screen = 1'b0;
		enable_collision_detection = 1'b0;
		enable_brick_erase = 1'b0;
		enable_black_brick = 1'b0;
		
		case (current_state)
			CLEAR_SCREEN: begin
				clear_screen = 1'b1;
				writeEn = 1'b1;
			end
			STORE_INTO_RAM: begin
				store_ram = 1'b1;
			end
			INITIAL_DRAW: begin
				draw_all_bricks = 1'b1;
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
			DETECT_COLLISION: begin
				enable_collision_detection = 1'b1;
			end
			STORE_BLACK_BRICK: begin
				store_ram = 1'b1;
				enable_black_brick = 1'b1;
			end
			ERASE_BRICK: begin
				enable_brick_erase = 1'b1;
				draw = 1'b1;
				writeEn = 1'b1;
			end
		endcase
	end // enable_signals
	
	//store mouse coordinate
	always @(posedge clk)
	begin: storing_mouse_coordinate
		if (!resetn)
			mouse_prev <= 7'd0;
		else
		begin
			mouse_prev <= mouse_x_in;
		end
	end
	
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
	begin: clear_counting
		if (!resetn)
			clear_counter <= 16'd0;
		else
		begin
			if (current_state == CLEAR_SCREEN)
				clear_counter <= clear_counter + 1'b1;
			else
				clear_counter <= 16'd0;
		end
	end // clear_counting
	
	always @(posedge clk)
	begin: ram_counting
		if (!resetn)
			ram_counter <= 6'd0;
		else
		begin
			if (current_state == STORE_INTO_RAM | current_state == DETECT_COLLISION)
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
	begin: brick_erasing
		if (!resetn)
			brick_counter <= 7'd0;
		else
		begin
			if (current_state == ERASE_BRICK)
				brick_counter <= brick_counter + 1'b1;
			else
				brick_counter <= 7'd0;
		end
	end // brick_erasing

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
			if (timer == 20'b11001011011100110101)               //org value b11001011011100110101
			begin
				timer <= 20'b0;
				frame_counter <= frame_counter + 1'b1;
				ball_frame_counter <= ball_frame_counter + 1'b1;
			end
			else
				timer <= timer + 1'b1;
			if (frame_counter == 4'b0010)                                   //speed of paddle
				frame_counter <= 4'b0;
			if (ball_frame_counter == 4'b0001)                              //speed of ball
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
		input [7:0] mouse_x_in,
		input key_right,
		input key_left,
		input draw_ball,
		input enable_ball_move,
		input clear_screen,
		input enable_collision_detection,
		input enable_brick_erase,
		input enable_black_brick,
		output reg [7:0] x,
		output reg [6:0] y,
		output reg [2:0] colour
	);
	
	wire [17:0] ram_out;
	
	reg [7:0] clear_x;
	reg [6:0] clear_y;
	reg [17:0] ram_info;
	reg [7:0] ram_address;
	reg [5:0] draw_counter;
	reg [1:0] draw_ball_counter;
	
	reg [7:0] paddle_x;
	reg [7:0] ball_x;
	reg [6:0] ball_y;
	reg ball_x_dir, ball_y_dir;
	
	reg [7:0] mouse_prev;

	reg clear_screen_reg;
	
	reg [7:0] brick_to_clear_x;
	reg [6:0] brick_to_clear_y;
	reg actually_collides;
	reg [7:0] address_of_collision;
	reg [17:0] info_of_collided_brick;
	
	
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
			if (enable_black_brick & actually_collides)
			begin
				ram_address <= address_of_collision;
				ram_info <= info_of_collided_brick;
			end
			else
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
		else if (enable_collision_detection)
		begin
			if (ram_address == 8'd40)
				ram_address <= 8'd0;
			else
				ram_address <= ram_address + 1'b1;
		end
	end
	
		//store mouse coordinate
	always @(posedge clk)
	begin: storing_mouse_coordinate
		if (!resetn)
			mouse_prev <= 7'd0;
		else
		begin
			mouse_prev <= mouse_x_in;
		end
	end
	
//		//store clear screen                     //moved to moving paddle always block
//	always @(posedge clk)
//	begin: storing_mouse_coordinate_data
//		if (!resetn)
//			clear_screen_reg <= 7'd0;
//		else
//		begin
//			clear_screen_reg <= clear_screen;
//		end
//	end
	
	always @(posedge clk)
	begin: clearing_screen
		if (!resetn)
		begin
			clear_x <= 8'd0;
			clear_y <= 7'd0;
		end
		else
		begin
			if (clear_screen_reg)              //changed
			begin
				if (clear_x == 8'd159)
				begin
					clear_x <= 8'd0;
					if (clear_y == 7'd119)
						clear_y <= 7'd0;
					else
						clear_y <= clear_y + 1'b1;
				end
				else
					clear_x <= clear_x + 1'b1;
			end
		end
	end // clearing_screen

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
			y = 7'd115 + draw_counter[5:4];
			colour = enable_black ? 3'b000 : 3'b111;
		end
		else if (draw_ball)
		begin
			x = ball_x + draw_ball_counter[0];
			y = ball_y + draw_ball_counter[1];
			colour = enable_black ? 3'b000 : 3'b100;
		end
		else if (clear_screen_reg)
		begin
			x = clear_x;
			y = clear_y;
			colour = 3'b000;
		end
		else if (enable_brick_erase & actually_collides)
		begin
			x = brick_to_clear_x + draw_counter[3:0];
			y = brick_to_clear_y + draw_counter[5:4];
			colour = 3'b000;
		end
	end // decide_where_x_y_colour_come_from
	
	always @(posedge clk)
	begin: paddle_movement
		if (!resetn)
			paddle_x <= 8'd80;
		else if (enable_paddle_move) begin
			//if (mouse_x_in != mouse_prev) begin                            //mouse_x_in != mouse_prev
				//if (paddle_x != 8'd0)
					paddle_x <= mouse_x_in;           //or can just decrement x value???????????????? whichever works best with mouse
					//paddle_x <= paddle_x - 1'b1;
			//end
//			else if (key_right) begin
//				if (paddle_x != 8'd148)
//					paddle_x <= <= mouse_x_in;
//				end
		end
	end // paddle_movement
	
	always @(posedge clk)
	begin
		if (!resetn)
		begin
			ball_x <= 8'd88;
			ball_y <= 7'd98;
			ball_x_dir <= 1'b1;
			ball_y_dir <= 1'b0;
			clear_screen_reg <= 7'd0;
			actually_collides <= 1'b0;
			address_of_collision <= 8'd0;
		end
		else
		begin
			clear_screen_reg <= clear_screen;
			if (enable_ball_move)
			begin
				if (ball_x_dir == 1'b1)
				begin
					if (ball_x == 8'd158) begin
						ball_x_dir <= 1'b0;
						ball_x <= 8'd157;
					end
					else
						ball_x <= ball_x + 1'b1;
				end
				else
				begin
					if (ball_x == 8'd0) begin
						ball_x_dir <= 1'b1;
						ball_x <= 8'd1;
					end
					else
						ball_x <= ball_x - 1'b1;
				end
				if (ball_y_dir == 1'b1)
				begin
					if (ball_y < 7'd110)
						ball_y <= ball_y + 1'b1;
					/////////////////////////////////////ball collisions////////////////////////////
					else if (ball_y == 7'd110) begin                   //later on have if ball past 115 and not hit paddle reset game
						if ((((paddle_x + 16) - ball_x) < 16) & (((paddle_x + 16) - ball_x) >= 0)) begin
							ball_y_dir <= 1'b0;
							ball_y <= 7'd109;
						end
						else 
							ball_y <= ball_y + 1'b1;
							//clear_screen_reg <= 1'b1;                   //trying level reset//////////////////
					end
//					else if(ball_y < 7'd117) begin
//						ball_y <= ball_y + 1'b1;
//					end
					else begin
						if(ball_y < 7'd117) begin
							ball_y <= ball_y + 1'b1;
						end
						else begin
							ball_y_dir <= 1'b0;
							ball_y <= 7'd116;
						end
					end               
				end
				else
				begin
					if (ball_y == 7'd0) begin
						ball_y_dir <= 1'b1;
						ball_y <= 7'd1;
					end
					else
						ball_y <= ball_y - 1'b1;
				end
			end
			else if (enable_collision_detection)
			begin
				if (ram_out[17:15] != 3'b000) // Black bricks are already hit bricks
				begin
					if ((ram_out[7:0] - ball_x < 16) & (ram_out[14:8] == (ball_y - 2)))
					begin // Case where ball hits the brick from above. Ball should be moving down
						ball_y_dir <= 1'b0;
						brick_to_clear_x <= ram_out[7:0];
						brick_to_clear_y <= ram_out[14:8];
						info_of_collided_brick = {3'b000, ram_out[14:0]};
						actually_collides <= 1'b1;
						address_of_collision <= ram_address;
					end
					else if ((ram_out[7:0] - ball_x < 16) & ((ram_out[14:8] + 4) == ball_y))
					begin // Case where ball hits the brick from below
						ball_y_dir <= 1'b1;
						brick_to_clear_x <= ram_out[7:0];
						brick_to_clear_y <= ram_out[14:8];
						info_of_collided_brick = {3'b000, ram_out[14:0]};
						actually_collides <= 1'b1;
						address_of_collision <= ram_address;
					end
					else if ((ram_out[7:0] == (ball_x + 2)) & (ram_out[14:8] - ball_y < 4))
					begin // Case where ball hits the brick from the left edge
						ball_x_dir <= 1'b0;
						brick_to_clear_x <= ram_out[7:0];
						brick_to_clear_y <= ram_out[14:8];
						info_of_collided_brick = {3'b000, ram_out[14:0]};
						actually_collides <= 1'b1;
						address_of_collision <= ram_address;
					end
					else if ((ram_out[7:0] + 16 == ball_x) & (ram_out[14:8] - ball_y < 4))
					begin
						ball_x_dir <= 1'b1;
						brick_to_clear_x <= ram_out[7:0];
						brick_to_clear_y <= ram_out[14:8];
						info_of_collided_brick = {3'b000, ram_out[14:0]};
						actually_collides <= 1'b1;
						address_of_collision <= ram_address;
					end
				end
			end
			else if (~enable_brick_erase)
				actually_collides = 1'b0;
		end
	end
endmodule

