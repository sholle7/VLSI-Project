module ps2(
    input wire PS2_KBCLK, // Clock pin form keyboard
    input wire CLOCK_50,
    input wire PS2_KBDAT, //Data pin form keyboard
    output reg [15:0] led //Printing input data to led
);
    reg [7:0] data_curr;
    reg [3:0] b;
    reg flag;

    reg [7:0] buffer[1:0];

   
    reg len;
    reg finished;

    initial
    begin
        b<=4'h1;
        flag<=1'b0;
        data_curr<=8'h00;
        led<=16'h00;

        buffer[0] <= 8'b0;
        buffer[1] <= 8'b0;

        len<=1;
        finished<=0;

     
       
    end 
    always @(negedge PS2_KBCLK) //Activating at negative edge of clock from keyboard
    begin
    
            case(b)
                1:; //first bit
                2:data_curr[0]<=PS2_KBDAT;
                3:data_curr[1]<=PS2_KBDAT;
                4:data_curr[2]<=PS2_KBDAT;
                5:data_curr[3]<=PS2_KBDAT;
                6:data_curr[4]<=PS2_KBDAT;
                7:data_curr[5]<=PS2_KBDAT;
                8:data_curr[6]<=PS2_KBDAT;
                9:data_curr[7]<=PS2_KBDAT;
                10:flag<=1'b1; //Parity bit
                11:flag<=1'b0; //Ending bit
                default:;

            endcase

            if (( b == 1 ) && ( ~PS2_KBDAT )) begin
	            b <= 4'd2;
	            //parity <= 1;
	            //error <= 0;
	        end else if (( b >= 2 ) && ( b < 11 ))
	            b <= b + 4'h1;
	        else begin
				b <= 4'h1;
	        end

    end


    always@(posedge flag) // Printing data obtained to led
    begin
        //led={buffer[1],buffer[0]};   

        if(finished == 1 && len>0) begin
            len=len-1;

            if(len == 0 ) begin
                finished=0;
                len=1;
            end
             
        end
        else begin

            if(data_curr== 8'he0) begin
            buffer[1]=data_curr;
            len=1;
       end 
       
       else if(data_curr==8'hf0)
            begin
             buffer[1]=data_curr;   
             finished=1;
        end

        else begin

            if(buffer[1] != 8'he0 ) begin
                buffer[1]=8'h00;
            end
         
            buffer[0]=data_curr;
             
         end
            
        end

       

      led={buffer[1],buffer[0]};           
               
    end 
endmodule


