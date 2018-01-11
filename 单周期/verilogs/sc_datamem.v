module sc_datamem (addr, datain, dataout, we, clock, mem_clk, dmem_clk, io_bus_in, io_bus_out);

   input  [31:0]  addr;
   input  [31:0]  datain;
   input          we, clock, mem_clk;
   input  [12:0]   io_bus_in;
   output [31:0]  dataout;
   output         dmem_clk;
   output [44:0]  io_bus_out;

   wire           dmem_clk, dram_write_enable, io_write_enable;
   wire   [31:0]  mem_out, io_out;

   assign         dram_write_enable = we & ~clock & ~addr[7];
   assign         io_write_enable = we & ~clock & addr[7];
   assign         dmem_clk = mem_clk & ( ~ clock);
   assign         dataout = addr[7] ? io_out : mem_out;

   dmem  dataram(addr[6:2], dmem_clk, datain, dram_write_enable, mem_out);
   simple_io io(addr[6:2], dmem_clk, datain, io_write_enable, io_out, io_bus_in, io_bus_out);
endmodule
