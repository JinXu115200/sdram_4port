module fifo_ctrl
(
    input   wire                sys_clk             ,
    input   wire                sys_rst_n           ,
	
	//FIFO writing Port 0
    input   wire    	        wr_fifo_wr_clk_0    ,
    input   wire                wr_fifo_wr_req_0    ,
    input   wire    [15:0]      wr_fifo_wr_data_0   ,

    //FIFO writing Port 1
    input   wire                wr_fifo_wr_clk_1    ,
    input   wire                wr_fifo_wr_req_1    ,
    input   wire    [15:0]      wr_fifo_wr_data_1   ,

    //FIFO writing Port for control
    input   wire    [23:0]      sdram_wr_b_addr     ,
    input   wire    [23:0]      sdram_wr_e_addr     ,
    input   wire    [9:0]       wr_burst_len        ,
    input   wire                wr_rst              ,

    //FIFO reading Port 
    input   wire                rd_fifo_rd_clk      ,
    input   wire                rd_fifo_rd_req      ,
    output  wire    [15:0]      rd_fifo_rd_data     ,

    //FIFO reading Port for control
    input   wire    [23:0]      sdram_rd_b_addr     ,
    input   wire    [23:0]      sdram_rd_e_addr     ,
    input   wire    [9:0]       rd_burst_len        ,
    input   wire                rd_rst              ,
    input   wire                sdram_pingpang_en   ,
    input   wire                sdram_read_valid    ,

    //SDRAM Port for control
    input   wire   [10:0]       pixel_xpos          ,
    input   wire   [12:0]       rd_h_pixel          ,
    input   wire                sdram_init_done     ,

    //SDRAM Port for writting
    input   wire                sdram_wr_ack        ,
    output  wire   [23:0]       sdram_wr_addr       ,
    output  reg                 sdram_wr_req        ,
    output  reg    [15:0]       sdram_data_in       ,

    //SDRAM Port for reading
    input   wire                sdram_rd_ack        ,
    input   wire   [15:0]       sdram_data_out      ,
    output  reg                 sdram_rd_req        ,
    output  reg    [23:0]       sdram_rd_addr      
);

//State Maschine
parameter IDLE    = 4'd0  ;
parameter INIT    = 4'd1  ;
parameter WR_KEEP = 4'd2  ;
parameter RD_KEEP = 4'd3  ;

//Reg Define
reg         wr_ack_r1           ;
reg         wr_ack_r2           ;
reg         rd_ack_r1           ;
reg         rd_ack_r2           ;
reg         wr_load_r1          ;
reg         wr_load_r2          ;
reg         rd_load_r1          ;
reg         rd_load_r2          ;
reg         read_vaild_r1       ;
reg         read_vaild_r2       ;
reg         sw_bank_en0         ;
reg         sw_bank_en1         ;
reg         rw_bank_flag0       ;
reg         rw_bank_flag1       ;
reg         wr_fifo_flag        ;
reg         rd_fifo_flag        ;

reg [23:0]  sdram_rd_addr0      ;
reg [23:0]  sdram_rd_addr1      ;
reg [23:0]  sdram_wr_addr0      ;
reg [23:0]  sdram_wr_addr1      ;
reg [3:0]   state               ;
reg [12:0]  rd_cnt              ; 

//wire  define
wire        write_done_flag     ;
wire        read_done_flag      ;
wire        wr_load_flag        ;
wire        rd_load_flag        ;  
wire        sdram_wr_ack_0      ;
wire        sdram_wr_ack_1      ;

wire [10:0] wr_fifo_num_0       ;
wire [10:0] wr_fifo_num_1       ;
wire [10:0] rd_fifo_num_0       ;
wire [10:0] rd_fifo_num_1       ;
wire [15:0] sdram_data_out_0    ;
wire [15:0] sdram_data_out_1    ;
wire        rd_fifo_rd_req_0    ;
wire        rd_fifo_rd_req_1    ;
wire [15:0] rd_fifo_data_out_0  ;       
wire [15:0] rd_fifo_data_out_1  ; 
wire [15:0] sdram_data_in_0     ;
wire [15:0] sdram_data_in_1     ;

//***************************************************************************
//**                                main code                           **//
//***************************************************************************

//negedge detection
assign write_done_flag = (wr_ack_r2 & ~ wr_ack_r1);
assign read_done_flag = (rd_ack_r1 & ~ rd_ack_r2);

//The ack signal from the writting port of FIFO_0
assign sdram_wr_ack_0 = (wr_fifo_flag == 1'b1) ? 1'b0 : sdram_wr_ack;

//The ack signal from the writting port of FIFO_0
assign sdram_wr_ack_1 = (wr_fifo_flag == 1'b1) ? sdram_wr_ack : 1'b0;

endmodule