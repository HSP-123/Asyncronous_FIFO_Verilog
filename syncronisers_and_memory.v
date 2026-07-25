// Write side writes on wclk, read side reads combinationally
module fifo_memory(    
    wclk, wr_en, waddr, wdata, raddr, //inputs
    rdata   //outputs
   );
    
    parameter DATA_WIDTH = 8; //8 bit data 
    parameter ADDR_WIDTH = 4; //4bit adress = 2^4 locations = 16 locations
    
    input wclk;
    input wr_en;// wr_en = winc & !wfull
    input [ADDR_WIDTH-1:0] waddr;//[3:0]
    input [DATA_WIDTH-1:0] wdata;//[7:0]
    input [ADDR_WIDTH-1:0] raddr;//[3:0]
    
    output [DATA_WIDTH-1:0] rdata;
    
    
    localparam DEPTH = 1 << ADDR_WIDTH; //2^addr_width = 2^4 = 16 adresses possibel

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];// 16 element array storing 8 bit each

    always @(posedge wclk) begin
        if (wr_en)
            mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];
endmodule

//====================================================================================================================================

//syncroniser sending read pointer towards write clock domain 
module sync_r2w 
(
    wclk, wrst_n, rptr_gray,//inputs
    rptr_gray_wclk //output
);
    
    parameter PTR_WIDTH = 5; //ADDR_WIDTH + 1 in terms of bits 
    input wclk;
    input wrst_n;
    input [PTR_WIDTH-1:0] rptr_gray; // gray-coded read pointer (read clock domain)
    
    output reg [PTR_WIDTH-1:0] rptr_gray_wclk; // read pointer synchronized into write clock domain
    
    reg [PTR_WIDTH-1:0] rptr_gray_int;

    
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_int <= {PTR_WIDTH{1'b0}};
            rptr_gray_wclk <= {PTR_WIDTH{1'b0}};
        end 
        else begin
            rptr_gray_int <= rptr_gray;
            rptr_gray_wclk <= rptr_gray_int;
        end
    end
endmodule

//===========================================================================================================

//syncroniser sending write pointer towards read clock domain 
module sync_w2r 
(
    rclk, rrst_n, wptr_gray,//inputs
    wptr_gray_rclk //output
);
    
    parameter PTR_WIDTH = 5; //ADDR_WIDTH + 1 in terms of bits 
    input rclk;
    input rrst_n;
    input [PTR_WIDTH-1:0] wptr_gray; // gray-coded read pointer (read clock domain)
    
    output reg [PTR_WIDTH-1:0] wptr_gray_rclk; // read pointer synchronized into write clock domain
    
    reg [PTR_WIDTH-1:0] wptr_gray_int;

    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_int <= {PTR_WIDTH{1'b0}};
            wptr_gray_rclk <= {PTR_WIDTH{1'b0}};
        end 
        else begin
            wptr_gray_int <= wptr_gray;
            wptr_gray_rclk <= wptr_gray_int;
        end
    end
endmodule

//===========================================================================================================


