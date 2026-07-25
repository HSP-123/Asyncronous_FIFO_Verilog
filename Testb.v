`timescale 1ns/1ps

module Testb;
    
    parameter DATA_WIDTH = 8, ADDR_WIDTH = 4;
    parameter PTR_WIDTH = 5; // only for gray
    
    //write pointer signals
    reg wclk; 
    reg rclk; 
    reg wrst_n;
    reg rrst_n;
    reg winc;
    wire [ADDR_WIDTH:0] rptr_gray_wclk; //from syncroniser
  
    wire [ADDR_WIDTH-1:0] waddr;
    wire wfull;
    wire [ADDR_WIDTH:0] wptr_gray;
    
    //read pointer signals
    reg rinc;
    wire [ADDR_WIDTH:0] wptr_gray_rclk; //from syncroniser
    
    wire [ADDR_WIDTH-1:0] raddr;
    wire [ADDR_WIDTH:0] rptr_gray;
    wire rempty;
    
    // FIFO signals
    wire wr_en = winc & !wfull;
    reg [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
//====================================================================================================
    //module instantiations
    
    wptr_handler #(.ADDR_WIDTH(ADDR_WIDTH)) Write(   
        .wclk(wclk),   
        .wrst_n(wrst_n), 
        .winc(winc), 
        .rptr_gray_wclk(rptr_gray_wclk), 
        
        .waddr(waddr), 
        .wptr_gray(wptr_gray), 
        .wfull(wfull)          
    );
    
    rptr_handler #(.ADDR_WIDTH(ADDR_WIDTH)) Read(   
        .rclk(rclk),   
        .rrst_n(rrst_n), 
        .rinc(rinc), 
        .wptr_gray_rclk(wptr_gray_rclk), 
        
        .raddr(raddr), 
        .rptr_gray(rptr_gray), 
        .rempty(rempty)          
    );
    
    sync_r2w #(.PTR_WIDTH(PTR_WIDTH)) Sync_R2W(
        .wclk(wclk), 
        .wrst_n(wrst_n), 
        .rptr_gray(rptr_gray),
        
        .rptr_gray_wclk(rptr_gray_wclk) 
    );
    
    sync_w2r #(.PTR_WIDTH(PTR_WIDTH)) Sync_W2R(
        .rclk(rclk), 
        .rrst_n(rrst_n), 
        .wptr_gray(wptr_gray),
         
        .wptr_gray_rclk(wptr_gray_rclk) 
    );
    
    fifo_memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) Mem(    
        .wclk(wclk), 
        .wr_en(wr_en),
        .waddr(waddr), 
        .wdata(wdata), 
        .raddr(raddr), //inputs
        
        .rdata(rdata)   //outputs
    );

//========================================================================================================================    
    
    initial begin
        $dumpfile("Testb.vcd");
        $dumpvars(0, Testb);
    end
    
    always begin
        #5 wclk = !wclk;
    end
    
    always begin
        #21 rclk = !rclk;
    end
    
//===============================================================================================================================    
    
    initial begin
        
        wrst_n = 1'b0;
        rrst_n = 1'b0;
        wclk = 1'b0;
        rclk = 1'b0;
        winc = 1'b0;
        rinc = 1'b0;
        wdata = 8'b0;
        
        @(negedge wclk);
        wrst_n = 1'b1;
        @(negedge rclk);
        rrst_n = 1'b1;
      
      //check to see when fifo gets full  
        repeat(20) begin
            @(negedge wclk);
            winc = 1'b1;
            wdata = wdata + 8'h01;
        end
        winc = 1'b0;
        
        repeat(2) begin
            @(negedge wclk);
        end
        
        // check to see when fifo gets empty
        repeat(20) begin
            @(negedge rclk);
            rinc = 1'b1;
        end
        rinc = 1'b0;
        
        repeat(2) begin
            @(negedge rclk);
        end
        
        //To show both read and write work together
        wdata = 8'h00;
        
        fork
            begin
                repeat(50) begin
                    @(negedge wclk);
                    winc  = 1'b1;
                    wdata = wdata + 8'h02;
                end
                winc = 1'b0;
            end
            begin
                repeat(50) begin
                    @(negedge rclk);
                    rinc = 1'b1;
                end
                rinc = 1'b0;
            end
        join
      
        $finish;
    end
        
endmodule