module  sdram_top
(
    input   wire            sys_clk            ,   //系统时钟
    input   wire            clk_out            ,   //相位偏移时钟
    input   wire            sys_rst_n          ,   //复位信号,低有效
//写FIFO信号
    input   wire            wr_fifo_wr_clk_0   ,   //写FIFO写时钟
    input   wire            wr_fifo_wr_req_0   ,   //写FIFO写请求
    input   wire    [15:0]  wr_fifo_wr_data_0  ,   //写FIFO写数据
 
    input   wire            wr_fifo_wr_clk_1   ,   //写FIFO写时钟
    input   wire            wr_fifo_wr_req_1   ,   //写FIFO写请求
    input   wire    [15:0]  wr_fifo_wr_data_1  ,   //写FIFO写数据

    input   wire    [23:0]  sdram_wr_b_addr    ,   //写SDRAM首地址
    input   wire    [23:0]  sdram_wr_e_addr    ,   //写SDRAM末地址
    input   wire    [9:0]   wr_burst_len       ,   //写SDRAM数据突发长度
    input   wire            wr_rst             ,   //写复位信号
//读FIFO信号   
    input   wire            rd_fifo_rd_clk     ,   //读FIFO读时钟
    input   wire            rd_fifo_rd_req     ,   //读FIFO读请求

    input   wire    [23:0]  sdram_rd_b_addr    ,   //读SDRAM首地址
    input   wire    [23:0]  sdram_rd_e_addr    ,   //读SDRAM末地址

    input   wire    [9:0]   rd_burst_len       ,   //读SDRAM数据突发长度
    input   wire            rd_rst             ,   //读复位信号
    output  wire    [15:0]  rd_fifo_rd_data    ,   //读FIFO读数据


    input   wire            sdram_read_valid   ,   //SDRAM读使能
    input   wire            pingpang_en        ,   //SDRAM乒乓操作使能
    output  wire            init_end           ,   //SDRAM初始化完成标志
//
    input   wire    [12:0]  rd_h_pixel         ,         
//SDRAM接口信号   
    output  wire            sdram_clk          ,   //SDRAM芯片时钟
    output  wire            sdram_cke          ,   //SDRAM时钟有效信号
    output  wire            sdram_cs_n         ,   //SDRAM片选信号
    output  wire            sdram_ras_n        ,   //SDRAM行地址选通脉冲
    output  wire            sdram_cas_n        ,   //SDRAM列地址选通脉冲
    output  wire            sdram_we_n         ,   //SDRAM写允许位
    output  wire    [1:0]   sdram_ba           ,   //SDRAM的L-Bank地址线
    output  wire    [12:0]  sdram_addr         ,   //SDRAM地址总线
    output  wire    [1:0]   sdram_dqm          ,   //SDRAM数据掩码
    inout   wire    [15:0]  sdram_dq              //SDRAM数据总线
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//

//wire  define
wire            sdram_wr_req    ;   //sdram 写请求
wire            sdram_wr_ack    ;   //sdram 写响应
wire    [23:0]  sdram_wr_addr   ;   //sdram 写地址
wire    [15:0]  sdram_data_in   ;   //写入sdram中的数据

wire            sdram_rd_req    ;   //sdram 读请求
wire            sdram_rd_ack    ;   //sdram 读响应
wire    [23:0]  sdram_rd_addr   ;   //sdram 读地址
wire    [15:0]  sdram_data_out  ;   //从sdram中读出的数据

//sdram_clk:SDRAM芯片时钟
assign  sdram_clk = clk_out;
//sdram_dqm:SDRAM数据掩码
assign  sdram_dqm = 2'b00;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

//------------- fifo_ctrl_inst -------------
fifo_ctrl fifo_ctrl_inst
(
    .sys_clk             (sys_clk),
    .sys_rst_n           (sys_rst_n),
	
	
    .wr_fifo_wr_clk_0    (wr_fifo_wr_clk_0  ),
    .wr_fifo_wr_req_0    (wr_fifo_wr_req_0  ),
    .wr_fifo_wr_data_0   (wr_fifo_wr_data_0 ),

    //FIFO writing Port 1
    .wr_fifo_wr_clk_1    (wr_fifo_wr_clk_1 ),
    .wr_fifo_wr_req_1    (wr_fifo_wr_req_1 ),
    .wr_fifo_wr_data_1   (wr_fifo_wr_data_1),

    //FIFO writing Port for control
    .sdram_wr_b_addr     (sdram_wr_b_addr  ),
    .sdram_wr_e_addr     (sdram_wr_e_addr  ),
    .wr_burst_len        (wr_burst_len     ),
    .wr_rst              (wr_rst           ),

    //FIFO reading Port 
    .rd_fifo_rd_clk      (rd_fifo_rd_clk  ),
    .rd_fifo_rd_req      (rd_fifo_rd_req  ),
    .rd_fifo_rd_data     (rd_fifo_rd_data ),

    //FIFO reading Port for control
    .sdram_rd_b_addr     (sdram_rd_b_addr  ),
    .sdram_rd_e_addr     (sdram_rd_e_addr  ),
    .rd_burst_len        (rd_burst_len     ),
    .rd_rst              (rd_rst           ),
    .sdram_pingpang_en   (sdram_pingpang_en),
    .sdram_read_valid    (sdram_read_valid ),

    //SDRAM Port for control
    .pixel_xpos          (),
    .rd_h_pixel          (rd_h_pixel),
    .sdram_init_done     (init_end),

    //SDRAM Port for writting
    .sdram_wr_ack        (sdram_wr_ack  ),
    .sdram_wr_addr       (sdram_wr_addr ),
    .sdram_wr_req        (sdram_wr_req  ),
    .sdram_data_in       (sdram_data_in ),

    //SDRAM Port for reading
    .sdram_rd_ack        (sdram_rd_ack      ),
    .sdram_data_out      (sdram_data_out    ),
    .sdram_rd_req        (sdram_rd_req      ),
    .sdram_rd_addr       (sdram_rd_addr     )
);

//------------- sdram_ctrl_inst -------------
sdram_ctrl  sdram_ctrl_inst(

    .sys_clk        (sys_clk        ),   //系统时钟
    .sys_rst_n      (sys_rst_n      ),   //复位信号，低电平有效
//SDRAM 控制器写端口
    .sdram_wr_req   (sdram_wr_req   ),   //写SDRAM请求信号
    .sdram_wr_addr  (sdram_wr_addr  ),   //SDRAM写操作的地址
    .wr_burst_len   (wr_burst_len   ),   //写sdram时数据突发长度
    .sdram_data_in  (sdram_data_in  ),   //写入SDRAM的数据
    .sdram_wr_ack   (sdram_wr_ack   ),   //写SDRAM响应信号
//SDRAM 控制器读端口
    .sdram_rd_req   (sdram_rd_req   ),  //读SDRAM请求信号
    .sdram_rd_addr  (sdram_rd_addr  ),  //SDRAM写操作的地址
    .rd_burst_len   (rd_burst_len   ),  //读sdram时数据突发长度
    .sdram_data_out (sdram_data_out ),  //从SDRAM读出的数据
    .init_end       (init_end       ),  //SDRAM 初始化完成标志
    .sdram_rd_ack   (sdram_rd_ack   ),  //读SDRAM响应信号
//FPGA与SDRAM硬件接口
    .sdram_cke      (sdram_cke      ),  // SDRAM 时钟有效信号
    .sdram_cs_n     (sdram_cs_n     ),  // SDRAM 片选信号
    .sdram_ras_n    (sdram_ras_n    ),  // SDRAM 行地址选通脉冲
    .sdram_cas_n    (sdram_cas_n    ),  // SDRAM 列地址选通脉冲
    .sdram_we_n     (sdram_we_n     ),  // SDRAM 写允许位
    .sdram_ba       (sdram_ba       ),  // SDRAM L-Bank地址线
    .sdram_addr     (sdram_addr     ),  // SDRAM 地址总线
    .sdram_dq       (sdram_dq       )   // SDRAM 数据总线

);

endmodule