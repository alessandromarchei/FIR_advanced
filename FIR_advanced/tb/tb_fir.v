//`timescale 1ns

module tb_fir ();

   parameter NBIT = 14;   

   wire CLK_i;
   wire RST_n_i;
   wire [13:0] DIN3k_i;
   wire [13:0] DIN3k1_i;
   wire [13:0] DIN3k2_i;   
   wire VIN_i;
   wire [13:0] H0_i;
   wire [13:0] H1_i;
   wire [13:0] H2_i;
   wire [13:0] H3_i;
   wire [13:0] H4_i;
   wire [13:0] H5_i;
   wire [13:0] H6_i;
   wire [13:0] H7_i;
   wire [13:0] H8_i;
   wire [13:0] H9_i;
   wire [13:0] H10_i;
   wire [13:0] DOUT3k_i;
   wire [13:0] DOUT3k1_i;
   wire [13:0] DOUT3k2_i;   
   wire VOUT_i;
   wire END_SIM_i;

   clk_gen CG(.END_SIM(END_SIM_i),
  	      .CLK(CLK_i),
	      .RST_n(RST_n_i));

   data_maker #(.NBIT(NBIT)) SM(.CLK(CLK_i),
				.RST_n(RST_n_i),
				.VOUT(VIN_i),
				.DOUT3k(DIN3k_i),
				.DOUT3k1(DIN3k1_i),
				.DOUT3k2(DIN3k2_i),				
				.B0(H0_i),
				.B1(H1_i),
				.B2(H2_i),
				.B3(H3_i),
				.B4(H4_i),
				.B5(H5_i),
				.B6(H6_i),
				.B7(H7_i),
				.B8(H8_i),
				.B9(H9_i),
				.B10(H10_i),
				.END_SIM(END_SIM_i));

   FIR_adv UUT(.CLK(CLK_i),
				.RST_n(RST_n_i),
				.DIN3k(DIN3k_i),
				.DIN3k1(DIN3k1_i),
				.DIN3k2(DIN3k2_i),		
				.VIN(VIN_i),
				.B0(H0_i),
				.B1(H1_i),
				.B2(H2_i),
				.B3(H3_i),
				.B4(H4_i),
				.B5(H5_i),
				.B6(H6_i),
				.B7(H7_i),
				.B8(H8_i),
				.B9(H9_i),
				.B10(H10_i),
				.DOUT3k(DOUT3k_i),
				.DOUT3k1(DOUT3k1_i),
				.DOUT3k2(DOUT3k2_i),		
				.VOUT(VOUT_i)); 

   data_sink #(.NBIT(NBIT)) DS(.CLK(CLK_i),
			       .RST_n(RST_n_i),
			       .VIN(VOUT_i),
			       .DIN3k(DOUT3k_i),
			       .DIN3k1(DOUT3k1_i),
			       .DIN3k2(DOUT3k2_i));

endmodule

		   
