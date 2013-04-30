require 'rubygems'
require 'bud'
require 'node_protocol'
#channel   :SndRequestVote, [:candidate, :@me, :term, :last_index, :last_term] 
#channel   :RspRequestVote, [:@candidate, :me, :term, :granted]
#channel   :SndAppendEntries, [:leader, :@me, :term, :prev_index, :prev_term, :entry, :commit_index]
#channel   :RspAppendEntries, [:@leader, :me, :term, :success]
module Candidate
  include NodeProtocol
  
  state do
    table :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => sndRequestVote.schema
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
  
  bloom :stdio do 
    #stdio <~ server_type {|s| [["Server type: #{s}"]]}
    stdio <~ sndRequestVote {|s| [["Send Request Vote: #{s}"]]}
    #stdio <~ better_candidate {|s| [["Better Candidate: #{s}"]]}
  end
  
  def firsty(something)
    something.first.first
  end
  
end