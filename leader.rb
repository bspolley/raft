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
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => inputSndRequestVote.schema
    periodic :heartbeat, 0.02
    scratch :max_index, [] => [:index]
    scratch :ip_port_scratch, [] => [:grr]
    scratch :log_max, [] => [:index, :term, :entry]
    scratch :leader, [] => [:state]
  end
  
  bloom :leader_election do
    better_candidate <= inputSndRequestVote do |s|
      s if s.term > current_term.first.first
    end
    server_type <= better_candidate.argagg(:choose, [], :candidate) do |p|
      [NodeProtocol::FOLLOWER]
    end
    #TODO: Step down if we get an append entries that is of a term greater than ours
  end
  
  bloom :heartbeat do #<\3
    max_index <= log.argmax([], :index) do |l|
      [l.index]
    end
    log_max <= (log * max_index).lefts do |l|
      [l.index, l.term, l.command] if l.index == max_index.first.first #entry and command same thing
    end
    # channel   :sndAppendEntries, [:leader, :@follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    outputSndAppendEntries <= (heartbeat * member * leader).rights do |m|
      [ip_port_scratch.first.first, m.host, current_term.first.first, log_max.first.index, log_max.first.term, log_max.first.entry, commit_index.first.first] unless m.host == ip_port_scratch.first.first
    end
  end
  
  bloom :append_entries do
    outputSndAppendEntries <= (log * log * inputRspAppendEntries).combos do |l1, l2, i|
      if l1.index == i.index-1 and l2.index == i.index
        [ip_port_scratch.first.first, i.follower, current_term.first.first, l1.index, l1.term, l2.command, commit_index.first.first]
      end
    end
  end
  
  bloom :stdio do
    #stdio <~ log_max {|l| [["LOG MAX: #{l}"]]}
    #stdio <~ ip_port_scratch {|l| [["IP: #{l}"]]}
    #stdio <~ outputSndAppendEntries {|l| [["outSndAppendEntries: #{l}"]]}
    #stdio <~ inputRspAppendEntries {|l| [["inputRspAppendEntries: #{l}"]]}
    stdio <~ sndRequestVote {|s| [["Send Request Vote (in leader): #{s}"]]}
  end
  

end
