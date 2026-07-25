// Write pointer + full flag generation
module wptr_handler 
(   wclk, wrst_n, winc, rptr_gray_wclk, //inputs
                   
    waddr, wptr_gray, wfull  //outputs        
);

    parameter ADDR_WIDTH = 4;
    input wclk;                                                        
    input wrst_n;                                                      
    input winc; // write request                           
    input [ADDR_WIDTH:0] rptr_gray_wclk; // read pointer synced into wclk domain    
                                                                                            
    output [ADDR_WIDTH-1:0] waddr; // address fed to memory                   
    output reg [ADDR_WIDTH:0] wptr_gray; // gray write pointer (sent to read domain)
    output reg wfull;                                                        
    
    reg [ADDR_WIDTH:0] wbin;
    wire [ADDR_WIDTH:0] wbin_next;
    wire [ADDR_WIDTH:0] wgray_next;
    wire wfull_next;

    // binary pointer advances only if a write happens and FIFO is not full
    assign wbin_next  = wbin + (winc & ~wfull);
    assign wgray_next = (wbin_next >> 1) ^ wbin_next; // binary -> gray

    assign waddr = wbin[ADDR_WIDTH-1:0];
  
    generate
        if (ADDR_WIDTH == 1) begin 
            assign wfull_next = (wgray_next == ~rptr_gray_wclk);
        end 
        else begin 
            assign wfull_next = (wgray_next == {~rptr_gray_wclk[ADDR_WIDTH:ADDR_WIDTH-1],
                                                  rptr_gray_wclk[ADDR_WIDTH-2:0]});
        end
    endgenerate

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin      <= {(ADDR_WIDTH+1){1'b0}};
            wptr_gray <= {(ADDR_WIDTH+1){1'b0}};
            wfull     <= 1'b0;
        end 
        else begin
            wbin      <= wbin_next;
            wptr_gray <= wgray_next;
            wfull     <= wfull_next;
        end
    end
endmodule 

//==========================================================================================================================

// Read pointer + empty flag generation

module rptr_handler 
(   rclk, rrst_n, rinc, wptr_gray_rclk, // inputs
    
    raddr, rptr_gray, rempty // outputs
);
    
    parameter ADDR_WIDTH = 4;
    input rclk;                                                        
    input rrst_n;                                                      
    input rinc; // read request                            
    input [ADDR_WIDTH:0] wptr_gray_rclk; // write pointer synced into rclk domain   
                                                                                            
    output [ADDR_WIDTH-1:0] raddr; // address fed to memory                   
    output reg [ADDR_WIDTH:0] rptr_gray; // gray read pointer (sent to write domain)
    output reg rempty;                                                       
    
    
    reg [ADDR_WIDTH:0] rbin;
    wire [ADDR_WIDTH:0] rbin_next;
    wire [ADDR_WIDTH:0] rgray_next;
    wire rempty_next;

    // binary pointer advances only if a read happens and FIFO is not empty
    assign rbin_next  = rbin + (rinc & ~rempty);
    assign rgray_next = (rbin_next >> 1) ^ rbin_next; // binary -> gray

    assign raddr = rbin[ADDR_WIDTH-1:0];

    assign rempty_next = (rgray_next == wptr_gray_rclk);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin      <= {(ADDR_WIDTH+1){1'b0}};
            rptr_gray <= {(ADDR_WIDTH+1){1'b0}};
            rempty    <= 1'b1;
        end 
        else begin
            rbin      <= rbin_next;
            rptr_gray <= rgray_next;
            rempty    <= rempty_next;
        end
    end
endmodule
