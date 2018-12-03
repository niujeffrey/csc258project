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
	output [9:0] LEDR;
	
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
	
	wire [8:0] x;
	wire [7:0] y;
	wire [8:0] colour;
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
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	wire store_ram, draw_all_bricks, paddle, enable_black, enable_paddle_move, draw_ball, enable_ball_move, clear_screen, soft_reset, subtract_powerup;	
	wire enable_brick_erase, enable_collision_detection, enable_black_brick, initial_ram, actually_erase, loss_restart, enable_autopilot, restart;
	wire [8:0] mouse_x, mouse_y;
	wire [7:0] score;
	wire [3:0] lives_remaining;
	wire [3:0] num_powerups;
	
	control c0(
		.clk(CLOCK_50),
		.resetn(resetn),                      //removed HEX0 from here
		.key_left(~KEY[2]),
		.key_right(~KEY[1]),
		.mouse_x_in(x_coord),
		.right_click(right_click),
		.left_click(left_click),
		.num_powerups(num_powerups),
		.loss_restart(loss_restart),
		.restart(restart),
		.writeEn(writeEn),
		.store_ram(store_ram),
		.draw(draw),
		.draw_all_bricks(draw_all_bricks),
		.draw_paddle(paddle),
		.enable_black(enable_black),
		.enable_paddle_move(enable_paddle_move),
		.enable_autopilot(enable_autopilot),
		.draw_ball(draw_ball),
		.enable_ball_move(enable_ball_move),
		.clear_screen(clear_screen),
		.enable_collision_detection(enable_collision_detection),
		.enable_brick_erase(enable_brick_erase),
		.enable_black_brick(enable_black_brick),
		.initial_ram(initial_ram),
		.actually_erase(actually_erase),
		.soft_reset(soft_reset),
		.subtract_powerup(subtract_powerup)
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
		.enable_autopilot(enable_autopilot),
		.left_click(left_click),
		.mouse_x_in(x_coord),
		.key_left(~KEY[2]),
		.key_right(~KEY[1]),
		.draw_ball(draw_ball),
		.enable_ball_move(enable_ball_move),
		.clear_screen(clear_screen),
		.enable_collision_detection(enable_collision_detection),
		.enable_brick_erase(enable_brick_erase),
		.enable_black_brick(enable_black_brick),
		.initial_ram(initial_ram),
		.actually_erase(actually_erase),
		.loss_restart(loss_restart),
		.restart(restart),
		.soft_reset(soft_reset),
		.subtract_powerup(subtract_powerup),
		.x(x),
		.y(y),
		.colour(colour),
		.score(score),
		.lives_remaining(lives_remaining),
		.num_powerups(num_powerups)
	);
	
	wire [8:0] x_coord, y_coord;
	wire right_click;
	wire left_click;

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

    hex_decoder hex3(
	     .hex_digit(lives_remaining),
		  .segments(HEX3)
		  );

    hex_decoder hex4(
	     .hex_digit(score[3:0]),
		  .segments(HEX4)
		  );

    hex_decoder hex5(
	     .hex_digit(score[7:4]),
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
		  .left_click(left_click),
		  .right_click(right_click)
		  );
		defparam tester.XMAX = 9'd319;
		defparam tester.YMAX = 9'd239;
	  
	assign LEDR[0] = right_click;
	assign LEDR[1] = left_click;
	
	assign LEDR[9:6] = num_powerups;

endmodule

module control(
		input clk,
		input resetn,
		input key_left,
		input key_right,
		input [8:0] mouse_x_in,
		input loss_restart,
		input restart,
		input right_click,
		input left_click,
		input [3:0] num_powerups,
		output reg writeEn,
		output reg store_ram,
		output reg draw_all_bricks,
		output reg draw,
		output reg draw_paddle,
		output reg enable_black,
		output reg enable_paddle_move,
		output reg enable_autopilot,
		output reg draw_ball,
		output reg enable_ball_move,
		output reg clear_screen,
		output reg enable_brick_erase,
		output reg enable_collision_detection,
		output reg enable_black_brick,
		output reg actually_erase,
		output reg initial_ram,
		output reg soft_reset,
		output reg subtract_powerup
	);

	reg [3:0] current_state, next_state;
	
	reg [8:0] mouse_prev;
		
	// Bricks will be 32x8 pixels
	
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
				  ERASE_BRICK = 4'd12,
				  ACTUAL_ERASE = 4'd13,
				  SOFT_RESET = 4'd14,
				  SET_POWERUP = 4'd15,
