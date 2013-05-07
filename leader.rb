require 'rubygems'
require 'bud'
require 'node_protocol'

module Leader
  include NodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => sndRequestVote.schema
    periodic :heartbeat, 0.02
    scratch :max_index, [] => [:index]
    scratch :log_max, [] => [:index, :term, :entry]
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :leader_election do
    better_candidate <= sndRequestVote do |s|
      s if s.term > firsty(current_term)
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
      [l.index, l.term, l.command] if l.index == firsty(max_index)
    end
    # channel   :sndAppendEntries, [:leader, :@follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    sndAppendEntries <~ (heartbeat * member).rights do |m|
      [ip_port, m.host, firsty(current_term), log_max.first.index, log_max.first.term, log_max.first.entry, firsty(commit_index)] unless m.host == ip_port
    end
  end
  
  

end
