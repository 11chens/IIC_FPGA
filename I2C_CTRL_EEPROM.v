module I2C_CTRL_EEPROM(
	input	wire	clk,
	input	wire	rst_n,
	input	wire	i2c_start,
	input	wire	[7:0]	wr_dev,
	input	wire	[7:0]	rd_dev,
	input	wire	[7:0]	addh,
	input	wire	[7:0]	addl,
	input	wire	[7:0]	wr_data,
	input	wire	[7:0]	rd_data,
	input	wire	rd_flag,

	inout	wire	SDA,
	output	wire	SCL,	

	output	reg		i2c_done
);
	
	parameter	I2C_FREQ	=	250;//	50M/250=200KHZ

	localparam	IDLE		=	'd15;

	localparam	START		=	'd0;
	localparam	WR_CTRL		=	'd1;
	localparam	WR_CTRL_ACK	=	'd2;
	localparam	HADDR		=	'd3;
	localparam	HD_ACK		=	'd4;
	localparam	LADDR		=	'd5;
	localparam	LD_ACK		=	'd6;
	localparam	WR_DAT		=	'd7;
	localparam	WR_DAT_ACK	=	'd8;

	localparam	RD_START	=	'd9;
	localparam	RD_CTRL		=	'd10;
	localparam	RD_CTRL_ACK	=	'd11;
	localparam	RD_DAT		=	'd12;
	localparam	NOACK		=	'd13;

	localparam	STOP		=	'd14;

	wire high_flag,low_flag;
	wire wait_input;
	reg	[4:0]state;
	reg	r_sda,r_scl;
	reg [7:0]clk_cnt;
	reg [4:0]trcnt;


	always @(posedge clk or negedge rst_n) 
		if (!rst_n) begin
			clk_cnt<=8'd0;	
		end
		else if (clk_cnt==I2C_FREQ-1) begin
			clk_cnt<=8'd0;	
		end
		else begin
			clk_cnt<=clk_cnt+1'd1;	
		end

	always @(posedge clk or negedge rst_n) 
		if (!rst_n) begin
			r_scl<=1'b0;	
		end
		else if (clk_cnt==I2C_FREQ/4-1) begin
			r_scl<=1'b1;	
		end
		else if (clk_cnt==I2C_FREQ*3/4-1) begin
			r_scl<=1'b0;	
		end
		else begin
			r_scl<=r_scl;
		end

	assign high_flag = (clk_cnt==I2C_FREQ/2-1)?	1'b1:1'b0;
	assign low_flag = (clk_cnt==I2C_FREQ/I2C_FREQ-1)? 1'b1:1'b0;

	assign wait_input = (state==WR_CTRL_ACK || state==HD_ACK || state==LD_ACK 
					|| state==WR_DAT_ACK || state==RD_CTRL_ACK)? 1'b1:1'b0;

	assign SDA = (wait_input==1'b1)?1'bz:r_sda;//((r_sda)?1'bz:1'b0)
	assign SCL = r_scl;

	always @(posedge clk or negedge rst_n) 
		if (!rst_n) begin
			state<=IDLE;
			r_sda<=1'b1;
			trcnt<=4'd0;
			i2c_done<=1'b0;
		end
		else begin
			case(state)
				IDLE:begin
					i2c_done<=1'b0;
					if (i2c_start) begin
						state<=START;
					end
					else begin
						state<=IDLE;
					end
				end
//********************WRITE BEGIN********************//
				START:begin
					if (high_flag) begin
						r_sda<=1'b0;
						state<=WR_CTRL;
					end
					else begin
						state<=START;
					end
				end

				WR_CTRL:begin
					if (low_flag) begin
						if (trcnt<4'd8) begin
							r_sda<=wr_dev[4'd7-trcnt];
							trcnt<=trcnt+1'd1;
						end
						else begin
							trcnt<=4'd0;
							state<=WR_CTRL_ACK;
							r_sda<=1'b0;
						end
					end
					else begin
						state<=WR_CTRL;
					end
				end

				WR_CTRL_ACK:begin
					if (high_flag) begin
						if (!SDA) begin
							state<=HADDR;
						end
						else begin
							state<=IDLE;
						end
					end
					else begin
						state<=WR_CTRL_ACK;
					end
				end

				HADDR:begin
					if(low_flag)begin
						if (trcnt<4'd8) begin
							r_sda<=addh[4'd7-trcnt];
							trcnt<=trcnt+1'd1;
						end
						else begin
							trcnt<=4'd0;
							state<=HD_ACK;
							r_sda<=1'b0;
						end
					end
					else begin
						state<=HADDR;
					end
				end

				HD_ACK:begin
					if (high_flag) begin
						if (!SDA) begin
							state<=LADDR;
						end
						else begin
							state<=IDLE;
						end
					end
					else begin
						state<=HD_ACK;
					end
				end

				LADDR:begin
					if(low_flag)begin
						if (trcnt<4'd8) begin
							r_sda<=addl[4'd7-trcnt];
							trcnt<=trcnt+1'd1;
						end
						else begin
							trcnt<=4'd0;
							state<=LD_ACK;
							r_sda<=1'b0;
						end
					end
					else begin
						state<=LADDR;
					end
				end

				LD_ACK:begin
					if (high_flag) begin
						if (!SDA) begin
							state<=WR_DAT;
						end
						else begin
							state<=IDLE;
						end
					end
					else begin
						state<=LD_ACK;
					end
				end

				WR_DAT:begin
					if(low_flag)begin
						if (trcnt<4'd8) begin
								r_sda<=wr_data[4'd7-trcnt];
								trcnt<=trcnt+1'd1;
						end
						else begin
								trcnt<=4'd0;
								state<=WR_DAT_ACK;
								r_sda<=1'b0;
						end
					end
					else begin
						state<=WR_DAT;
					end
				end

				WR_DAT_ACK:begin
					if (high_flag) begin
						if (!SDA) begin
							if (!rd_flag) begin
								r_sda<=1'b0;
								state<=STOP;	//******WRITE******//
							end
							else begin
								r_sda<=1'b1;
								state<=RD_START;//******READ******//
							end
						end
						else begin
							state<=IDLE;
						end
					end
					else begin
						state<=WR_DAT_ACK;
					end
				end

//********************READ BEGIN********************//

				RD_START:begin
					if (high_flag) begin
						r_sda<=1'b0;
						state<=RD_CTRL;
					end
					else begin
						state<=RD_START;
					end
				end

				RD_CTRL:begin
					if(low_flag)begin
						if (trcnt<4'd8) begin
							r_sda<=rd_dev[4'd7-trcnt];
							trcnt<=trcnt+1'd1;
						end
						else begin
							trcnt<=4'd0;
							state<=RD_CTRL_ACK;
							r_sda<=1'b0;
						end
					end
					else begin
						state<=WR_DAT;
					end
				end

				RD_CTRL_ACK:begin
					if (high_flag) begin
						if (!SDA) begin
							state<=RD_DAT;
						end
						else begin
							state<=IDLE;
						end
					end
					else begin
						state<=RD_CTRL_ACK;
					end
				end

				RD_DAT:begin
					if(low_flag)begin
						if (trcnt<4'd8) begin
							r_sda<=rd_data[4'd7-trcnt];
							trcnt<=trcnt+1'd1;
						end
						else begin
							trcnt<=4'd0;
							state<=NOACK;
							r_sda<=1'b0;
						end
					end
					else begin
						state<=WR_DAT;
					end
				end

				NOACK:begin
					if (high_flag) begin
						state<=STOP;
					end
					else begin
						state<=NOACK;
					end
				end
				
//********************READ OVER********************//

//********************WRITE & READ STOP********************//
				STOP:begin
					if (high_flag) begin
						r_sda<=1'b1;
						i2c_done<=1'b1;
						state<=IDLE;
					end
					else begin
						state<=STOP;
					end
				end

				default:begin
					state<=IDLE;
				end

			endcase
		end

endmodule




