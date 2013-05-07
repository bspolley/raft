require 'rubygems'
require 'bud'
require 'node_protocol'
require 'inner_node_protocol'

module Follower
  include NodeProtocol
  include InnerNodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :voted_for, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :max_index, [] => [:index]
    scratch :candidate_valid_vote, inputSndRequestVote.schema
    scratch :pos_votes, inputSndRequestVote.schema
    scratch :valid_vote, inputSndRequestVote.schema
    scratch :max_log_term, [] => [:term]
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :leader_election do
    max_index <= log.argmax([], :index) do |l|
      [l.index]
    end
    max_log_term <= (log * max_index).lefts do |l|
      [l.term ] if l.index == firsty(max_index)
    end
    pos_votes <= inputSndRequestVote do |s|
      if s.term > firsty(current_term)
        if log.empty? or s.last_term > firsty(max_log_term)
          s
        elsif s.last_term == firsty(max_log_term) and s.last_index >= firsty(max_index)
          s
        end
      end
    end
    candidate_valid_vote <= pos_votes.argagg(:choose, [], :candidate)
    valid_vote <= (candidate_valid_vote * pos_votes).rights(:candidate => :candidate)
    current_term <+- valid_vote {|s| [s.term]}
    outputRspRequestVote <= valid_vote do |s|
      [s.candidate, s.voter, s.term, true]
    end
  end
  
  bloom :stdio do
    #stdio <~ pos_votes {|p| [["Pos votes: #{p}"]]}
    #stdio <~ candidate_valid_vote {|c| [["Cand valid votes: #{c}"]]}
    #stdio <~ valid_vote{|v| [["Valid votes: #{v}"]]}
    #stdio <~ sndRequestVote {|s| [["Send Request Vote: #{s}"]]}
    #stdio <~ rspRequestVote {|s| [["Response Request Vote: #{s}"]]}
  end
  
  def firsty(something)
    something.first.first
  end
  
end