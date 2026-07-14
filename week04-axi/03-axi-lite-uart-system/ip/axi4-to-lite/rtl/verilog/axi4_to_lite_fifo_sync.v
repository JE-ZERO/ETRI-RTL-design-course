`ifndef AXI4_TO_LITE_FIFO_SYNC_V
`define AXI4_TO_LITE_FIFO_SYNC_V
//------------------------------------------------------------------------------
// Copyright (c) by Ando Ki
// All right reserved.
//------------------------------------------------------------------------------
// fifo_sync.v
//------------------------------------------------------------------------------
// Synchronous FIFO
//------------------------------------------------------------------------------
// VERSION: 2023.03.14.
//------------------------------------------------------------------------------
// MACROS and PARAMETERS
//     FDW: bit-width of data
//     FAW: num of entries in power of 2
//------------------------------------------------------------------------------
// Features
//    * ready-valid handshake protocol
//------------------------------------------------------------------------------
//    * data moves when both ready(rdy) and valid(vld) is high.
//    * ready(rdy) means the receiver is ready to accept data.
//    * valid(vld) means the data is valid on 'data'.
//------------------------------------------------------------------------------
//               __     ___     ___     ___     ___
//   clk           |___|   |___|   |___|   |___|
//               _______________________________
//   wr_rdy     
//                      _______________ 
//   wr_vld      ______|       ||      |___________  
//                      _______  ______
//   wr_din      XXXXXXX__D0___XX__D1__XXXX
//               ______________                 ___
//   empty                     |_______________|
//                              _______________ 
//   rd_rdy      ______________|               |___
//                              _______________
//   rd_vld      ______________|       ||      |___
//                              ________ _______
//   rd_dout     XXXXXXXXXXXXXXX__D0____X__D1___XXXX
//
//   full        __________________________________________
//                     |       |
//                     |<----->|
//                     one-cycle delay
//------------------------------------------------------------------------------

module axi4_to_lite_fifo_sync
     #(parameter FDW =32  // fifo data width
               , FAW =10) // num of entries in 2 to the power FAW
(
       input   wire           rstn// asynchronous reset (active low)
     , input   wire           clr // synchronous reset (active high)
     , input   wire           clk
     , output  wire           wr_rdy
     , input   wire           wr_vld
     , input   wire [FDW-1:0] wr_din
     , input   wire           rd_rdy
     , output  wire           rd_vld
     , output  wire [FDW-1:0] rd_dout
     , output  wire           full
     , output  wire           empty
     , output  reg  [FAW:0]   items // num of elements in the FIFO to be read
     , output  wire [FAW:0]   rooms // num of rooms in the FIFO to be written
);
   //---------------------------------------------------
   localparam FDT = 1<<FAW;
   //---------------------------------------------------
   reg  [FAW:0]   bram_head={FAW{1'b0}}; // where data to be read (filled room)
   reg  [FAW:0]   bram_tail={FAW{1'b0}}; // where data to be written (empty room)
   wire [FAW:0]   bram_next=bram_head+1;
   wire [FAW-1:0] bram_addr_wr=bram_tail[FAW-1:0];
   wire [FAW-1:0] bram_addr_rd=(rd_vld&rd_rdy) ? bram_next[FAW-1:0]
                                               : bram_head[FAW-1:0];
   //---------------------------------------------------
   reg  [FDW-1:0] bram_dout;
   wire           bram_empty=(bram_head==bram_tail);
   wire           bram_full =(bram_head[FAW]^bram_tail[FAW])&&
                             (bram_head[FAW-1:0]==bram_tail[FAW-1:0]);
   //---------------------------------------------------
   assign  empty   = bram_empty;
   assign  full    = bram_full;
   assign  wr_rdy  =~full;
   assign  rooms   = FDT-items;
   assign  rd_vld  =~empty;
   //---------------------------------------------------
   // accept input at bram_tail.
   //  - push data item into the entry pointed by bram_tail
   // provide output at bram_head.
   //  - pop data item from the entry pointed by bram_head
   always @ (posedge clk or negedge rstn) begin
      if (rstn==1'b0) begin
          bram_tail     <=  'h0;
          bram_head     <=  'h0;
          items         <=  'h0;
      end else if (clr==1'b1) begin
          bram_tail     <=  'h0;
          bram_head     <=  'h0;
          items         <=  'h0;
      end else begin
          if ((rd_vld&rd_rdy)&~(wr_vld&wr_rdy)) begin
              // read only
              items     <= items - 1;
              bram_head <= bram_head + 1;
          end else if (~(rd_vld&rd_rdy)&(wr_vld&wr_rdy)) begin
              // write only ==> write to bram since rd_dout has value
              items     <= items + 1;
              bram_tail <= bram_tail + 1;
          end else if ((rd_vld&rd_rdy)&(wr_vld&wr_rdy)) begin
              // both read and write
              bram_head <= bram_head + 1;
              bram_tail <= bram_tail + 1;
          end
      end
   end
   //---------------------------------------------------
   // RAM_STYLE instructs the Vivado synthesis tool on how to infer memory.
   // Accepted values are:
   // * block: Instructs the tool to infer RAMB type components.
   // * distributed: Instructs the tool to infer the LUT RAMs.
   // * registers: Instructs the tool to infer registers instead of RAMs.
   // * ultra: Instructs the tool to use the UltraScale+™ URAM primitives.
   // * mixed: Instructs the tool to infer a combination of RAM types designed
   //          to minimize the amount of space that is unused.
   (* ram_style = "block" *) reg [FDW-1:0] Mem [0:FDT-1];
   reg  [FDW-1:0] mem_dout;

   always @ (posedge clk ) begin
     if (wr_rdy & wr_vld) begin
         Mem[bram_addr_wr] <= wr_din;
     end
     mem_dout <= Mem[bram_addr_rd];
   end // always
   //---------------------------------------------------
   // To make it write-through.
   reg [FDW-1:0] bram_data_sav='h0;
   reg           bram_data_vld=1'b0;
   always @ ( posedge clk ) begin
      if ((wr_rdy&wr_vld)&&(bram_addr_wr==bram_addr_rd)) begin
          bram_data_sav <= wr_din;
          bram_data_vld <= 1'b1;
      end else begin
          if (rd_rdy&rd_vld) bram_data_vld <= 1'b0;
      end
   end
   //---------------------------------------------------
   always @ ( * ) begin
      if (bram_data_vld) bram_dout = bram_data_sav;
      else bram_dout = mem_dout;
   end
   assign  rd_dout = bram_dout;
   //---------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2023.03.14: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
`endif
