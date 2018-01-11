module sc_computer (resetn,clock,mem_clk,pc,inst,aluout,memout,imem_clk,dmem_clk, io_in, io_out);

   input         resetn,clock,mem_clk;
   input  [12:0]  io_in;
   output [31:0] pc,inst,aluout,memout;
   output        imem_clk,dmem_clk;
   output [44:0] io_out;
   wire   [31:0] data;
   wire          wmem; // all these "wire"s are used to connect or interface the cpu,dmem,imem and so on.

   sc_cpu cpu (clock,resetn,inst,memout,pc,wmem,aluout,data);          // CPU module.
   sc_instmem  imem (pc,inst,clock,mem_clk,imem_clk);                  // instruction memory.
   sc_datamem  dmem (aluout,data,memout,wmem,clock,mem_clk,dmem_clk,io_in,io_out); // data memory.

endmodule
