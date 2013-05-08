require 'rubygems'
require 'bud'
require 'node_protocol'
require 'inner_node_protocol'

module Leader
  include NodeProtocol
  include InnerNodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => inputSndRequestVote.schema
    periodic :heartbeat, 0.02
    scratch :max_index, [] => [:index]
    scratch :log_max, [] => [:index, :term, :entry]
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :leader_election do
    better_candidate <= inputSndRequestVote do |s|
      s if s.term > current_term.first.first
    end
    server_type <= better_candidate.argagg(:choose, [], :candidate) do |p|
      [NodeProtocol::FOLLOWER]
    end
  end
  
  bloom :heartbeat do #<\3
    max_index <= log.argmax([], :index) do |l|
      [l.index]
    end
    log_max <= (log * max_index).lefts do |l|
      [l.index, l.term, l.command] if l.index == max_index.first.first #entry and command same thing
    end
    # channel   :sndAppendEntries, [:leader, :@follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    outputSndAppendEntries <= (heartbeat * member).rights do |m|
      [ip_port, m.host, current_term.first.first, log_max.first.index, log_max.first.term, log_max.first.entry, commit_index.first.first] unless m.host == ip_port
    end
  end
  
  bloom :stdio do
    #stdio <~ log_max {|l| [["LOG MAX: #{l}"]]}
  end
  

end
