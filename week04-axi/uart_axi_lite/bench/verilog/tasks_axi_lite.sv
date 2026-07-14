`ifndef TASKS_AXI_LITE_SV 
`define TASKS_AXI_LITE_SV 
//------------------------------------------------------------------------------
//  Copyright (c) 2024 by Ando Ki.
//  All right reserved.
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//------------------------------------------------------------------------------
// tasks_axi_lite.sv
//------------------------------------------------------------------------------
// VERSION: 2024.08.10.
//------------------------------------------------------------------------------
//  [MACROS]
//------------------------------------------------------------------------------
`define DL #(0.01)
//------------------------------------------------------------------------------
task axi_lite_write;
     input integer addr;
     input integer data;
begin
   fork begin
            m_axi_lite_awaddr  <= `DL addr;
            m_axi_lite_awvalid <= `DL 1'b1;
            @ (posedge aclk);
            while (m_axi_lite_awready==1'b0) @ (posedge aclk);
            m_axi_lite_awvalid <= `DL 1'b0;
        end
        begin
            m_axi_lite_wdata  <= `DL data;
            m_axi_lite_wvalid <= `DL 1'b1;
            @ (posedge aclk);
            while (m_axi_lite_wready==1'b0) @ (posedge aclk);
            m_axi_lite_wvalid <= `DL 1'b0;
        end
        begin
            m_axi_lite_bready <= `DL 1'b1;
            @ (posedge aclk);
            while (m_axi_lite_bvalid==1'b0) @ (posedge aclk);
            m_axi_lite_bready <= `DL 1'b0;
            if (m_axi_lite_bresp!=2'b00) $display("%m ERROR BRESP 0x%0X", m_axi_lite_bresp);
        end
   join
end
endtask
//------------------------------------------------------------------------------
task axi_lite_read;
     input  integer addr;
     output integer data;
begin
   fork begin
            m_axi_lite_araddr  <= `DL addr;
            m_axi_lite_arvalid <= `DL 1'b1;
            @ (posedge aclk);
            while (m_axi_lite_arready==1'b0) @ (posedge aclk);
            m_axi_lite_arvalid <= `DL 1'b0;
        end
        begin
            m_axi_lite_rready <= `DL 1'b1;
            @ (posedge aclk);
            while (m_axi_lite_rvalid==1'b0) @ (posedge aclk);
            m_axi_lite_rready <= `DL 1'b0;
            if (m_axi_lite_rresp!=2'b00) $display("%m ERROR RRESP 0x%0X", m_axi_lite_rresp);
            data = m_axi_lite_rdata;
        end
   join
end
endtask
//------------------------------------------------------------------------------
// Revision History
//
// 2024.08.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
`endif // TASKS_AXI_LITE_SV 
