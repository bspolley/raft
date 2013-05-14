require 'rubygems'
require 'bud'
require 'node_protocol'
require 'inner_node_protocol'

module Leader
  include NodeProtocol
  include InnerNodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    scratch :log, [:index] => [:term, :command]
    scratch :current_term, [] => [:term]
    scratch :commit_index, [] => [:index]
    scratch :new_commit_index, commit_index.schema
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => inputSndRequestVote.schema
    periodic :heartbeat, 0.1
    scratch :max_index, [] => [:index]
    scratch :ip_port_scratch, [] => [:grr]
    scratch :log_max, [] => [:index, :term, :entry]
    scratch :leader, [] => [:state]
    scratch :new_entry, [:entry_id] => [:entry]
    scratch :log_add, [:index] => [:term, :command]
    table :new_entry_buffer, new_entry.schema
    scratch :chosen_one, new_entry.schema
    scratch :good_chosen_one, new_entry.schema
    scratch :repeat_entry, new_entry.schema
    table :follower_logs, [:follower, :index]
    scratch :commited, [:index]
  end
  
  bloom :leader_election do
    better_candidate <= inputSndRequestVote do |s|
      s if s.term > current_term.first.first
    end
    server_type <= better_candidate.argagg(:choose, [], :candidate) do |p|
      [NodeProtocol::FOLLOWER]
    end
    server_type <= inputSndAppendEntries do |s|
      [NodeProtocol::FOLLOWER] if s.term > current_term.first.first
    end
  end
  
  bloom :heartbeat do #<\3
    max_index <= log.argmax([], :index) do |l|
      [l.index]
    end
    log_max <= (log * max_index).lefts do |l|
      [l.index, l.term, l.command] if l.index == max_index.first.first #entry and command same thing bad naming convention
    end
    outputSndAppendEntries <= (log * heartbeat * member * leader).combos do |lo, h, m, le|
      if lo.index == max_index.first.index - 1
        [ip_port_scratch.first.first, m.host, current_term.first.first, lo.index, lo.term, log_max.first.entry, commit_index.first.first] unless m.host == ip_port_scratch.first.first
      elsif max_index.first.index == 0
        [ip_port_scratch.first.first, m.host, current_term.first.first, lo.index - 1, lo.term, log_max.first.entry, commit_index.first.first] unless m.host == ip_port_scratch.first.first
      end
    end
  end
  
  bloom :rsp_append_entries do
    outputSndAppendEntries <= (log * log * inputRspAppendEntries).combos do |l1, l2, i|
      if l1.index == i.index-1 and l2.index == i.index
        [ip_port_scratch.first.first, i.follower, current_term.first.first, l1.index, l1.term, l2.command, commit_index.first.first]
      end
    end
  end
  
  bloom :commit_index do
    follower_logs <= inputRspAppendEntries do |i|
      [i.follower, i.index-1]
    end
    #TODO: Make sure this is safe (ie something from current term included in the log)
    commited <= commit_index
    commited <= follower_logs.group([:index], count(:nums)) do |l|
      [l[0]] if (l[1] + 1) > member.count/2.0
    end
    follower_logs <- (commited * follower_logs).rights(:index => :index)
    new_commit_index <= (commited * leader).lefts.argagg(:max, [], :index)
  end

  bloom :append_entries do
    new_entry_buffer <= new_entry
    chosen_one <= new_entry_buffer.argagg(:choose, [], :entry)
    repeat_entry <= (chosen_one * log).pairs do |c, l|
      c if c.entry_id.to_s + " " + c.entry == l.command
    end
    good_chosen_one <= chosen_one.notin(repeat_entry)
    log_add <= good_chosen_one do |e|
      [log_max.first.index + 1, current_term.first.first, e.entry_id.to_s + " " + e.entry]
    end
    new_entry_buffer <- chosen_one
  end

  
  bloom :stdio do
    #stdio <~ log_max {|l| [["LOG MAX: #{l}"]]}
    #stdio <~ ip_port_scratch {|l| [["IP: #{l}"]]}
    #stdio <~ outputSndAppendEntries {|l| [["outSndAppendEntries: #{l}"]]}
    #stdio <~ inputRspAppendEntries {|l| [["inputRspAppendEntries: #{l}"]]}
    #stdio <~ sndRequestVote {|s| [["Send Request Vote (in leader): #{s}"]]}
  end
  

end
