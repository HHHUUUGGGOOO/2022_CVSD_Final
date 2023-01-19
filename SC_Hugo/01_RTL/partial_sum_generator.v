module partial_sum_generator(
    input clk,
    input rst_n,
    input u0,
    input u1,
    input [3:0] state,
    input [3:0] stage,
    output [255:0] out
);

// integer
integer k;

// registers
reg [255:0] stage_8_u_r, stage_8_u_w;
reg [127:0] stage_7_u_r, stage_7_u_w;
reg [63:0] stage_6_u_r, stage_6_u_w;
reg [31:0] stage_5_u_r, stage_5_u_w;
reg [15:0] stage_4_u_r, stage_4_u_w;
reg [7:0] stage_3_u_r, stage_3_u_w;
reg [3:0] stage_2_u_r, stage_2_u_w;
reg [1:0] stage_1_u_r, stage_1_u_w;


// combinational
always @(*) begin
    stage_8_u_w = stage_8_u_r;
    stage_7_u_w = stage_7_u_r;
    stage_6_u_w = stage_6_u_r;
    stage_5_u_w = stage_5_u_r;
    stage_4_u_w = stage_4_u_r;
    stage_3_u_w = stage_3_u_r;
    stage_2_u_w = stage_2_u_r;
    stage_1_u_w = stage_1_u_r;
    if (state == 4) begin   // state decode
        if (stage == 0) begin
            
        end
        else begin
            stage_8_u_w = stage_8_u_r;
            stage_7_u_w = stage_7_u_r;
            stage_6_u_w = stage_6_u_r;
            stage_5_u_w = stage_5_u_r;
            stage_4_u_w = stage_4_u_r;
            stage_3_u_w = stage_3_u_r;
            stage_2_u_w = stage_2_u_r;
            stage_1_u_w = stage_1_u_r;
        end
    end
end



// squential
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage_8_u_r <= 0;
        stage_7_u_r <= 0;
        stage_6_u_r <= 0;
        stage_5_u_r <= 0;
        stage_4_u_r <= 0;
        stage_3_u_r <= 0;
        stage_2_u_r <= 0;
        stage_1_u_r <= 0;
    end
    else begin
        stage_8_u_r <= stage_8_u_w;
        stage_7_u_r <= stage_7_u_w;
        stage_6_u_r <= stage_6_u_w;
        stage_5_u_r <= stage_5_u_w;
        stage_4_u_r <= stage_4_u_w;
        stage_3_u_r <= stage_3_u_w;
        stage_2_u_r <= stage_2_u_w;
        stage_1_u_r <= stage_1_u_w;
    end
end


endmodule