//				  MOVE_PADDLE_AUTOPILOT = 4'd14,
				  X_MAX = 9'd319,
				  Y_MAX = 8'd239;
				  
	
	reg [16:0] clear_counter;    // ensure CLEAR_SCREEN lasts long enough
	reg [5:0] ram_counter; 		  // ensure the storing/checking the ram lasts	
	reg [13:0] draw_all_counter; // ensure that drawing all the bricks lasts
	reg [5:0] ball_counter;		  // ensure drawing ball lasts
	reg [8:0] paddle_counter;    // ensure drawing paddle lasts
	reg [8:0] brick_counter; 	  // ensure erasing brick lasts
	
	reg [19:0] timer;			     // 60 Hz counter
	reg [19:0] ball_timer;
	reg [3:0] frame_counter;	  // Count the frames for the paddle to move
	reg [3:0] ball_frame_counter;// To count frame for the ball to move
	
	reg [1:0] storage_counter;
	
	reg [25:0] autopilot_counter;
	reg [25:0] double_speed_counter;
	
	reg [19:0] ball_counter_limit;
	
	always @(posedge clk)
	begin
		ball_counter_limit = double_speed_counter > 26'd0 ? 20'd208333 : 20'd416667;
	end
	
	always @(*)
	begin: state_table
		case (current_state)
			CLEAR_SCREEN: begin
				if (clear_counter == 17'd76800) // 320*240 pixels to clear
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
				if (draw_all_counter == 14'd10240) // 10240 = 40 bricks * 256 pixels each
					next_state = WAIT;
				else
					next_state = INITIAL_DRAW;
			end
			DRAW_PADDLE: begin
				if (paddle_counter == 9'd256)
					next_state = WAIT;
				else
					next_state = DRAW_PADDLE;
			end
//			MOVE_PADDLE_AUTOPILOT: begin
//				if (paddle_counter == 9'd256)
//					next_state = WAIT;
//				else
//					next_state = DRAW_PADDLE_AUTOPILOT;
//			end
			ERASE_PADDLE: begin
				if (paddle_counter == 9'd256)
					next_state = MOVE_PADDLE;
				else
					next_state = ERASE_PADDLE;
			end
			MOVE_PADDLE: begin
//				if (right_click)
//					next_state = DRAW_PADDLE_AUTOPILOT;
//				else
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
				if (ball_counter == 6'd15)           //changed for ball size, was 4
					next_state = WAIT;
				else
					next_state = DRAW_BALL;
			end
			ERASE_BALL: begin
				if (ball_counter == 6'd15)           //changed for ball size, was 5
					next_state = DETECT_COLLISION;
				else
					next_state = ERASE_BALL;
			end
			DETECT_COLLISION: begin
				if (ram_counter == 6'd63)
					next_state = STORE_BLACK_BRICK;
				else
					next_state = DETECT_COLLISION;
			end
			STORE_BLACK_BRICK: begin
				if (storage_counter == 2'd1)
					next_state = ACTUAL_ERASE;
				else
					next_state = STORE_BLACK_BRICK;
			end
			ACTUAL_ERASE: begin
				next_state = ERASE_BRICK;
			end
			ERASE_BRICK: begin
				if (brick_counter == 9'd256)
					next_state = MOVE_BALL;
				else
					next_state = ERASE_BRICK;
			end
			MOVE_BALL: begin
				if (restart)
					next_state = SOFT_RESET;
				else if (((right_click & autopilot_counter == 26'b0) || (left_click & double_speed_counter == 26'b0)) && num_powerups > 4'd0)
					next_state = SET_POWERUP;
				else
					next_state = DRAW_BALL;
			end
			SOFT_RESET: begin
				next_state = loss_restart ? CLEAR_SCREEN : DRAW_BALL;
			end
			SET_POWERUP: begin
				next_state = DRAW_BALL;
			end
		endcase	
	end // state_table
	
	always @(*)
	begin: enable_signals
		writeEn = 1'b0;
		store_ram = 1'b0;
		initial_ram = 1'b0;
		draw_all_bricks = 1'b0;
		draw = 1'b0;
		draw_paddle = 1'b0;
		draw_ball = 1'b0;
		enable_black = 1'b0;
		enable_paddle_move = 1'b0;
		enable_autopilot = 1'b0;
		enable_ball_move = 1'b0;
		clear_screen = 1'b0;
		enable_collision_detection = 1'b0;
		enable_brick_erase = 1'b0;
		enable_black_brick = 1'b0;
		actually_erase = 1'b0;
		soft_reset = 1'b0;
		subtract_powerup = 1'b0;
		
		case (current_state)
			CLEAR_SCREEN: begin
				clear_screen = 1'b1;
				writeEn = 1'b1;
			end
			STORE_INTO_RAM: begin
				store_ram = 1'b1;
				initial_ram = 1'b1;
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
				if(autopilot_counter > 26'b0)
					enable_autopilot = 1'b1;
//				else if(autopilot_counter != 23'd0) //!= 23'd8388608)
//					enable_autopilot = 1'b1;
				else 
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
				enable_black_brick = 1'b1;
			end
			ERASE_BRICK: begin
				enable_brick_erase = 1'b1;
				draw = 1'b1;
				writeEn = 1'b1;
			end
			ACTUAL_ERASE: begin
				store_ram = 1'b1;
				actually_erase = 1'b1;
			end
			SOFT_RESET: begin
				soft_reset = 1'b1;
			end
			SET_POWERUP: begin
				subtract_powerup = 1'b1;
			end
		endcase
	end // enable_signals
	
	//store mouse coordinate
	always @(posedge clk)
	begin: storing_mouse_coordinate
		if (!resetn)
			mouse_prev <= 8'd0;
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
			clear_counter <= 17'd0;
		else
		begin
			if (current_state == CLEAR_SCREEN)
				clear_counter <= clear_counter + 1'b1;
			else
				clear_counter <= 17'd0;
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
			draw_all_counter <= 14'd0;
		else
		begin
			if (current_state == INITIAL_DRAW)
				draw_all_counter <= draw_all_counter + 1'b1;
			else
				draw_all_counter <= 14'b0;
		end
	end // brick_counting
	
	always @(posedge clk)
	begin: brick_erasing
		if (!resetn)
			brick_counter <= 9'd0;
		else
		begin
			if (current_state == ERASE_BRICK)
				brick_counter <= brick_counter + 1'b1;
			else
				brick_counter <= 9'd0;
		end
	end // brick_erasing

	always @(posedge clk)
	begin: paddle_counting
		if (!resetn)
			paddle_counter <= 9'd0;
		else
		begin
			if (current_state == DRAW_PADDLE | current_state == ERASE_PADDLE)
				paddle_counter <= paddle_counter + 1'b1;
			else
				paddle_counter <= 9'd0;
		end
	end // paddle_counting

	always @(posedge clk)
	begin: powerup_duration
		if (!resetn) begin
			autopilot_counter <= 26'd0;
			double_speed_counter <= 26'd0;
		end
		else
		begin
			if (current_state == SET_POWERUP && right_click)
				autopilot_counter <= 26'd50000000;
			else if (autopilot_counter > 26'd0)
				autopilot_counter <= autopilot_counter - 1'b1;
			if (current_state == SET_POWERUP && left_click)
				double_speed_counter <= 26'd50000000;
			else if (double_speed_counter > 26'd0)
				double_speed_counter <= double_speed_counter - 1'b1;
		end
	end // powerup_duration
	
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
	begin
		if (!resetn)
			storage_counter <= 2'd0;
		else
		begin
			if (current_state == STORE_BLACK_BRICK)
				storage_counter <= storage_counter + 1'b1;
			else
				storage_counter <= 2'b0;
		end
	end
	
	always @(posedge clk)
	begin: frame_counting
		if (!resetn)
		begin
			timer <= 20'b0;
			ball_timer <= 20'b0;
			frame_counter <= 4'b0;
			ball_frame_counter <= 4'b0;
		end
		else
		begin
			if (timer == 20'd833333)               //org value b11001011011100110101
			begin
				timer <= 20'b0;
				frame_counter <= frame_counter + 1'b1;
			end
			else
				timer <= timer + 1'b1;
			if (frame_counter == 4'b0010)                                   //speed of paddle
				frame_counter <= 4'b0;
			if (ball_timer == ball_counter_limit)
			begin
				ball_timer <= 20'd0;
				ball_frame_counter <= ball_frame_counter + 1'b1;
			end
			else if (ball_timer > ball_counter_limit)
				ball_timer <= 20'd0;
			else
				ball_timer <= ball_timer + 1'b1;
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
		input enable_autopilot,
		input [8:0] mouse_x_in,
		input key_right,
		input key_left,
		input draw_ball,
		input enable_ball_move,
		input clear_screen,
		input enable_collision_detection,
		input enable_brick_erase,
		input enable_black_brick,
		input actually_erase,
		input initial_ram,
		input left_click,
		input soft_reset,
		input subtract_powerup,
		output reg [8:0] x,
		output reg [7:0] y,
		output reg [8:0] colour,
		output reg loss_restart,
		output reg restart,
		output reg [7:0] score,
		output reg [3:0] lives_remaining,
		output reg [3:0] num_powerups
	);
	
	localparam X_MAX = 9'd319,
				  Y_MAX = 8'd239,
				  X_RECT = 5'd16,
				  Y_RECT = 4'd8;
				  //SPEED_CONSTANT = 3'd1;
	
	reg [6:0] bricks_hit;
	
	wire [27:0] ram_out;
	
	reg [8:0] clear_x;
	reg [7:0] clear_y;
	reg [27:0] ram_info;
	reg [7:0] ram_address;
	reg [7:0] draw_counter;
	reg [4:0] draw_ball_counter;
	
	reg [8:0] paddle_x;
	reg [8:0] ball_x;
	reg [7:0] ball_y;
	reg ball_x_dir, ball_y_dir;
	reg [5:0] ball_dir;
	
	reg [8:0] mouse_prev;

	reg clear_screen_reg;
	
	reg [8:0] brick_to_clear_x;
	reg [7:0] brick_to_clear_y;
	reg actually_collides;
	reg [1:0] collision_level;
	reg [7:0] address_of_collision;
	reg [27:0] info_of_collided_brick;
	
	reg [7:0] last_score;
	
	wire [1:0] SPEED_CONSTANT;
	assign SPEED_CONSTANT = 2'b01;
	
	// Make the ram256x32
	ram256x32 storage(
		.data(ram_info),
		.address(ram_address),
		.wren(store_ram & (initial_ram | actually_collides)),
		.clock(clk),
		.q(ram_out)
	);

	
	/*
	 * ram_info holds all the information, the state, color, y, x in that order, 
	 * that will be stored into the ram
	 * ram_address holds the address for which the info of a brick will be stored
	 * To generate the bricks, x += 16, once x reaches end of screen, x = 0, y += 8. Address
	 * increments by one each time.
	 */
	always @(posedge clk)
	begin
		if (!resetn)
		begin
			ram_info <= 28'b1111100000000000000000000000;
			ram_address <= 8'd0;
		end
		else if (clear_screen) begin
			ram_info <= 28'b1111100000000000000000000000;
			ram_address <= 8'd0;
		end
		else if (store_ram == 1'b1)
		begin
//			if (enable_black_brick & actually_collides)
//			begin
//				ram_address <= address_of_collision;
//				ram_info <= info_of_collided_brick;
//			end
//			else
//			begin
				// ram_address increment for each brick added into memory
			if (ram_address == 8'd40)
				ram_address <= 8'd0;
			else
				ram_address <= ram_address + 1'b1;
				
			// Cycle through colours for some spice in life
			//raminfo[21:20] is state of brick in regards to how broken it is
			//raminfo[19:17] are for colour
			if (ram_address == 8'd39)
				ram_info[27:17] <= 11'd0;
			else if (ram_info[25:17] == 9'b111111111)                           //change this for colour
				ram_info[27:17] <= 11'b11111000000;
			else
				ram_info[27:17] <= ram_info[27:17] + 3'd1;
				
			if (ram_info[8:0] == 9'd288)
			begin
				ram_info[8:0] <= 9'd0;
				ram_info[16:9] <= ram_info[16:9] + 8'd24;
			end
			else
				ram_info[8:0] <= ram_info[8:0] + 9'd32;
//			end
		end
		else if (draw_all) begin
			ram_info <= 28'd0;
			if (draw_counter == 8'b11111111) begin
				if (ram_address == 8'd39)
					ram_address <= 8'd0;
				else
					ram_address <= ram_address + 1'b1;
			end
		end
		else if (enable_collision_detection)
		begin
			if (ram_address == 8'd39)
				ram_address <= 8'd0;
			else
				ram_address <= ram_address + 1'b1;
		end
		else if (enable_black_brick & actually_collides)
		begin
			ram_address <= address_of_collision == 8'd0 ? 8'd39 : address_of_collision - 1'b1;
			ram_info <= info_of_collided_brick;
		end
	end
	
		//store mouse coordinate
	always @(posedge clk)
	begin: storing_mouse_coordinate
		if (!resetn)
			mouse_prev <= 8'd0;
		else
		begin
			mouse_prev <= mouse_x_in;
		end
	end
	
	always @(posedge clk)
	begin: clearing_screen
		if (!resetn)
		begin
			clear_x <= 9'd0;
			clear_y <= 8'd0;
		end
		else
		begin
			if (clear_screen_reg)              //changed
			begin
				if (clear_x == X_MAX)
				begin
					clear_x <= 9'd0;
					if (clear_y == Y_MAX)
						clear_y <= 8'd0;
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
		if (!resetn | clear_screen)
			draw_counter <= 8'd0;
		else
		begin
			if (draw == 1'b1)
			begin
				if (draw_counter == 8'b11111111)
					draw_counter <= 8'd0;
				else
					draw_counter <= draw_counter + 1'b1;
			end
			else
				draw_counter <= 8'd0;
		end
	end // increment_draw_counter
	
	always @(posedge clk)                                    //change this for ball size
	begin: increment_draw_ball_counter
		if (!resetn | clear_screen)
			draw_ball_counter <= 4'b0;
		else
		begin
			if (draw_ball)
			begin
				if (draw_ball_counter == 5'b10000)                //one more than num pixels needed for ball. EX 3x3 ball needs 9 pixels, make this value 10
					draw_ball_counter <= 4'b0;
				else
					draw_ball_counter <= draw_ball_counter + 1'b1;
			end
			else
				draw_ball_counter <= 4'b0;
		end
	end // increment_draw_ball_counter
	
	always @(*)
	begin: decide_where_x_y_colour_come_from
		if (draw_all)
		begin
			x = ram_out[8:0] + draw_counter[4:0];
			y = ram_out[16:9] + draw_counter[7:5];
			if (draw_counter[7:5] == 3'b0 || draw_counter[7:5] == 3'd7)
				colour = 9'b0;
			else
				colour = ram_out[25:17];
		end
		else if (draw_paddle)
		begin
			x = paddle_x + draw_counter[4:0];
			y = 8'd231 + draw_counter[7:5];
			colour = enable_black ? 9'b000 : 9'b111111111;
		end
		else if (draw_ball)
		begin
			x = ball_x + draw_ball_counter[1:0];
			y = ball_y + draw_ball_counter[3:2];
			colour = enable_black ? 9'b000 : 9'b111000000;
		end
		else if (clear_screen_reg)
		begin
			x = clear_x;
			y = clear_y;
			colour = 9'b000;
		end
		else if (enable_brick_erase & actually_collides & collision_level == 2'b01)
		begin
			x = brick_to_clear_x + draw_counter[4:0];
			y = brick_to_clear_y + draw_counter[7:5];
			colour = 9'b000;
		end
		else if (enable_brick_erase & actually_collides & collision_level == 2'b10)              //this parts makes pixelated bricks when hit
		begin
			x = brick_to_clear_x + draw_counter[3:0] * 4 + 3;
			y = brick_to_clear_y + draw_counter[1:0] * 2 + 1;
			colour = 9'b000;
		end
		else if (enable_brick_erase & actually_collides & collision_level == 2'b11)
		begin
			x = brick_to_clear_x + draw_counter[3:0] * 4 + 1;
			y = brick_to_clear_y + draw_counter[1:0] * 2;
			colour = 9'b000;
		end
	end // decide_where_x_y_colour_come_from
	
	always @(posedge clk)
	begin: paddle_movement
//		if (!resetn | clear_screen)
//			paddle_x <= 8'd80;
//			paddle_x <= mouse_x_in;
//		else if (enable_paddle_move) begin
		if (enable_paddle_move) begin
			//if (mouse_x_in != mouse_prev) begin                            //mouse_x_in != mouse_prev
				//if (paddle_x != 8'd0)
					paddle_x <= mouse_x_in;
		end
		else if(enable_autopilot) begin// & num_powerups >= 1) begin
			paddle_x <= ball_x - 12;
		end
	end // paddle_movement
	
	always @(posedge clk)
	begin
		if (!resetn)
		begin
			score <= 8'd0;
			bricks_hit <= 7'd0;
			last_score <= 8'd0;
			num_powerups <= 4'd0;
		end
		else if (clear_screen)
			bricks_hit <= 7'd0;
		else
		begin
			if (actually_erase & actually_collides & collision_level == 2'b01)
			begin
				score <= score + 1'b1;
				bricks_hit <= bricks_hit + 1'b1;
			end
			else if (lives_remaining == 4'd0)
				score <= 8'd0;
			if(score == last_score + 5) begin
				last_score <= score;
				num_powerups <= num_powerups + 1;
			end
			else if (subtract_powerup) begin
				num_powerups <= num_powerups - 1;
			end
			else if (lives_remaining == 4'd0)
			begin
				num_powerups <= 4'd0;
				last_score <= 8'd0;
			end
		end
	end
	
	always @(posedge clk)
	begin
		if (!resetn)
		begin
			lives_remaining <= 4'd3;
			loss_restart <= 1'b0;
			restart <= 1'b0;
		end
		if (clear_screen)
			loss_restart <= 1'b0;
		else
		begin
			if (soft_reset)
				lives_remaining <= lives_remaining - 1'b1;
			if ((ball_y == Y_MAX) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) == Y_MAX))  // Lose by hitting the bottom of the screen
			begin
				if (lives_remaining == 4'd1)
					loss_restart <= 1'b1;
				restart <= 1'b1;
			end
			else if (bricks_hit == 7'd40) begin // Clear all the blocks
				loss_restart <= 1'b1;
				restart <= 1'b1; // not really a loss, just restart
			end
			else if (~soft_reset && ~enable_ball_move) // Didn't lose
			begin
				loss_restart <= 1'b0;
				restart <= 1'b0;
			end
			if (lives_remaining == 4'd0)
			begin
				lives_remaining <= 4'd3;
			end
		end
	end
	
	
	//////////////////////////////For warp_speed powerup
//	always @(posedge clk)
//	begin: warp_speed
//		if (!resetn)
//			SPEED_CONSTANT <= 2'd1;
//		else if (left_click & ball_y < 227)
//			SPEED_CONSTANT <= 2'd2;
//		else
//			SPEED_CONSTANT <= 2'd1;
//	end

	
	always @(posedge clk)
	begin
		if (!resetn | clear_screen | soft_reset)
		begin
			ball_x <= X_MAX / 2;
			ball_y <= 8'd171;   //was 231
			ball_x_dir <= 1'b1;
			ball_y_dir <= 1'b0;
			ball_dir <= 6'd0;
			clear_screen_reg <= 7'd0;
			actually_collides <= 1'b0;
			address_of_collision <= 8'd0;
			info_of_collided_brick <= 20'd0;
			brick_to_clear_x <= 9'd0;
			brick_to_clear_y <= 8'd0;
			collision_level <= 2'd0;
		end
		else
		begin
			clear_screen_reg <= clear_screen;
			if (enable_ball_move)                    ///////////////////////////////////////////for ball and paddle collisions
			begin
				if (ball_dir == 6'd0)   //slope of 1 positive (up right)
				//only need to consider if hits right wall or top wall
				begin
					if ((ball_x == X_MAX - 4) || ((ball_x + (1 * (SPEED_CONSTANT - 1))) == X_MAX - 4)) begin                         //(1 * SPEED_CONSTANT)) begin
						ball_dir <= 6'd2;                //dir 2 is 90 degrees to dir 0  (up left)
						ball_x <= X_MAX - 2;
					end
					else
						ball_x <= ball_x + 1'b1 * SPEED_CONSTANT;

					if ((ball_y == 8'd0) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) == 8'd0)) begin
						ball_dir <= 6'd3;        //now down right
						ball_y <= 8'd1;
					end
					else
						ball_y <= ball_y - 1'b1 * SPEED_CONSTANT;
				end
				
				if (ball_dir == 6'd1)   //slope of 1 positive (down left)
				begin
					if ((ball_y < 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < 8'd229))
						ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
					/////////////////////////////////////ball collisions////////////////////////////
					else if ((ball_y == 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) == 8'd229)) begin                   
//						if ((((paddle_x + 32) - ball_x) < 32) & (((paddle_x + 32) - ball_x) >= 0)) begin
//							ball_dir <= 6'd2;   //now up left
//							ball_y <= 8'd228;
//						end
						if ( ((((paddle_x + 7) - ball_x) < 7) & (((paddle_x + 7) - ball_x) >= 0)) || 
							((((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
							ball_dir <= 6'd6;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) || 
							((((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) begin
							ball_dir <= 6'd2;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) || 
							((((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 4) & (((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) begin
							ball_dir <= 6'd8;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) || 
							((((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) begin
							ball_dir <= 6'd0;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) || 
							((((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) begin
							ball_dir <= 6'd4;
							ball_y <= 8'd228;
						end
							else 
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
					end
	
					///////////////////////////////////////////////////////////why this?????????????????????////////////////////////////
					//to move ball between distance from paddle and bottom of screen when user misses
					else begin
						if((ball_y < Y_MAX) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < Y_MAX)) begin
							ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						end
					end 

					if ((ball_x == 9'd0) || ((ball_x - (1 * (SPEED_CONSTANT - 1))) == 9'd0)) begin
						ball_dir <= 6'd3;        // now go down right
						ball_x <= 9'd1;
					end
					else
						ball_x <= ball_x - 1'b1 * SPEED_CONSTANT;
					
				end
				
				////////////// up left
				if (ball_dir == 6'd2)
				begin
				//only need to consider if hits left wall or top wall
					begin
						if ((ball_x == 9'd0) || ((ball_x - (1 * (SPEED_CONSTANT - 1))) == 9'd0)) begin
							ball_dir <= 6'd0;                //dir 2 is 90 degrees to dir 0  (up right)
							ball_x <= 9'd1;
						end
						else
							ball_x <= ball_x - 1'b1 * SPEED_CONSTANT;
					end

					begin
						if ((ball_y == 8'd0) || ((ball_y - (1 * (SPEED_CONSTANT - 1))) == 8'd0)) begin
							ball_dir <= 6'd1;             //now down left
							ball_y <= 8'd1;
						end
						else
							ball_y <= ball_y - 1'b1 * SPEED_CONSTANT;
					end
				end
				
				
				//down right
				if (ball_dir == 6'd3)   
				begin
					begin
					if ((ball_x == X_MAX - 4) || ((ball_x + (1 * (SPEED_CONSTANT - 1))) == X_MAX - 4)) begin       
						ball_dir <= 6'd1;                //dir 2 is 90 degrees to dir 0  (down left)
						ball_x <= X_MAX - 2;
					end
					else
						ball_x <= ball_x + 1'b1 * SPEED_CONSTANT;
					end	
						
					begin
						if ((ball_y < 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < 8'd229))
							ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						/////////////////////////////////////ball collisions////////////////////////////
						else if ((ball_y == 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) == 8'd229)) begin                   
//							if ((((paddle_x + 32) - ball_x) < 32) & (((paddle_x + 32) - ball_x) >= 0)) begin
//								ball_dir <= 6'd0;   //now up right
//								ball_y <= 8'd228;
//							end
						if ( ((((paddle_x + 7) - ball_x) < 7) & (((paddle_x + 7) - ball_x) >= 0)) || 
							((((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
							ball_dir <= 6'd6;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) || 
							((((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) begin
							ball_dir <= 6'd2;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) || 
							((((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 4) & (((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) begin
							ball_dir <= 6'd8;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) || 
							((((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) begin
							ball_dir <= 6'd0;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) || 
							((((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) begin
							ball_dir <= 6'd4;
							ball_y <= 8'd228;
						end
							else 
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						end
		
						///////////////////////////////////////////////////////////why this?????????????????????////////////////////////////
						else begin
							if ((ball_y < Y_MAX) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < Y_MAX)) begin
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
							end
						end 
					end
				end
				if (ball_dir == 6'd4)   //slope of 1 positive (up right 2)
				//only need to consider if hits right wall or top wall
				begin
					if ((ball_x == X_MAX - 4) || (ball_x + 1 == X_MAX - 4) || ((ball_x + 1 + (2 * (SPEED_CONSTANT - 1))) == X_MAX - 4) || (ball_x + 1 + (1 * (SPEED_CONSTANT - 1)) == X_MAX - 4)) begin            
						ball_dir <= 6'd6;                //dir 2 is 90 degrees to dir 0  (up left)
						ball_x <= X_MAX - 2;
					end
					else
						ball_x <= ball_x + 2 * SPEED_CONSTANT;

					if ((ball_y == 8'd0) || ((ball_y - (1 * (SPEED_CONSTANT - 1))) == 8'd0)) begin
						ball_dir <= 6'd7;        //now down right 2
						ball_y <= 8'd1;
					end
					else
						ball_y <= ball_y - 1'b1 * SPEED_CONSTANT;
				end
				
				
				if (ball_dir == 6'd5)   //slope of 2 negative (down left)
				begin
					if ((ball_x == 9'd0) || (ball_x - 1 == 9'd0) || ((ball_x - 1 - (2 * (SPEED_CONSTANT - 1))) == 9'd0) || ((ball_x - 1 - (1 * (SPEED_CONSTANT - 1))) == 9'd0)) begin
						ball_dir <= 6'd7;        // now go down right 2
						ball_x <= 9'd1;
					end
					else
						ball_x <= ball_x - 2 * SPEED_CONSTANT;
						
					if ((ball_y < 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < 8'd229) || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) < 8'd229))
						ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
					/////////////////////////////////////ball collisions////////////////////////////
					else if ((ball_y == 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) == 8'd229)) begin                   
//						if ((((paddle_x + 32) - ball_x) < 32) & (((paddle_x + 32) - ball_x) >= 0)) begin
//							ball_dir <= 6'd6;   //now up left
//							ball_y <= 8'd228;
//						end
						if ( ((((paddle_x + 7) - ball_x) < 7) & (((paddle_x + 7) - ball_x) >= 0)) || 
							((((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
							ball_dir <= 6'd6;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) || 
							((((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) begin
							ball_dir <= 6'd2;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) || 
							((((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 4) & (((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) begin
							ball_dir <= 6'd8;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) || 
							((((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) begin
							ball_dir <= 6'd0;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) || 
							((((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) begin
							ball_dir <= 6'd4;
							ball_y <= 8'd228;
						end
							else 
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
					end
	
					///////////////////////////////////////////////////////////why this?????????????????????////////////////////////////
					//to move ball between distance from paddle and bottom of screen when user misses
					else begin
						if ((ball_y < Y_MAX) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < Y_MAX) || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) < Y_MAX)) begin
							ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						end
					end 					
					////////////////////////////////////////// y direction going down left
					
				end
				
				////////////// up left 2
				if (ball_dir == 6'd6)
				begin
				//only need to consider if hits left wall or top wall
					begin
						if ((ball_x == 9'd0) || (ball_x - 1 == 9'd0) || ((ball_x - 1 - (2 * (SPEED_CONSTANT - 1))) == 9'd0) || ((ball_x - 1 -  (1 * (SPEED_CONSTANT - 1))) == 9'd0)) begin
							ball_dir <= 6'd4;                //dir 2 is 90 degrees to dir 0  (up right)
							ball_x <= 9'd1;
						end
						else
							ball_x <= ball_x - 2 * SPEED_CONSTANT;
					end

					begin
						if ((ball_y == 8'd0) || ((ball_y - (1 * (SPEED_CONSTANT - 1))) == 8'd0)) begin
							ball_dir <= 6'd5;             //now down left 2
							ball_y <= 8'd1;
						end
						else
							ball_y <= ball_y - 1'b1 * SPEED_CONSTANT;
					end
				end
				
				//down right 2
				if (ball_dir == 6'd7)   
				begin
					begin
					if ((ball_x == X_MAX - 4) || (ball_x + 1 == X_MAX - 4) || ((ball_x + 1 + (2 * (SPEED_CONSTANT - 1))) == X_MAX - 4) || ((ball_x + 1 + (1 * (SPEED_CONSTANT - 1))) == X_MAX - 4)) begin           
						ball_dir <= 6'd5;                //dir 2 is 90 degrees to dir 0  (down left)
						ball_x <= X_MAX - 2;
					end
					else
						ball_x <= ball_x + 2 * SPEED_CONSTANT;
					end	
						
					begin
						if ((ball_y < 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < 8'd229) || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) < 8'd229))         
							ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						/////////////////////////////////////ball collisions////////////////////////////
						else if ((ball_y == 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) == 8'd229) || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) == 8'd229)) begin                   
//							if ((((paddle_x + 32) - ball_x) < 32) & (((paddle_x + 32) - ball_x) >= 0)) begin
//								ball_dir <= 6'd4;   //now up right
//								ball_y <= 8'd228;
//							end
						if ( ((((paddle_x + 7) - ball_x) < 7) & (((paddle_x + 7) - ball_x) >= 0)) || 
							((((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
							ball_dir <= 6'd6;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) || 
							((((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) begin
							ball_dir <= 6'd2;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) || 
							((((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 4) & (((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) begin
							ball_dir <= 6'd8;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) || 
							((((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) begin
							ball_dir <= 6'd0;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) || 
							((((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) begin
							ball_dir <= 6'd4;
							ball_y <= 8'd228;
						end
							else 
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						end
		
						///////////////////////////////////////////////////////////why this?????????????????????////////////////////////////
						//to move ball between distance from paddle and bottom of screen when user misses
						else begin
							if ((ball_y < Y_MAX) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < Y_MAX) || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) < Y_MAX)) begin
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
							end
						end 
					end
				end
				//up
				if (ball_dir == 6'd8)
				begin
					
					if ((ball_y == 8'd0) || ((ball_y - (1 * (SPEED_CONSTANT - 1))) == 8'd0)) begin
						ball_dir <= 6'd9;        
						ball_y <= 8'd1;
					end
					else
						ball_y <= ball_y - 1'b1 * SPEED_CONSTANT;
						
				end
				
				//down
				if(ball_dir == 6'd9)
				begin
					if ((ball_y < 8'd229) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < 8'd229))// || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) < 8'd229))
						ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
					/////////////////////////////////////ball collisions////////////////////////////
					else if ((ball_y == 8'd229) || ((ball_y + (2 * (SPEED_CONSTANT - 1))) == 8'd229)) begin// || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) == 8'd229)) begin              //changed multiple to 2     
//						if ((((paddle_x + 32) - ball_x) < 32) & (((paddle_x + 32) - ball_x) >= 0)) begin
//							ball_dir <= 6'd8;   //now up right
//							ball_y <= 8'd228;
//						end
						if ( ((((paddle_x + 7) - ball_x) < 7) & (((paddle_x + 7) - ball_x) >= 0)) || 
							((((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 7) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
							ball_dir <= 6'd6;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) || 
							((((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 14) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 14) - ball_x) < 7) & (((paddle_x + 14) - ball_x) >= 0)) begin
							ball_dir <= 6'd2;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) || 
							((((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 4) & (((paddle_x + 18) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 18) - ball_x) < 4) & (((paddle_x + 18) - ball_x) >= 0)) begin
							ball_dir <= 6'd8;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) || 
							((((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 25) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 25) - ball_x) < 7) & (((paddle_x + 25) - ball_x) >= 0)) begin
							ball_dir <= 6'd0;
							ball_y <= 8'd228;
						end
						else if ( ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) || 
							((((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) < 7) & (((paddle_x + 32) - (ball_x - (1 * (SPEED_CONSTANT - 1)))) >= 0)) ) begin
						//else if ((((paddle_x + 32) - ball_x) < 7) & (((paddle_x + 32) - ball_x) >= 0)) begin
							ball_dir <= 6'd4;
							ball_y <= 8'd228;
						end
							else 
								ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
					end
	
					///////////////////////////////////////////////////////////why this?????????????????????////////////////////////////
					else begin
						if ((ball_y < Y_MAX) || ((ball_y + (1 * (SPEED_CONSTANT - 1))) < Y_MAX)) begin// || ((ball_y + 1 + (1 * (SPEED_CONSTANT - 1))) < Y_MAX)) begin
							ball_y <= ball_y + 1'b1 * SPEED_CONSTANT;
						end
					end
				end
			end
			else if (enable_collision_detection)
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////////////////////should split up faster moving directions into their own blocks because they need more positions checked. i.e x and x+1///////////////////////
			///////////////////////////////////////																																							////////////////////////////////////////////////////
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			
			
			//didn't do side collisions with  speed constant
			
			
			begin
				if (ram_out[27:26] != 2'b00) // Black bricks are already hit bricks
				begin
					if (((ball_x - ram_out[8:0] < 32) & (ball_x - ram_out[8:0] >= 0) & (ram_out[16:9] == (ball_y + 4))) 
							|| (((ball_x + (1 * (SPEED_CONSTANT - 1))) - ram_out[8:0] < 32) & ((ball_x - (1 * (SPEED_CONSTANT - 1))) - ram_out[8:0] >= 0) & (ram_out[16:9] == ((ball_y + 3 + (1 * (SPEED_CONSTANT - 1))))))
							||  ((ball_dir == 6'd5 || ball_dir == 6'd7 || ball_dir == 6'd9) & 
							(((ball_x + 1 + (2 * (SPEED_CONSTANT - 1))) - ram_out[8:0] < 32) & ((ball_x - 1 - (2 * (SPEED_CONSTANT - 1))) - ram_out[8:0] >= 0) & (ram_out[16:9] == ((ball_y + 3 + (2 * (SPEED_CONSTANT - 1)))))))
							|| ((ball_dir == 6'd5 || ball_dir == 6'd7 || ball_dir == 6'd9) & 
							(((ball_x + 1 + (2 * (SPEED_CONSTANT - 1))) - ram_out[8:0] < 32) & ((ball_x - 1 - (2 * (SPEED_CONSTANT - 1))) - ram_out[8:0] >= 0) & (ram_out[16:9] == ((ball_y + 4 + (2 * (SPEED_CONSTANT - 1)))))))
							|| (((ball_x == ram_out[8:0] + 1) || (ball_x == ram_out[8:0] + 2)) & (ram_out[16:9] == (ball_y + 4))))  //add 3 pixels since ball is 4x4 and bottommost pixel is y=4
					begin
					//when ball going in any downward direction
					
						if(ball_dir == 6'd1 || ball_dir == 6'd3 || ball_dir == 6'd5 || ball_dir == 6'd7 || ball_dir == 6'd9)
						begin // Case where ball hits the brick from above. Ball should be moving down
							if(ball_dir == 6'd1)   //if was down left, make up left
								ball_dir <= 6'd2;
							else if (ball_dir == 6'd3)	//if was down right, make up right
								ball_dir <= 6'd0;
							else if (ball_dir == 6'd5)
								ball_dir <= 6'd6;
							else if (ball_dir == 6'd7)
								ball_dir <= 6'd4;
							else if (ball_dir == 6'd9)
								ball_dir <= 6'd8;
						end
							brick_to_clear_x <= ram_out[8:0];
							brick_to_clear_y <= ram_out[16:9];
							info_of_collided_brick <= {ram_out[27:26] - 1'b1, 9'b0, ram_out[16:0]};
							actually_collides <= 1'b1;
							collision_level <= ram_out[27:26];
							address_of_collision <= ram_address;
//						end
					end
					
					
					if (((ram_out[8:0] == (ball_x + 3)) & (ball_y - ram_out[16:9] < 8) & (ball_y - ram_out[16:9] >= 0))
							|| (ram_out[8:0] == (ball_x + 4) & (ball_y - ram_out[16:9] < 8) & (ball_y - ram_out[16:9] >= 0))
							|| ((ram_out[8:0] == (ball_x + 3 - (1 * (SPEED_CONSTANT - 1)))) & (ball_y - ram_out[16:9] < 8) & (ball_y - ram_out[16:9] >= 0)) ) begin
						if(ball_dir == 6'd0 || ball_dir == 6'd3 || ball_dir == 6'd4 || ball_dir == 6'd7 || ball_dir == 6'd8)  //either up right, or down right
						begin // Case where ball hits the brick from the left edge
							if(ball_dir == 6'd0)   //if was up right, make up left
								ball_dir <= 6'd2;
							else if (ball_dir == 6'd3)  //if was down right, make down left
								ball_dir <= 6'd1;
							else if (ball_dir == 6'd4)
								ball_dir <= 6'd6;
							else if (ball_dir == 6'd7)
								ball_dir <= 6'd5;
							else if (ball_dir == 6'd8)
								ball_dir <= 6'd9;
						end
							brick_to_clear_x <= ram_out[8:0];
							brick_to_clear_y <= ram_out[16:9];
							info_of_collided_brick <= {ram_out[27:26] - 1'b1, 9'b0, ram_out[16:0]};
							actually_collides <= 1'b1;
							collision_level <= ram_out[27:26];
							address_of_collision <= ram_address;
//						end
					end
					if ((ball_x - ram_out[8:0] < 32) & (ball_x - ram_out[8:0] >= 0) & ((ram_out[16:9] + 8) == ball_y) 
//							|| (((ball_x + (1 * (SPEED_CONSTANT - 1))) - ram_out[8:0] < 32) & ((ball_x - (1 * (SPEED_CONSTANT - 1))) - ram_out[8:0] >= 0) & ((ram_out[16:9] + 8) == (ball_y - (1 * (SPEED_CONSTANT - 1)))))) begin
						 || ((ball_x - ram_out[8:0] < 32) & (ball_x - ram_out[8:0] >= 0) & ((ram_out[16:9] + 8) == (ball_y - 1))) || 
						 (((ball_x == ram_out[8:0] - 1) || (ball_x == ram_out[8:0] - 2)) & (ram_out[16:9] == ball_y)))
					begin	
						if(ball_dir == 6'd0 || ball_dir == 6'd2 || ball_dir == 6'd4 || ball_dir == 6'd6 || ball_dir == 6'd8)     //any upward direction
						begin // Case where ball hits the brick from below
							if(ball_dir == 6'd0)   //if was up right, make down right
								ball_dir <= 6'd3;
							else if (ball_dir == 6'd2)						//if was up left, make down left                  ///////////////////////////////////////does else if (ball_dir == 6'd2) work?
								ball_dir <= 6'd1;
							else if (ball_dir == 6'd4)
								ball_dir <= 6'd7;
							else if (ball_dir == 6'd6)
								ball_dir <= 6'd5;
							else if (ball_dir == 6'd8) // up to down
								ball_dir <= 6'd9;
						end
							brick_to_clear_x <= ram_out[8:0];
							brick_to_clear_y <= ram_out[16:9];
							info_of_collided_brick <= {ram_out[27:26] - 1'b1, 9'b0, ram_out[16:0]};
							actually_collides <= 1'b1;
							collision_level <= ram_out[27:26];
							address_of_collision <= ram_address;
//						end
					end
					if ((ram_out[8:0] + 32 == ball_x) & (ball_y - ram_out[16:9] < 8) & (ball_y - ram_out[16:9] >= 0)
						|| (ram_out[8:0] + 31 == ball_x) & (ball_y - ram_out[16:9] < 8) & (ball_y - ram_out[16:9] >= 0)) begin
						if(ball_dir == 6'd1 || ball_dir == 6'd2 || ball_dir == 6'd5 || ball_dir == 6'd6 || ball_dir == 6'd8)    //any leftward direction
						begin // Case where ball hits the brick from right edge
							if(ball_dir == 6'd1)   //if was up left, make up right
								ball_dir <= 6'd0;
							else if (ball_dir == 6'd2)						//if was down left, make down right
								ball_dir <= 6'd3;
							else if (ball_dir == 6'd5) 
								ball_dir <= 6'd7;
							else if (ball_dir == 6'd6)
								ball_dir <= 6'd4;
							else if (ball_dir == 6'd8)
								ball_dir <= 6'd9;
						end
							brick_to_clear_x <= ram_out[8:0];
							brick_to_clear_y <= ram_out[16:9];
							info_of_collided_brick <= {ram_out[27:26] - 1'b1, 9'b0, ram_out[16:0]};
							actually_collides <= 1'b1;
							collision_level <= ram_out[27:26];
							address_of_collision <= ram_address;
//						end
					end
				end
			end
			else if (~enable_brick_erase & ~enable_black_brick & ~actually_erase) // Preserves the values of the actually_collides value.
				actually_collides = 1'b0;
		end
	end
endmodule

