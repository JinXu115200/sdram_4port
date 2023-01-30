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
    output  reg    [23:0]       sdram_wr_addr       ,
    output  reg                 sdram_wr_req        ,
    output  wire   [15:0]       sdram_data_in       ,

    //SDRAM Port for reading
    input   wire                sdram_rd_ack        ,
    input   wire   [15:0]       sdram_data_out      ,
    output  reg                 sdram_rd_req        ,
    output  reg    [23:0]       sdram_rd_addr      
);

//State Maschine
parameter IDLE          = 4'd0  ;
parameter INIT_DONE     = 4'd1  ;
parameter WR_KEEP       = 4'd2  ;
parameter RD_KEEP       = 4'd3  ;

//Reg Define
reg         wr_ack_r1           ;
reg         wr_ack_r2           ;
reg         rd_ack_r1           ;
reg         rd_ack_r2           ;
reg         wr_rst_r1           ;
reg         wr_rst_r2           ;
reg         rd_rst_r1           ;
reg         rd_rst_r2           ;
reg         read_valid_r1       ;
reg         read_valid_r2       ;
reg         sw_bank_en0         ;   //enable signal for switch to the bank0 signal
reg         sw_bank_en1         ;   //enable signal for switch to the bank1 signal
reg         rw_bank_flag0       ;   //read bank0 flag signal
reg         rw_bank_flag1       ;   //read bank1 flag signal
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
wire        wr_rst_flag         ;
wire        rd_rsd_flag         ;  

wire        sdram_wr_ack_0      ;
wire        sdram_wr_ack_1      ;
wire        sdram_rd_ack_0      ;
wire        sdram_rd_ack_1      ;    

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

//posedge detection
assign wr_rst_flag =  (~wr_rst_r2 & wr_rst_r1);
assign rd_rst_flag =  (~rd_rst_r2 & rd_rst_r1);

