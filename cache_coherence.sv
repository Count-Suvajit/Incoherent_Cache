`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns/1ps

module cache_coherence_top;

  reg clk;
  reg rstn;

  reg [7:0] host2cache_address1;
  reg host2cache_write1;
  reg host2cache_valid1;
  reg [7:0] host2cache_rdata1;
  reg [7:0] host2cache_wdata1;
  reg cache2host_busy1;

  reg [7:0] host2cache_address2;
  reg host2cache_write2;
  reg host2cache_valid2;
  reg [7:0] host2cache_rdata2;
  reg [7:0] host2cache_wdata2;
  reg cache2host_busy2;

  reg mem2cache_transfer_done1;
  reg [7:0] cache2mem_wdata1;
  reg [7:0] cache2mem_rdata1;
  reg [7:0] cache2mem_address1;
  reg cache2mem_write1;
  reg cache2mem_valid1;

  reg mem2cache_transfer_done2;
  reg [7:0] cache2mem_wdata2;
  reg [7:0] cache2mem_rdata2;
  reg [7:0] cache2mem_address2;
  reg cache2mem_write2;
  reg cache2mem_valid2;

  reg mem2cache_transfer_done;
  reg [7:0] cache2mem_wdata;
  reg [7:0] cache2mem_rdata;
  reg [7:0] cache2mem_address;
  reg cache2mem_write;
  reg cache2mem_valid;

  bit test_done1,test_done2;

  cache_bfm bfm_inst1(.cache2host_busy(cache2host_busy1),.host2cache_rdata(host2cache_rdata1),.host2cache_wdata(host2cache_wdata1),.host2cache_address(host2cache_address1),.host2cache_write(host2cache_write1),.host2cache_valid(host2cache_valid1),.test_done(test_done1),.*);

  defparam bfm_inst1.id=1;

  cache_bfm bfm_inst2(.cache2host_busy(cache2host_busy2),.host2cache_rdata(host2cache_rdata2),.host2cache_wdata(host2cache_wdata2),.host2cache_address(host2cache_address2),.host2cache_write(host2cache_write2),.host2cache_valid(host2cache_valid2),.test_done(test_done2));

  defparam bfm_inst2.id=2;

  cache cache_inst1(.host2cache_address(host2cache_address1),.host2cache_write(host2cache_write1),.host2cache_valid(host2cache_valid1),.host2cache_wdata(host2cache_wdata1),.host2cache_rdata(host2cache_rdata1),.cache2host_busy(cache2host_busy1),.mem2cache_transfer_done(mem2cache_transfer_done1),.cache2mem_wdata(cache2mem_wdata1),.cache2mem_rdata(cache2mem_rdata1),.cache2mem_address(cache2mem_address1),.cache2mem_write(cache2mem_write1),.cache2mem_valid(cache2mem_valid1),.*);

  cache cache_inst2(.host2cache_address(host2cache_address2),.host2cache_write(host2cache_write2),.host2cache_valid(host2cache_valid2),.host2cache_wdata(host2cache_wdata2),.host2cache_rdata(host2cache_rdata2),.cache2host_busy(cache2host_busy2),.mem2cache_transfer_done(mem2cache_transfer_done2),.cache2mem_wdata(cache2mem_wdata2),.cache2mem_rdata(cache2mem_rdata2),.cache2mem_address(cache2mem_address2),.cache2mem_write(cache2mem_write2),.cache2mem_valid(cache2mem_valid2),.*);

  memory_access_arbiter mem_arb(.*);

  memory_responder #(10) mem_inst(.*);

  initial begin
	  $fsdbDumpfile("novas.fsdb");
	  $fsdbDumpvars("+all");
          $fsdbDumpvars("+parameter");
	  $fsdbDumpon;
  end

  initial begin
	  fork
		  wait(test_done1);
		  wait(test_done2);
	  join
	  $finish();
  end

endmodule : cache_coherence_top

module memory_access_arbiter(
  input clk,
  input rstn,

  input [7:0] cache2mem_address1,
  input [7:0] cache2mem_wdata1,
  input cache2mem_write1,
  input cache2mem_valid1,
  output mem2cache_transfer_done1,
  output [7:0] cache2mem_rdata1,

  input [7:0] cache2mem_address2,
  input [7:0] cache2mem_wdata2,
  input cache2mem_write2,
  input cache2mem_valid2,
  output mem2cache_transfer_done2,
  output [7:0] cache2mem_rdata2,

  input mem2cache_transfer_done,
  input [7:0] cache2mem_rdata,
  output reg [7:0] cache2mem_wdata,
  output reg [7:0] cache2mem_address,
  output reg cache2mem_write,
  output reg cache2mem_valid  

);

  reg sel;
  reg mem2cache_transfer_done_r;
  reg mem2cache_transfer_in_progress;

  always @(negedge rstn) begin
	  sel = 1;
	  mem2cache_transfer_in_progress = 0;
  end

  always @(posedge clk) begin
	  mem2cache_transfer_done_r <= mem2cache_transfer_done;
	  if(~mem2cache_transfer_in_progress) begin
		  mem2cache_transfer_in_progress <= 1;
		  if(cache2mem_valid1 && cache2mem_valid2) begin
			  sel <= ~sel;
		  end
		  else if (cache2mem_valid1) begin
			  sel <= 0;
		  end
		  else if (cache2mem_valid2) begin
			  sel <= 1;
		  end
	  end
	  if(mem2cache_transfer_in_progress) begin
		  if(~mem2cache_transfer_done && mem2cache_transfer_done_r) begin
			  mem2cache_transfer_in_progress <= 0;
		  end
	  end
  end

  assign mem2cache_transfer_done1 = sel==0 ? mem2cache_transfer_done : 0;
  assign mem2cache_transfer_done2 = sel==1 ? mem2cache_transfer_done : 0;

  assign cache2mem_rdata1 = cache2mem_rdata;
  assign cache2mem_rdata2 = cache2mem_rdata;

  assign cache2mem_address = sel==0 ? cache2mem_address1 : cache2mem_address2;
  assign cache2mem_wdata = sel==0 ? cache2mem_wdata1 : cache2mem_wdata2;
  assign cache2mem_write = sel==0 ? cache2mem_write1 : cache2mem_write2;
  assign cache2mem_valid = sel==0 ? cache2mem_valid1 : cache2mem_valid2;

endmodule : memory_access_arbiter

//256 locations, byte addressable
//16 locations in cache.
//Direct mapped
//[7:4] needs to be stored as tag bits
module cache(
  input clk,
  input rstn,
  input [7:0] host2cache_address,
  input host2cache_write,
  input host2cache_valid,
  input [7:0] host2cache_wdata,
  output reg [7:0] host2cache_rdata,
  output reg cache2host_busy,

  input mem2cache_transfer_done,
  input [7:0] cache2mem_rdata,
  output reg [7:0] cache2mem_wdata,
  output reg [7:0] cache2mem_address,
  output reg cache2mem_write,
  output reg cache2mem_valid
);

  //[15]=Modified, [14]=Exclusive, [13]=Shared [12]=valid_bit, [11:8]=Tag bit direct mapping, [7:0]=data
  reg [15:0] reg_bank[16];

  reg cache_miss;

  reg mem_read_busy;

  reg mem_write_busy;
  reg [7:0] mem_write_data;
  reg [7:0] mem_write_address;

  reg [17:0] cache2mem_access_buffer; //Bit-17 : Valid, Bit-16 : Write/Read, Bit-[15:8] : Data, Bit-[7:0] : Address

  always @(negedge rstn) begin
	  cache_miss = 0;
	  mem_read_busy = 0;
	  mem_write_busy = 0;
	  foreach(reg_bank[i]) begin
		  reg_bank[i] = 0;
	  end
	  cache2mem_access_buffer = 18'h0;
	  cache2host_busy = 0;
  end

  always @(posedge clk) begin
	  if(host2cache_valid && ~cache2host_busy) begin
	       cache2host_busy <= 1;
               if(host2cache_write) begin
		       if(reg_bank[host2cache_address[3:0]][11:8] == host2cache_address[7:4] && reg_bank[host2cache_address[3:0]][12]) begin
			       reg_bank[host2cache_address[3:0]][7:0] <= host2cache_wdata;
		       end
		       else begin
			       cache_miss <= 1;
			       //do mem_read & write
			       cache2mem_access_buffer <= {1'b1,host2cache_write,host2cache_wdata,host2cache_address[7:0]};
		       end
	       end
	       else begin
		       if(reg_bank[host2cache_address[3:0]][11:8] == host2cache_address[7:4] && reg_bank[host2cache_address[3:0]][12]) begin
			       host2cache_rdata <= reg_bank[host2cache_address[3:0]][7:0];
		       end
		       else begin
			       cache_miss <= 1;
			       //do mem_read & read
			       cache2mem_access_buffer <= {1'b1,host2cache_write,8'h0,host2cache_address[7:0]};
		       end
	       end
	  end
	  if(mem2cache_transfer_done) begin
		  if(host2cache_write) begin
			  reg_bank[host2cache_address[3:0]][7:0] <= host2cache_wdata;
		  end
		  else begin
			  reg_bank[host2cache_address[3:0]][7:0] <= cache2mem_rdata;
			  host2cache_rdata <= cache2mem_rdata;
		  end
		  reg_bank[host2cache_address[3:0]][12] <= 1;
		  reg_bank[host2cache_address[3:0]][11:8] <= host2cache_address[7:4];
		  cache_miss <= 0;
	  end
	  if(host2cache_valid && ~cache_miss && cache2host_busy) begin
	       cache2host_busy <= 0;
	  end
  end

  always @(posedge clk) begin
	  if(cache2mem_access_buffer[17]) begin
		  if(~cache2mem_access_buffer[16]) begin
			if(~mem2cache_transfer_done) begin
				cache2mem_address <= cache2mem_access_buffer[7:0];
				cache2mem_write <= 0;
				cache2mem_valid <= 1;
			end
			if(mem2cache_transfer_done) begin
				cache2mem_valid <= 0;
				cache2mem_access_buffer[17] <= 0;
			end
		  end
		  else begin
			if(~mem2cache_transfer_done) begin
				cache2mem_address <= cache2mem_access_buffer[7:0];
				cache2mem_wdata <= cache2mem_access_buffer[15:8];			  
				cache2mem_write <= 1;
				cache2mem_valid <= 1;
			end
			if(mem2cache_transfer_done) begin
				cache2mem_valid <= 0;
				cache2mem_access_buffer[17] <= 0;
			end
		  end
	  end
  end


endmodule : cache

module memory_responder #(parameter MEMORY_LATENCY = 20)
(
  input clk,
  input rstn,

  input [7:0] cache2mem_address,
  input cache2mem_write,
  input cache2mem_valid,
  input [7:0] cache2mem_wdata,
  output reg [7:0] cache2mem_rdata,
  output reg mem2cache_transfer_done

);

  reg [7:0] mem[256];

  reg [3:0] counter;

  always @(negedge rstn) begin
	  foreach(mem[i]) begin
		  mem[i] = i;
	  end
	  mem2cache_transfer_done = 0;
	  counter = 0;
  end

  always @(posedge clk) begin
	  if(cache2mem_valid) begin
		  counter<=counter+1;
		  if(counter==MEMORY_LATENCY) begin
			  if(cache2mem_write) begin
				  mem[cache2mem_address] <= cache2mem_wdata;
			  end
			  else begin
				  cache2mem_rdata <= mem[cache2mem_address];
			  end
			  mem2cache_transfer_done <= 1;
		  end
	  end
	  else if(mem2cache_transfer_done) begin
		  mem2cache_transfer_done <= 0;
		  counter <= 0;
	  end
  end

endmodule : memory_responder

program cache_bfm(
  input cache2host_busy,
  input [7:0] host2cache_rdata,
  output reg clk,
  output reg rstn,
  output reg [7:0] host2cache_wdata,
  output reg [7:0] host2cache_address,
  output reg host2cache_write,
  output reg host2cache_valid,
  output bit test_done
);

  parameter [1:0] id=1;

  initial begin
	  clk = 0;
	  forever begin
		  #1 clk <= !clk;
	  end
  end

  task automatic apply_reset();
      `uvm_info("apply_reset", "TASK BEGIN", UVM_MEDIUM)
      rstn <= 0;
      repeat(2) begin
	      @(posedge clk);
      end
      rstn <= 1;
      `uvm_info("apply_reset", "TASK END", UVM_MEDIUM)
  endtask : apply_reset

  task automatic do_read(input bit [7:0] address_read);
      `uvm_info("do_read", "TASK BEGIN", UVM_MEDIUM)
      @(posedge clk);
      host2cache_address <= address_read;
      host2cache_write <= 0;
      host2cache_valid <= 1;
      do begin
	      @(posedge clk);
      end while(cache2host_busy);
      host2cache_valid <= 0;
      `uvm_info("do_read", "TASK END", UVM_MEDIUM)
  endtask : do_read

  task automatic do_write(input bit [7:0] address_write, input bit [7:0] write_data);
      `uvm_info("do_write", $sformatf("TASK BEGIN address : 'h%0h, data : 'h%0h",address_write,write_data), UVM_MEDIUM)
      @(posedge clk);
      host2cache_address <= address_write;
      host2cache_wdata <= write_data;
      host2cache_write <= 1;
      host2cache_valid <= 1;
      do begin
	      @(posedge clk);
      end while(cache2host_busy);
      host2cache_valid <= 0;
      `uvm_info("do_write", "TASK END", UVM_MEDIUM)
  endtask : do_write

  initial begin
	  apply_reset;
	  do_read('h53);
	  do_read('h53);
	  do_write('h53,$urandom()/id);
	  do_read('h53);
	  do_read('h53);
	  test_done=1;	  
  end

endprogram : cache_bfm
