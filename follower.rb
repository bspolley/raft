require 'rubygems'
require 'bud'
require 'node_protocol'

module Follower
  include NodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :voted_for, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :max_index, [] => [:index]
    scratch :candidate_valid_vote, sndRequestVote.schema
    scratch :pos_votes, sndRequestVote.schema
    scratch :valid_vote, sndRequestVote.schema
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :leader_election do
    max_index <= log.argmax([:index], :index)
    pos_votes <= sndRequestVote do |s|
      if s.term > firsty(current_term)
        if log.empty? or s.last_term > log[max_index.first].term
          s
        elsif s.last_term == log[max_index.first].term and s.last_index >= max_index.first
          s
        end
      end
    end
    candidate_valid_vote <= pos_votes.argagg(:choose, [], :candidate)
    valid_vote <= (candidate_valid_vote * pos_votes).rights(:candidate => :candidate)
    current_term <+- valid_vote {|s| [s.term]}
    rspRequestVote <~ valid_vote do |s|
      [s.candidate, s.voter, s.term, true]
    end
  end
  
  bloom :stdio do
    #stdio <~ pos_votes {|p| [["Pos votes: #{p}"]]}
    #stdio <~ candidate_valid_vote {|c| [["Cand valid votes: #{c}"]]}
    stdio <~ valid_vote{|v| [["Valid votes: #{v}"]]}
    #stdio <~ sndRequestVote {|s| [["Send Request Vote: #{s}"]]}
  end
  
  def firsty(something)
    something.first.first
  end
  
end