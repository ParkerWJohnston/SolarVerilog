module FPGATOP(input [3:0]GPIO_1, 
					input [0:0]SW, 
					input CLOCK_50, 
					input [0:0]KEY, 
					output[9:0]LEDR, 
					output [6:0]HEX0,
					output [6:0]HEX1,	
					output [6:0]HEX2,
					output [6:0]HEX3,
					output [6:0]HEX4,
					output [6:0]HEX5);

	reg [3:0]max;
	
	wire reset;
	assign reset = KEY[0];
	
	reg motorOn = 1;
	assign LEDR[0] = motorOn;
	assign LEDR[1] = motorOn;
	assign LEDR[2] = motorOn;
	assign LEDR[3] = motorOn;
	assign LEDR[4] = motorOn;
	assign LEDR[5] = motorOn;
	assign LEDR[6] = motorOn;
	assign LEDR[7] = motorOn;
	assign LEDR[8] = motorOn;
	assign LEDR[9] = motorOn;
	
	wire autoReset;
	assign autoReset = SW[0];
	
	reg [1:0]state = 0;
	reg [3:0]currentTime = 0;
	reg [3:0]maxTime = 0;
	reg [26:0]rateDivider50to1s = 50000000;
	reg [3:0]tenSecWait = 10;
	
	always@(posedge CLOCK_50) begin
		if(rateDivider50to1s == 0 & motorOn) begin
			rateDivider50to1s <= 50000000;
			
			if(currentTime == 10) begin
				currentTime <= 0;
			end
			else begin
				currentTime <= currentTime + 1;
			end
			
		end
		else begin
			rateDivider50to1s <= rateDivider50to1s - 1;
		end
	
		if(~reset) begin
			max <= 1;
			currentTime <= 0;
			maxTime <= 0;
			rateDivider50to1s <= 50000000;
			state <= 0;
			motorOn <= 1;
			tenSecWait <= 10;
		end
		
		if(state == 0) begin
			motorOn <= 1;
			if(GPIO_1 > max) begin
				max <= GPIO_1;
				maxTime <= currentTime;
			end
			if(currentTime == 10) begin
				state <= 1;
			end
		end
		
		else if(state == 1) begin
			motorOn <= 1;
			if(currentTime == maxTime) begin
				state <= 2;
			end
			else if(GPIO_1 > max) begin
				state <= 0;
				max <= GPIO_1;
				maxTime <= currentTime;
				currentTime <= 0;
			end
		end
		
		else if(state == 2) begin
			motorOn <= 0;
			if(autoReset == 1) begin
				if(rateDivider50to1s == 0) begin
					rateDivider50to1s <= 50000000;
					
					if(tenSecWait == 0) begin
						state <= 0;
						max <= 1;
						currentTime <= 0;
						maxTime <= 0;
						rateDivider50to1s <= 50000000;
						tenSecWait <= 10;
					end
					else begin
						tenSecWait <= tenSecWait - 1;
					end
					
				end
				else begin
					rateDivider50to1s <= rateDivider50to1s - 1;
				end
			end
		end
	end

	hex_decoder h0 (GPIO_1, HEX0);
	hex_decoder h1 (currentTime, HEX1);
	hex_decoder h2 (max, HEX2);
	hex_decoder h3 (maxTime, HEX3);
	hex_decoder h4 (state, HEX4);
	hex_decoder h5 (((state == 2 && autoReset == 1) ? tenSecWait : 4'hF), HEX5);
		
endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b111_1111;   
            default: segments = 7'b100_0000;
        endcase
endmodule
