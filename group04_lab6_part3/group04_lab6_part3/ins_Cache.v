
`timescale  1ns/100ps

module ins_cache (clock,PC,reset,c_instruction,c_busywait,mem_instruction,imem_read,imem_address,imem_busywait);

    input  clock, reset,imem_busywait;  //imem_busywait:busywait signal which comes from the ins memory to the ins cache
    input [31:0] PC;
    input [127:0] mem_instruction;      //data block which comes from ins_mem to the ins_cache
    
    output reg imem_read,c_busywait;   //imem_read:read signal which goes into the memory from the cache
    output reg [5:0] imem_address;     //address which goes from the ins cache into the ins memory
    output reg [31:0] c_instruction;   //instruction that goes into the cpu from the ins cache
    wire validbit;
    reg [31:0] instruction;            //temp reg to store the instruction           

   wire [1:0] offset;
   wire [2:0] index;
   wire [2:0]  tag;
   reg [131:0] iCache [7:0];           //8 132 bits instruction cache to store instructions
   wire [127:0] BLOCK;                 //128 bit instruction block
   wire hit;
  
   always@(BLOCK[31:0],BLOCK[63:32],BLOCK[95:64],BLOCK[127:96],offset) //instruction word is selected based on the offset from the block 

   begin
  
   #1
   case(offset)
         2'b00 :instruction=BLOCK[31:0]; 
         2'b01 :instruction=BLOCK[63:32];
         2'b10 :instruction=BLOCK[95:64];
         2'b11 :instruction=BLOCK[127:96];
   
  endcase
 
  end
    
  //tag comparison and deciding whether its a hit or a miss
   
    
assign #0.9 hit=(tag==PC[9:7] && validbit) ? 1:0;
   
    


always @(posedge clock)begin

if(!hit) begin
c_busywait = 1'b1;
end
else
c_busywait=1'b0;
end

always @(instruction)
begin
//when hit is detected,instruction is sent to the CPU
if(hit)begin
	
c_instruction = instruction;

end
end

//instruction in the cache is seperated into segments

assign #1 BLOCK = iCache[ PC[6:4]][127:0]; //instruction block
assign #1  tag = iCache[ PC[6:4]][130:128]; //tag value
assign #1 validbit = iCache[ PC[6:4]][131];	//valid bit
assign #1 index = PC[6:4];				//index of the cache entry
assign #1 offset = PC[3:2];				//offset
		

	




/* Cache Controller FSM Start */

    parameter IDLE = 2'b00, IMEM_READ = 2'b01,IC_WRITE=2'b10;
    reg [1:0] state, nextstate;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
            if(!hit)
              nextstate=IMEM_READ;
            else
              nextstate=IDLE; 
           IMEM_READ:
            if(!imem_busywait)
               nextstate=IC_WRITE;
            else
                nextstate=IMEM_READ;
        IC_WRITE:
             
               nextstate=IDLE; 
               
        endcase

    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
               imem_read = 0;
               imem_address = 6'dx;
               
            end
         
            IMEM_READ: 
            begin
                imem_read = 1;
                imem_address ={tag,index};
                c_busywait=1;
                
            end


          
	IC_WRITE:
            begin
                imem_read = 1'd0;
                imem_address = 6'dx;
                
              
                 #1
				iCache[index][127:0] = mem_instruction;	//write a data block to the cache
				iCache[index][130:128] = PC[9:7];	//tag
			        iCache[index][131] = 1'd1;	//valid bit
			
            end
            
            
            
            
        endcase
    end
    integer j;
   
    always @(posedge clock, reset)
    
    begin
        if(reset)
        begin
            state = IDLE;
            c_busywait=1'b0;
             #1;
             for( j=0;j<8;j=j+1)
            begin
            iCache[j] = 131'b0;
            end
        end
        
        else begin
            state = nextstate;
         end
    end
    /* Cache Controller FSM End */

endmodule
