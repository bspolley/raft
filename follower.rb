require 'rubygems'
require 'bud'
require 'node_protocol'
require 'inner_node_protocol'

module Follower
  include NodeProtocol
  include InnerNodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    scratch :log, [:index] => [:term, :command]
    scratch :log_add, [:index] => [:term, :command]
    scratch :log_del, [:index] => [:term, :command]
    scratch :current_term, [] => [:term]
    scratch :next_current_term, [] => [:term]
    table :voted_for, [] => [:term]
    scratch :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :max_index, [] => [:index]
    scratch :candidate_valid_vote, inputSndRequestVote.schema
    scratch :pos_votes, inputSndRequestVote.schema
    scratch :valid_vote, inputSndRequestVote.schema
    scratch :log_max_term, [] => [:term]
    scratch :append_entries, inputSndAppendEntries.schema
    scratch :append_entry, inputSndAppendEntries.schema
    scratch :reset, [] => [:timer]
    scratch :response_append_entry, outputRspAppendEntries.schema
    scratch :command_buffer, command.schema
  end
  
  bloom :leader_election do
    max_index <= log.argmax([], :index) do |l|
      [l.index]
    end
    log_max_term <= (log * max_index).lefts do |l|
      [l.term ] if l.index == firsty(max_index)
    end
    pos_votes <= inputSndRequestVote do |s|
      if s.term > firsty(current_term)
        if s.last_term > firsty(log_max_term)
          s
        elsif s.last_term == firsty(log_max_term) and s.last_index >= firsty(max_index)
          s
        end
      end
    end
    candidate_valid_vote <= pos_votes.argagg(:choose, [], :candidate)
    valid_vote <= (candidate_valid_vote * pos_votes).rights(:candidate => :candidate)
    next_current_term <= valid_vote {|s| [s.term]}
    outputRspRequestVote <= valid_vote do |s|
      [s.candidate, s.voter, s.term, true]
    end
  end
  
  bloom :append_entries do
    append_entries <= inputSndAppendEntries do |a|
      a if a.term >= current_term.first.first
    end
    append_entry <= append_entries.argmax([], :term)
    next_current_term <= append_entry do |a|
      [a.term]
    end
    reset <= append_entry do
      ["RESET"]
    end
    #Indexes equal
    log_add <= append_entry do |a|
      if max_index.first.first == a.prev_index and 
        log_max_term.first.first == a.prev_term
        [max_index.first.first+1, a.term, a.entry]
      end
    end
    #Follower max index less than leader's index
    outputRspAppendEntries <= append_entry do |a|
      if max_index.first.first < a.prev_index 
        [a.leader, a.follower, max_index.first.first+1]
      end
    end
    #Follower index greater than leader's index
    outputRspAppendEntries <= append_entry do |a|
      if max_index.first.first == a.prev_index and log_max_term.first.first != a.prev_term
        [a.leader, a.follower, a.prev_index]
      end
    end
    #Send same request after we del uncommitted entries from our log
    outputRspAppendEntries <= append_entry do |a|
      if max_index.first.first > a.prev_index
        [a.leader, a.follower, a.prev_index+1]
      end
    end
    log_del <= (log*append_entry).pairs do |l,a|
      if max_index.first.first > a.prev_index and l.index > a.prev_index
        l
      end
    end
    log_del <= (log*append_entry).pairs do |l,a|
      if max_index.first.first == a.prev_index and log_max_term.first.first != a.prev_term and
        l.index == max_index.first.first
        l
      end
    end
      
  end
  
  bloom :forward_commands do
    outputSndCommand <= (command_buffer * append_entry).pairs do |c, a|
      [a.leader, a.follower, c.entry_id, c.entry]
    end
  end 
  
  bloom :stdio do
    #stdio <~ pos_votes {|p| [["Pos votes: #{p}"]]}
    #stdio <~ candidate_valid_vote {|c| [["Cand valid votes: #{c}"]]}
    #stdio <~ valid_vote{|v| [["Valid votes: #{v}"]]}
    #stdio <~ sndRequestVote {|s| [["Send Request Vote (in follower): #{s}"]]}
    #stdio <~ rspRequestVote {|s| [["Response Request Vote: #{s}"]]}
    #stdio <~ append_entry {|a| [["APPEND: #{a}"]]}
  end
  
  def firsty(something)
    something.first.first
  end
  
end