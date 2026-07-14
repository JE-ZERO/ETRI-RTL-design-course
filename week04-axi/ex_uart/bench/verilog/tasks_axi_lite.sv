
task axi_lite_write;
     input integer addr;
     input integer data;
begin
    fork begin
        m_axi_lite_awaddr = addr;
        m_axi_lite_awvalid = 1'b1;
        @ (posedge aclk);
        while (m_axi_lite_awready==1'b0) @ (posedge aclk);
        m_axi_lite_awvalid = 1'b0;
    end

    begin
        m_axi_lite_wdata = data;
        m_axi_lite_wvalid = 1'b1;
        @ (posedge aclk);
        while (m_axi_lite_wready==1'b0) @ (posedge aclk);
        m_axi_lite_wvalid = 1'b0;
    end

    begin
        m_axi_lite_bready = 1'b1;
        @ (posedge aclk);
        while (m_axi_lite_bvalid==1'b0) @ (posedge aclk);
        m_axi_lite_bready = 1'b0;
        if(m_axi_lite_bresp!=2'b00) $display("%m ERROR BRESP 0x0X", m_axi_lite_bresp);
    end
    join   
   //                __    __    __    __    __    __    __    __
   //  aclk       __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |
   //                ________   |     |
   //  awaddr[]   XXX________   |     |
   //                ______     |     |
   //  awvalid    __/      \    |     |
   //             ____________  |     |
   //  awready    __/      \___ |     |
   //                           |     |
   //                ________   |     |
   //   wdata[]   XXX________   |     |
   //                ______     |     |
   //   wvalid    __/      \    |     |
   //             ____________  |     |
   //   wready    __/      \___ |     |
   //                           |     |
   //                           |_____|__
   //   bresp[]               XXX________
   //                            ______
   //   bvalid                __/      \__
   //              ________________________
   //   bready     _/                  \___

end
endtask

task axi_lite_read;
     input  integer addr;
     output integer data;
begin
    fork begin
        m_axi_lite_araddr = addr;
        m_axi_lite_arvalid = 1'b1;
        @ (posedge aclk);
        while (m_axi_lite_arready==1'b0) @ (posedge aclk);
        m_axi_lite_arvalid = 1'b0;
    end

    begin
        m_axi_lite_rready = 1'b1;
        @ (posedge aclk);
        while (m_axi_lite_rvalid==1'b0) @ (posedge aclk);
        m_axi_lite_rready = 1'b0;
        if(m_axi_lite_rresp!=2'b00) $display("%m ERROR RRESP 0x%0X", m_axi_lite_rresp);
        data = m_axi_lite_rdata;
    end
    join
   //                __    __    __    __    __    __    __    __
   //  aclk       __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |
   //                ________   |     |
   //  araddr[]   XXX________   |     |
   //                ______     |     |
   //  arvalid    __/      \    |     |
   //             ____________  |     |
   //  arready    __/      \___ |     |
   //                           |     |
   //                            ________   |     |
   //   rdata[]               XXX________   |     |
   //                            ________   |     |
   //   rresp[]               XXX________   |     |
   //                            ______     |     |
   //   rvalid                __/      \    |     |
   //             ________________________  |     |
   //   rready    __/                  \___ |     |
   //                                  

end
endtask

