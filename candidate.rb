require 'rubygems'
require 'bud'
require 'node_protocol'
require 'inner_node_protocol'
#channel   :SndRequestVote, [:candidate, :@voter, :term, :last_index, :last_term] 
#channel   :RspRequestVote, [:@candidate, :voter, :term, :granted]
#channel   :SndAppendEntries, [:leader, :@follower, :term, :prev_index, :prev_term, :entry, :commit_index]
#channel   :RspAppendEntries, [:@leader, :follower, :term, :success]
module Candidate
  include NodeProtocol
  include InnerNodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => inputSndRequestVote.schema
    scratch :ring, [:name, :time_out]
    periodic :timer, 0.02
    table :votes, [:client]
    scratch :max_index, [] => [:index]
    scratch :log_max_term, [] => [:term]
    scratch :is_follower, [] => [:state]
    scratch :is_leader, [] => [:state]
    scratch :tmp_server_type, [:state]
    scratch :next_current_term, [] => [:term]
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  # This clears all votes if you have to 
  bloom :empty_votes do
    votes <- (better_candidate * votes).rights
    votes <- (ring * votes).rights
    votes <- (server_type * votes).pairs do |s, v|
      v if server_type.first.first == NodeProtocol::LEADER
    end
  end
  #TODO: step down if get hearbeat from Leader if >= term
  bloom :leader_election do
    better_candidate <= inputSndRequestVote do |s|
      s if s.term > current_term.first.first
    end
    is_follower <= better_candidate.argagg(:choose, [], :candidate) do |p|
      [NodeProtocol::FOLLOWER]
    end
    max_index <= log.argmax([], :index) do |l|
      [l.index]
    end
    log_max_term <= log.argmax([], :index) do |l|
      [l.term] 
    end
    outputSndRequestVote <= (timer * member).rights do |m|
      [m.host, ip_port, current_term.first.first, max_index.first.first, log_max_term.first.first]
    end
    votes <= inputRspRequestVote do |r|
      [r.voter] 
    end
    is_leader <= votes.group([], count(:client)) do |v|
      [NodeProtocol::LEADER] if (v.first + 1) > member.count/2.0 # +1 voting for self
    end
    tmp_server_type <= is_follower
    tmp_server_type <= is_leader
    server_type <= tmp_server_type.argmin([], :state)
    next_current_term <= ring do
      [current_term.first.first + 1] if server_type.empty?
    end
  end
  
  bloom :append_entries do
    is_follower <= inputSndAppendEntries do |a|
      [NodeProtocol::FOLLOWER] if a.term >= current_term.first.first
    end
  end
  
  bloom :stdio do 
    #stdio <~ server_type {|s| [["Server type: #{s}"]]}
    #stdio <~ inputSndRequestVote {|s| [["Send Request Vote: #{s}"]]}
    #stdio <~ better_candidate {|b| [["Better candidate: #{b}"]]}
    #stdio <~ is_follower {|f| [["Is follower: #{f}"]]}
    #stdio <~ tmp_server_type {|t| [["TMP Server Type: #{t}"]]}
    #stdio <~ current_term {|c| [["Current term: #{c}"]]}
    #stdio <~ ring {|c| [["RING!!!"]]}
    #stdio <~ next_current_term {|c| [["Next current term: #{c}"]]}
    #stdio <~ better_candidate {|s| [["Better Candidate: #{s}"]]}
    #stdio <~ [["MEMBER: #{member.count}"]]
    #stdio <~ outputSndRequestVote {|t| [["REQ: #{t}"]]}
    #stdio <~ timer {|t| [["Timer: #{t}"]]}
    #stdio <~ log {|l| [["LOG: #{l}"]]}
    
  end
  
end
