class apb_env extends uvm_env;
  `uvm_component_utils(apb_env)
  apb_agent                     agent;
  apb_scoreboard                scb;
  apb_ral_block                 regmodel;
  apb_reg_adapter               adapter;
  uvm_reg_predictor #(apb_item) predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent     = apb_agent::type_id::create("agent", this);
    scb       = apb_scoreboard::type_id::create("scb", this);
    regmodel  = apb_ral_block::type_id::create("regmodel");
    regmodel.build();
    adapter   = apb_reg_adapter::type_id::create("adapter");
    predictor = uvm_reg_predictor#(apb_item)::type_id::create("predictor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.monitor.ap.connect(scb.item_export);
    agent.monitor.ap.connect(predictor.bus_in);
    predictor.map     = regmodel.default_map;
    predictor.adapter = adapter;
    regmodel.default_map.set_sequencer(agent.sequencer, adapter);
    regmodel.default_map.set_auto_predict(0);
  endfunction
endclass