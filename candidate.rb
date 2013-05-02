require 'rubygems'
require 'bud'
require 'node_protocol'
#channel   :SndRequestVote, [:candidate, :@voter, :term, :last_index, :last_term] 
#channel   :RspRequestVote, [:@candidate, :voter, :term, :granted]
#channel   :SndAppendEntries, [:leader, :@follower, :term, :prev_index, :prev_term, :entry, :commit_index]
#channel   :RspAppendEntries, [:@leader, :follower, :term, :success]
module Candidate
  include NodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => sndRequestVote.schema
    scratch :ring, [:name, :time_out]
    periodic :timer, 0.02
    table :votes, [:client]
    scratch :max_index, [] => [:index]
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :empty_votes do
    votes <- (better_candidate * votes).rights
    votes <- (ring * votes).rights
    votes <- (server_type * votes).pairs do |s, v|
      if firsty(server_type) == NodeProtocol::LEADER
    end
  end
  
  bloom :leader_election do
    better_candidate <= sndRequestVote do |s|
      s if s.term > firsty(current_term)
    end
    is_follower <= better_candidate.argagg(:choose, [], :candidate) do |p|
      [NodeProtocol::FOLLOWER]
    end
    max_index <= log.argmax([:index], :index)
    sndRequestVote <~ (timer * member).rights do |m|
      [m.host, ip_port, current_term, max_index.first, log[max_index.first].term]
    end
    votes <= rspRequestVote do |r|
      [r.voter] 
    end
    is_leader <= votes.group([], count(:client)) do |v|
      [NodeProtocol::LEADER] if v.first > member.count/2.0
    end
    server_type <= ["True"].each do
      unless is_follower.empty? 
        is_follower
      elsif not is_leader.empty?
        is_leader
      end
    end
    current_term <+- ring do
      [firsty(current_term) + 1] if firsty(server_type) == NodeProtocol::CANDIDATE
    end
  end
  
  bloom :stdio do 
    #stdio <~ server_type {|s| [["Server type: #{s}"]]}
    stdio <~ sndRequestVote {|s| [["Send Request Vote: #{s}"]]}
    #stdio <~ better_candidate {|s| [["Better Candidate: #{s}"]]}
  end
  
  def firsty(something)
    something.first.first
  end
  
end