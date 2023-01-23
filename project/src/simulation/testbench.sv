`include "uvm_macros.svh"
import uvm_pkg::*;

// Sequence Item
class ps2_item extends uvm_sequence_item;

	//rand bit kbclk;
	rand bit kbdata;
	
	bit [15:0] led;
	
	`uvm_object_utils_begin(ps2_item)
		//`uvm_field_int(kbclk, UVM_DEFAULT)
		`uvm_field_int(kbdata, UVM_DEFAULT | UVM_BIN)
		`uvm_field_int(led, UVM_NOPRINT)
	`uvm_object_utils_end
	
	function new(string name = "ps2_item");
		super.new(name);
	endfunction
	
	virtual function string my_print();
		return $sformatf(
			"kbdata = %1b led = %16b",
			 kbdata, led
		);
	endfunction

endclass

// Sequence
class generator extends uvm_sequence;

	`uvm_object_utils(generator)
	
	function new(string name = "generator");
		super.new(name);
	endfunction
	
	int num = 800;

	virtual task body();
		
		for ( int i = 0; i < num; i++) begin

				ps2_item item = ps2_item::type_id::create("item");
				start_item(item);
				item.randomize();
				item.kbdata = 0;
				`uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_LOW)
				item.print();
				finish_item(item);

			for (int j = 0 ; j< 10 ; j++ ) begin
				ps2_item item = ps2_item::type_id::create("item");
				start_item(item);
				item.randomize();
				item.print();
				finish_item(item);
				
			end
		
			
		end


	endtask
	
endclass



// Driver
class driver extends uvm_driver #(ps2_item);
	
	`uvm_component_utils(driver)
	
	function new(string name = "driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Driver", "No interface.")
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		@(posedge vif.clk); 
		forever begin
			ps2_item item;
			seq_item_port.get_next_item(item);
			`uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_LOW)

				vif.kbdata = item.kbdata;
			
			@(negedge vif.kbclk); 
			seq_item_port.item_done();
		end
	endtask
	
endclass

// Monitor
class monitor extends uvm_monitor;
	
	`uvm_component_utils(monitor)
	
	function new(string name = "monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;
	uvm_analysis_port #(ps2_item) mon_analysis_port;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Monitor", "No interface.")
		mon_analysis_port = new("mon_analysis_port", this);
	endfunction
	
	virtual task run_phase(uvm_phase phase);	
		super.run_phase(phase);
		@(posedge vif.clk);
		forever begin
			ps2_item item = ps2_item::type_id::create("item");
			@(posedge vif.clk);

			item.kbdata = vif.kbdata;
			item.led = vif.led;

			`uvm_info("Monitor", $sformatf("%s", item.my_print()), UVM_LOW)
			mon_analysis_port.write(item);
		end
	endtask
	
endclass

// Agent
class agent extends uvm_agent;
	
	`uvm_component_utils(agent)
	
	function new(string name = "agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	driver d0;
	monitor m0;
	uvm_sequencer #(ps2_item) s0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		d0 = driver::type_id::create("d0", this);
		m0 = monitor::type_id::create("m0", this);
		s0 = uvm_sequencer#(ps2_item)::type_id::create("s0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		d0.seq_item_port.connect(s0.seq_item_export);
	endfunction
	
endclass

// Scoreboard
class scoreboard extends uvm_scoreboard;
	
	`uvm_component_utils(scoreboard)
	
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	uvm_analysis_imp #(ps2_item, scoreboard) mon_analysis_imp;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		mon_analysis_imp = new("mon_analysis_imp", this);
	endfunction
	
	bit [15:0] ps2_led=0;
	int cnt = 0;
	bit[10:0] temp=0;
	int finished = 0;
	
	virtual function write(ps2_item item);
		
		 temp[cnt]	= item.kbdata;
		 cnt ++;

		 if(cnt == 11) begin
			 if(finished == 1) begin
				 finished = 0;
			 end
			 else begin
				if(temp[7:0] == 8'hf0) begin
					ps2_led = {temp[7:0], ps2_led[7:0]};
					finished = 1;

				end 

				else if(temp[7:0] == 8'he0) begin
					ps2_led = {temp[7:0], ps2_led[7:0]};
				end

				else begin
					if(ps2_led[15:8] != 8'he0 ) begin
						ps2_led[15:8]=8'h00;
					end
						ps2_led = {ps2_led[15:8],temp[7:0]};
				end
			end
		
			cnt=0; 

			if (ps2_led == item.led)
				`uvm_info("Scoreboard", $sformatf("PASS!"), UVM_LOW)
			else
				`uvm_error("Scoreboard", $sformatf("FAIL! expected = %16b, got = %16b", ps2_led, item.led))
				

		 end

	endfunction
	
endclass

// Environment
class env extends uvm_env;
	
	`uvm_component_utils(env)
	
	function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	agent a0;
	scoreboard sb0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a0 = agent::type_id::create("a0", this);
		sb0 = scoreboard::type_id::create("sb0", this);
	endfunction
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		a0.m0.mon_analysis_port.connect(sb0.mon_analysis_imp);
	endfunction
	
endclass

// Test
class test extends uvm_test;

	`uvm_component_utils(test)
	
	function new(string name = "test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual ps2_if vif;

	env e0;
	generator g0;
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ps2_if)::get(this, "", "ps2_vif", vif))
			`uvm_fatal("Test", "No interface.")
		e0 = env::type_id::create("e0", this);
		g0 = generator::type_id::create("g0");
	endfunction
	
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		
		//vif.rst_n <= 0;
		//#20 vif.rst_n <= 1;
		
		g0.start(e0.a0.s0);
		phase.drop_objection(this);
	endtask

endclass

// Interface
interface ps2_if (
	input bit clk,
	input bit kbclk
);

	//logic kbclk;
	logic kbdata;
    logic [15:0] led;

endinterface

// Testbench
module testbench;

	reg clk;
	reg kbclk;
	
	ps2_if dut_if (
		.clk(clk),
		.kbclk(kbclk)
	);
	
	ps2 dut (
		.PS2_KBCLK(kbclk),
		.CLOCK_50(clk),
		
		.PS2_KBDAT(dut_if.kbdata),
		
		.led(dut_if.led)
	);

	initial begin
		clk = 0;
		kbclk = 0;
		forever begin
			#10 clk = ~clk;
			#7 kbclk = ~kbclk;
		end
	end

	initial begin
		uvm_config_db#(virtual ps2_if)::set(null, "*", "ps2_vif", dut_if);
		run_test("test");
	end

endmodule
