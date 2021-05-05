//main module
module SnakeGame(clk,red,green,blue,h_sync,v_sync,left,right,reset);
    input clk;//50mhz onboard clk
	 input left,right,reset;
    output reg [3:0] red, blue, green;
    output h_sync, v_sync;
    wire vga_clk,refresh_clk,displayArea;
    wire [9:0] xCount;
    wire [9:0] yCount;
    wire [9:0] randX;
    wire [9:0] randomX;
	 wire [8:0] randY;
	 wire [8:0] randomY;
	 wire [1:0] direction;
	 
	 wire R,G,B;
	 reg [9:0] snakeX;
	 reg [9:0] snakeY;
	 reg head;
	 reg border;
	 reg apple;
	 reg tempX, tempY;
    reg [9:0] appleX;
	 reg [9:0] appleY;
	 
	 ClockDivider c1(clk, vga_clk);
    ClockDivider2 c2(clk, refresh_clk);
    VGA_Generator vga(vga_clk,xCount,yCount,displayArea,h_sync,v_sync);
    randomGen(vga_clk,randX,randY);
	 buttonInput b1(refresh_clk,left,right,direction);
	 
	 assign randomX = randX;
	 assign randomY = randY;
	 
	 //initialize snake and first apple location
	 initial begin
	 snakeX = 9'd20;
	 snakeY = 9'd20;
	 appleX = 9'd300;
	 appleY = 9'd220;
	 end
	 
	 //apple size
	 always@(posedge vga_clk)
	 begin
		tempX <= (xCount > appleX & xCount < (appleX + 20));
		tempY <= (yCount > appleY & yCount < (appleY + 20));
		apple <= tempX & tempY;
	 end
	 
	 //border creation and snake size
	 always@(posedge vga_clk)
	 begin
		head <= (xCount > snakeX & xCount <(snakeX+20)) & (yCount > snakeY & yCount < (snakeY+20));
		border <= (((xCount >= 0) && (xCount < 11) || (xCount >= 630) && (xCount < 641)) || ((yCount >= 0) && (yCount < 11) || (yCount >= 470) && (yCount < 481)));
	 end
	 
	 //movement
	 always@(posedge refresh_clk)
	 begin
		//border collision reset 
		if((snakeX < 11 || snakeX > 605) || (snakeY < 11 || snakeY > 445) || ~reset)
			begin
				snakeX = 9'd20;
				snakeY = 9'd20;
			end
		if(direction == 2'b10)//left
			begin
				snakeX = snakeX - 5;
			end
		else if(direction == 2'b01)//right
			begin
				snakeX = snakeX + 5;
			end
		else if(direction == 2'b11)//up
			begin
				snakeY = snakeY - 5;
			end
		else if(direction == 2'b00)//down
			begin
				snakeY = snakeY + 5;
			end
	 end
	 
	 //border collision/gameover 
	 always@(posedge vga_clk)
	 begin
		if(apple & head)
		begin
			appleX = randX;
			appleY = randY;
		end
		if(~reset)//reset apple position on reset 
		begin
			appleX = 9'd300;
			appleY = 9'd220;
		end
	 end
	 //assign rgb outputs
	 assign R = (displayArea & (apple));
	 assign G = (displayArea & (head));
	 assign B = (displayArea & (border));
	 
	always@(posedge vga_clk)
	begin
		red = {4{R}};
		green = {4{G}};
		blue = {4{B}};
	end
	 
	 
endmodule 

//-----------------------------------------------------------------------
module ClockDivider(clk, vga_clk);
input clk;//50Mhz input clock
output reg vga_clk;//25Mhz pixel clock
reg q;
//time period of vga clock is twice that of the input clock
always@(posedge clk)
    begin
            q <= ~q;
        vga_clk = q;
    end

endmodule
//-----------------------------------------------------------------------
module ClockDivider2(clk, refresh_clk);
    output reg refresh_clk;
    input clk;
    
    reg [21:0] count = 0; 
    
    always@(posedge clk)
    begin
        count <= count + 1;
        if(count == 1000000)//50Hz 
        begin
            count <= 0;
            refresh_clk <= ~refresh_clk;
        end
    end

endmodule
//-----------------------------------------------------------------------
module VGA_Generator(vga_clk, xCount, yCount, displayArea, vga_hSync, vga_vSync);
    input vga_clk;
    output reg [9:0] xCount, yCount;
    output reg displayArea;
    output vga_hSync, vga_vSync;
    reg p_hSync, p_vSync;
    
    parameter porchHF = 640;
    parameter syncH = 656;
    parameter porchHB = 752;
    parameter maxH = 800;
    
    parameter porchVF = 480;
    parameter syncV = 490;
    parameter porchVB = 492;
    parameter maxV = 525;
    
    always@(posedge vga_clk)
    begin
        if(xCount == maxH)
            xCount <= 0;
        else
            xCount <= xCount + 1'b1;
    end
    
    always@(posedge vga_clk)
    begin
        if(xCount == maxH)
        begin
            if(yCount == maxV)
                yCount <= 0;
            else 
                yCount <= yCount + 1'b1;
        end
    end
    
    always@(posedge vga_clk)
    begin
        displayArea <= ((xCount < porchHF) && (yCount < porchVF));
        p_hSync <= ((xCount >= syncH) && (xCount < porchHB)); 
        p_vSync <= ((yCount >= syncV) && (yCount < porchVB));
    end
    
    assign vga_vSync = ~p_vSync;
    assign vga_hSync = ~p_hSync;


endmodule
//-----------------------------------------------------------------------
module randomGen(VGA_clk, rand_X, rand_Y);//random generator on a grid of 64 x 48
    input VGA_clk;
    output reg [9:0]rand_X;//1024 possibilities 
    output reg [8:0]rand_Y;//512 possibilities
    
    reg [5:0]Xcor, Ycor = 10;//64 possibilities since the snake moves 10 pixels, 64 x 48 border

    always @(posedge VGA_clk)
     begin
        Xcor <= Xcor + 2;   //as the VGA refreshes, the x coordinate will be increased by 3
     end
    always @(posedge VGA_clk)
     begin
        Ycor <= Ycor + 1;//as the VGA refreshes, the y coordinate will be increased by 3
    end
     always @(posedge VGA_clk)
    begin   
        if(Xcor>62) // if x cor is intersects right bound it will be set at x coordinate 62
            rand_X <= 595;
        else if (Xcor<2)
            rand_X <= 20;//if x cor is to close to the left bound it will be set at x coordinate 2
        else
            rand_X <= (Xcor * 10);//set the x coordinate location 
    end
    
    always @(posedge VGA_clk)
    begin   
        if(Ycor>46) // if y cor is to intersects with the  upper bounds it will be set at y coordinate 46
          begin
            rand_Y <= 435;// if x cor intersects with the bottom bound it will be set at y coordinate 2
        end
          else if (Ycor<2)
            rand_Y <= 20;
        else
            rand_Y <= (Ycor * 10);// otherwise it be set to the random generated y coordinate 
    end
endmodule
//-----------------------------------------------------------------------
module apple(VGA_clk, xCount, yCount, start, apple);//module for apple

    input VGA_clk, xCount, yCount, start;
    wire [9:0] appleX;//[9:0] since it can fit 640 pixels 
    wire [8:0] appleY;//[8:0] since it can fit 480 pixels
    reg apple_X, apple_Y;//location of apple
    wire [9:0]rand_X;
    wire [8:0]rand_Y;
    output apple;
    randomGen randGen1(VGA_clk, rand_X, rand_Y);// calling randomGen to find create a random spot for the apple
    
    assign appleX = 0;
    assign appleY = 0;
    
    always @(negedge VGA_clk)
    begin
        apple_X <= (xCount > appleX && xCount < (appleX + 20));
        apple_Y <= (yCount > appleY && yCount < (appleY + 20));
    end
    
    assign apple = apple_X && apple_Y;
endmodule

//-----------------------------------------------------------------------
module buttonInput(clk,left,right,direction);

input clk,left,right;
output reg [1:0]direction;

always @(posedge clk)
	begin
		if (left ==1 && right ==0)//left
			begin
				direction <= 2'b10;
			end

		else if (left ==0 && right ==1)//right
			begin
				direction <= 2'b01;
			end

		else if (left ==1 && right==1)//up
			begin
				direction <= 2'b11;
			end

		else if (left ==0 && right ==0)//down
			begin
				direction <= 2'b00;
			end

		else 
			begin
				direction <= direction;//continue direction
		end
	end
endmodule
