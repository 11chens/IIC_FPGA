`timescale 1ns/1ps
`define clk_period 20


module iic_ctrl_tb ;
	
	reg	clk;
	reg	rst_n;
	reg	i2c_start;
	reg	[7:0]	wr_dev;
	reg	[7:0]	rd_dev;
	reg	[7:0]	addh;
	reg	[7:0]	addl;
	reg	[7:0]	wr_data;
	reg	[7:0]	rd_data;
	reg	rd_flag;

	wire	i2c_done;
	wire 	[4:0]c_state;
	
	wire	SDA;
	wire	SCL;	
	pullup(SDA);
	
	wire wt;
	
	I2C_CTRL_EEPROM	I2C_CTRL_EEPROM(
		.clk(clk),
		.rst_n(rst_n),
		.i2c_start(i2c_start),
		.wr_dev(wr_dev),
		.rd_dev(rd_dev),
		.addh(addh),
		.addl(addl),
		.wr_data(wr_data),
		.rd_data(rd_data),
		.rd_flag(rd_flag),
		.SDA(SDA),
		.SCL(SCL),
		.c_state(c_state),	
		.i2c_done(i2c_done)
	);
	
	
	initial clk=1;
	always#(`clk_period/2)clk=~clk;
	
	assign wt = (c_state=='d2 || c_state=='d4 || c_state=='d6 
					|| c_state=='d8 || c_state=='d11)? 1'b1:1'b0;

	assign SDA = (wt==1'b1)?1'b0:1'bz;

	initial begin
		rst_n=1'b0;
		i2c_start=1'b0;
		wr_dev=8'ha0;
		addh=8'h12;
		addl=8'h34;
		wr_data=8'haa;	
		rd_dev=8'ha1;
		rd_flag=1'b0;
		rd_data=8'hcc;	

		#200;
		rst_n=1'b1;
		#201;
		
		addh=8'h12;
		addl=8'h34;
		wr_data=8'haa;		
		
		i2c_start=1'b1;
		#20;
		i2c_start=1'b0;	
		
		wait(i2c_done);
		
		#20000;
		//read
		rd_dev=8'ha1;
		rd_flag=1'b1;
		addh=8'h56;
		addl=8'h78;	
		rd_data=8'hcc;
		
		i2c_start=1'b1;
		#20;
		i2c_start=1'b0;
		
		wait(i2c_done);	
		
		#2000;
		$stop;
	end

endmodule