//The registor of writting ack signal of SDRAM, for detecting the negedge of "sdram_wr_ack"
always@ (posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                wr_ack_r1 <= 1'b0;
                wr_ack_r2 <= 1'b0;
            end
        else   
            begin
                wr_ack_r1 <= sdram_wr_ack;
                wr_ack_r2 <= wr_ack_r1;
            end
    end

//The registor of reading ack signal of SDRAM, for detecting the negedge of "sdram_rd_ack"
always@ (posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                rd_ack_r1 <= 1'b0;
                rd_ack_r2 <= 1'b0;
            end
        else   
            begin
                rd_ack_r1 <= sdram_rd_ack;
                rd_ack_r2 <= rd_ack_r1;
            end
    end

//Reset signal for writting port of synchronization SDRAM, at the same time for detection of the negedge of "wr_rst"
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                wr_rst_r1 <= 1'b0;
                wr_rst_r2 <= 1'b0;
            end
        else 
            begin
                wr_rst_r1 <= wr_rst;
                wr_rst_r2 <= wr_rst_r1;
            end
    end

//Reset signal for read port of synchronization SDRAM, at the same time for detection of the negedge of "rd_rst"
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                rd_rst_r1 <= 1'b0;
                rd_rst_r2 <= 1'b0;
            end
        else 
            begin
                rd_rst_r1 <= rd_rst;
                rd_rst_r2 <= rd_rst_r1;
            end
    end

//Enable signal for read port of synchronization SDRAM
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                read_valid_r1 <= 1'b0;
                read_valid_r2 <= 1'b0;
            end 
        else 
            begin
                read_valid_r1 <= sdram_read_valid;
                read_valid_r2 <= read_valid_r1;
            end
    end

//The ack signal from the writting port of FIFO_0
assign sdram_wr_ack_0 = (wr_fifo_flag == 1'b1) ? 1'b0 : sdram_wr_ack;

//The ack signal from the writting port of FIFO_1
assign sdram_wr_ack_1 = (wr_fifo_flag == 1'b1) ? sdram_wr_ack : 1'b0;

//The ack signal from the reading port of FIFO_0
assign sdram_rd_ack_0 = (rd_fifo_flag == 1'b1) ? 1'b0 : sdram_rd_ack;

//The ack signal from the reading port of FIFO_1
assign sdram_rd_ack_1 = (rd_fifo_flag == 1'b1) ? sdram_rd_ack: 1'b0;

//sdram_data_in: choose which data to write in SDRAM
assign sdram_data_in = (wr_fifo_flag == 1'b1) ? sdram_data_in_1 : sdram_data_in_0;

//sdram_data_out_0: choose the FIFO_0 to read the data form the SDRAM
assign sdram_data_out_0 = (rd_fifo_flag == 1'b1) ? 1'b0 : sdram_data_out;

//sdram_data_out_1: choose the FIFO_1 to read the data form the SDRAM
assign sdram_data_out_1 = (rd_fifo_flag == 1'b1) ? sdram_data_out : 1'b0; 

//像素显示请求信号切换，即显示器左侧请求FIFO0显示，右侧请求FIFO1显示
assign rd_fifo_rd_req_0 = (rd_cnt <= rd_h_pixel - 1'b1) ? rd_fifo_rd_req : 1'b0;
assign rd_fifo_rd_req_1 = (rd_cnt <= rd_h_pixel - 1'b1) ? 1'b0 : rd_fifo_rd_req;

//像素在显示器位置的切换，即显示器左侧显示FIFO0,右侧显示FIFO1
assign rd_data = (rd_cnt <= rd_h_pixel) ? rd_fifo_data_out_1 : rd_fifo_data_out_0;

//rd_cnt
always@(posedge rd_fifo_rd_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0)
        rd_cnt <= 13'd0;
    else if (rd_fifo_rd_req == 1'b1)
        rd_cnt <= rd_cnt + 1'b1;
    else
        rd_cnt <= 13'd0;

// sdram_wr_addr0
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                sdram_wr_addr0 <= 24'd0;
                rw_bank_flag0  <= 1'b0;
                sw_bank_en0    <= 1'b0;
            end
        else if (wr_rst_flag == 1'b1)
            begin
                sdram_wr_addr0 <= sdram_wr_b_addr;
                rw_bank_flag0 <= 1'b0;
                sw_bank_en0   <= 1'b0;
            end
        else if (write_done_flag == 1'b1 && wr_fifo_flag == 1'b0)
            begin
                if (sdram_pingpang_en == 1'b1)
                    begin
                        if (sdram_wr_addr0 [21:0] < sdram_wr_e_addr - wr_burst_len)
                            sdram_wr_addr0 <= sdram_wr_addr0 + wr_burst_len;
                        else
                            begin
                                rw_bank_flag0 <= ~rw_bank_flag0;
                                sw_bank_en0 <= 1'b1;
                            end
                    end
                else if (sdram_wr_addr0 < sdram_wr_e_addr - wr_burst_len)
                    sdram_wr_addr0 <= sdram_wr_addr0 + wr_burst_len;
                else
                    sdram_wr_addr0 <= sdram_wr_b_addr;
            end
        else if (sw_bank_en0 == 1'b1)
            begin
                sw_bank_en0 <= 1'b0;
                    if (rw_bank_flag0 == 1'b0)
                        sdram_wr_addr0 <= {2'b00,sdram_wr_b_addr [21:0]};
                    else 
                        sdram_wr_addr0 <= {2'b01,sdram_wr_b_addr [21:0]}; 
            end
    end

// sdram_wr_addr1
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            begin
                sdram_wr_addr1 <= 24'd0;
                rw_bank_flag1  <= 1'b0;
                sw_bank_en1    <= 1'b0;
            end
        else if (wr_rst_flag == 1'b1)
            begin
                sdram_wr_addr1 <= sdram_wr_e_addr;
                rw_bank_flag1 <= 1'b0;
                sw_bank_en1   <= 1'b0;
            end
        else if (write_done_flag == 1'b1 && wr_fifo_flag == 1'b1)
            begin
                if (sdram_pingpang_en == 1'b1)
                    begin
                        if (sdram_wr_addr1 [21:0] < sdram_wr_e_addr*2 - wr_burst_len)
                            sdram_wr_addr1 <= sdram_wr_addr1 + wr_burst_len;
                        else
                            begin
                                rw_bank_flag1 <= ~rw_bank_flag1;
                                sw_bank_en1 <= 1'b1;
                            end
                    end
                else if (sdram_wr_addr1 < sdram_wr_e_addr*2 - wr_burst_len)
                    sdram_wr_addr1 <= sdram_wr_addr1 + wr_burst_len;
                else
                    sdram_wr_addr1 <= sdram_wr_e_addr;
            end
        else if (sw_bank_en1 == 1'b1)
            begin
                sw_bank_en1 <= 1'b0;
                    if (rw_bank_flag1 == 1'b0)
                        sdram_wr_addr1 <= {2'b10,sdram_wr_e_addr [21:0]};
                    else 
                        sdram_wr_addr1 <= {2'b11,sdram_wr_e_addr [21:0]}; 
            end
    end

//sdram_rd_addr0
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            sdram_rd_addr0 <= 24'd0;
        else if (rd_rst_flag == 1'b1)
            sdram_rd_addr0 <= sdram_rd_b_addr;
        else if ((read_done_flag == 1'b1) && (rd_fifo_flag == 1'b0))
            begin
                if (sdram_pingpang_en == 1'b1)
                    begin
                        if (sdram_rd_addr0 [21:0] < sdram_rd_e_addr - rd_burst_len)
                            sdram_rd_addr0 <= sdram_rd_addr0 + rd_burst_len;
                        else
                            begin
                                if (rw_bank_flag0 == 1'b0)
                                    sdram_rd_addr0 <= {2'b01, sdram_rd_b_addr [21:0]};
                                else 
                                    sdram_rd_addr0 <= {2'b00, sdram_rd_b_addr [21:0]}; 
                            end
                    end
                else if (sdram_rd_addr0 < sdram_rd_e_addr - rd_burst_len)
                    sdram_rd_addr0 <= sdram_rd_addr0 + rd_burst_len;
                else
                    sdram_rd_addr0 <= sdram_rd_b_addr;
            end
    end

//sdram_rd_addr1
always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            sdram_rd_addr1 <= 24'd0;
        else if (rd_rst_flag == 1'b1)
            sdram_rd_addr1 <= sdram_rd_e_addr; 
        else if ((read_done_flag == 1'b1) && (rd_fifo_flag == 1'b1))
            begin
                if (sdram_pingpang_en == 1'b1)
                    begin
                        if (sdram_rd_addr [21:0] < sdram_rd_e_addr*2 - rd_burst_len)
                            sdram_rd_addr1 <= sdram_rd_addr1 + rd_burst_len;
                        else
                            begin
                                if (rw_bank_flag1 == 1'b0)
                                    sdram_rd_addr1 <= {2'b11, sdram_rd_e_addr [21:0]};
                                else
                                    sdram_rd_addr1 <= {2'b10, sdram_rd_e_addr [21:0]};
                            end
                    end
                else if (sdram_rd_addr1 < sdram_rd_e_addr*2 - rd_burst_len)
                    sdram_rd_addr1 <= sdram_rd_addr1 + rd_burst_len;
                else
                    sdram_rd_addr1 <= sdram_rd_e_addr;
            end
    end

//arbit for reading and writting 
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if (sys_rst_n == 1'b0)
        begin
            sdram_wr_req <= 1'b0;
            sdram_wr_addr <= sdram_wr_addr0;
            wr_fifo_flag <= 1'b0;

            sdram_rd_req <= 1'b0;
            rd_fifo_flag <= 1'b0;
            sdram_rd_addr <= sdram_rd_addr0;

            state <= IDLE;
        end
    else 
    begin
        case (state)
            IDLE: 
                if (sdram_init_done == 1'b1)    
                    state <= INIT_DONE;
                else
                    state <= state;
            INIT_DONE:
                begin
                    if (wr_fifo_num_0 >= wr_burst_len*2)
                    begin
                        sdram_wr_req <= 1'b1;
                        sdram_wr_addr <= sdram_wr_addr0;
                        wr_fifo_flag <= 1'b0;

                        sdram_rd_req <= 1'b0;
                        sdram_rd_addr <= sdram_rd_addr0;
                        rd_fifo_flag <= 1'b0;

                        state <= WR_KEEP;
                    end
                    else if (wr_fifo_num_1 >= wr_burst_len*2)
                    begin
                        sdram_wr_req <= 1'b1;
                        sdram_wr_addr <= sdram_wr_addr1;
                        wr_fifo_flag <= 1'b1;

                        sdram_rd_req <= 1'b0;
                        sdram_rd_addr <= sdram_rd_addr1;
                        rd_fifo_flag <= 1'b0;

                        state <= WR_KEEP;
                    end
                    else if (rd_fifo_num_0 < rd_burst_len*2)
                        begin
                            sdram_wr_req <= 1'b0;
                            sdram_wr_addr <= sdram_wr_addr0;
                            wr_fifo_flag <= 1'b0;

                            sdram_rd_req <= 1'b1;
                            sdram_rd_addr <= sdram_rd_addr0;
                            rd_fifo_flag <= 1'b0;

                            state <= RD_KEEP;
                        end
                    else if (rd_fifo_num_1 < rd_burst_len*2)
                        begin
                            sdram_wr_req <= 1'b0;
                            sdram_wr_addr <= sdram_wr_addr0;
                            wr_fifo_flag <= 1'b0;

                            sdram_rd_req <= 1'b1;
                            sdram_rd_addr <= sdram_rd_addr1;
                            rd_fifo_flag <= 1'b1;

                            state <= RD_KEEP;
                        end
                    else
                        begin
                            sdram_wr_req <= 1'b0;
                            sdram_wr_addr <= sdram_wr_addr0;
                            wr_fifo_flag <= 1'b0;

                            sdram_rd_req <= 1'b0;
                            sdram_rd_addr <= sdram_rd_addr0;
                            rd_fifo_flag <= 1'b0;

                            state <= state;
                        end
                end
            WR_KEEP:
            begin
                if (write_done_flag == 1'b1)
                begin
                    sdram_wr_req <= 1'b0;
                    sdram_wr_addr <= sdram_wr_addr0;
                    wr_fifo_flag <= 1'b0;

                    state <= INIT_DONE;
                end
            end
            RD_KEEP:
            begin
                if (read_done_flag == 1'b1)
                begin
                    sdram_rd_req <= 1'b0;
                    sdram_rd_addr <= sdram_rd_addr0;
                    rd_fifo_flag <= 1'b0;

                    state <= INIT_DONE;
                end
            end
            default : state <= IDLE;
        endcase         
    end
end

wrfifo	wrfifo0_inst
(
	.wrclk      ( wr_fifo_wr_clk_0  ),
    .wrreq      ( wr_fifo_wr_req_0  ),
	.data       ( wr_fifo_wr_data_0 ),

	.rdclk      ( sys_clk           ),
	.rdreq      ( sdram_wr_ack_0     ),
	.q          ( sdram_data_in_0    ),

    .aclr       ( ~sys_rst_n || wr_rst_flag  ),
	.rdusedw    ( wr_fifo_num_0 )
);    

wrfifo	wrfifo1_init
(
	.wrclk      ( wr_fifo_wr_clk_1  ),
    .wrreq      ( wr_fifo_wr_req_1  ),
	.data       ( wr_fifo_wr_data_1 ),

	.rdclk      ( sys_clk           ),
	.rdreq      ( sdram_wr_ack_1    ),
	.q          ( sdram_data_in_1   ),

    .aclr       ( ~sys_rst_n || wr_rst_flag  ),
	.rdusedw    ( wr_fifo_num_1 )
);   

rdfifo	rdfifo0_inst 
(
	.wrclk      ( sys_clk               ),
    .wrreq      ( sdram_rd_ack_0        ),
	.data       ( sdram_data_out_0      ),

	.rdclk      ( rd_fifo_rd_clk        ),
	.rdreq      ( rd_fifo_rd_req_0      ),
	.q          ( rd_fifo_data_out_0    ),

    .aclr       ( ~sys_rst_n || rd_rst_flag ),
	.wrusedw    ( rd_fifo_num_0 )
);

rdfifo	rdfifo1_inst 
(
	.wrclk      ( sys_clk               ),
    .wrreq      ( sdram_rd_ack_1        ),
	.data       ( sdram_data_out_1      ),

	.rdclk      ( rd_fifo_rd_clk        ),
	.rdreq      ( rd_fifo_rd_req_1      ),
	.q          ( rd_fifo_data_out_1    ),

    .aclr       ( ~sys_rst_n || rd_rst_flag ),
	.wrusedw    ( rd_fifo_num_1 )
);


endmodule