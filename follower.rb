require 'rubygems'
require 'bud'
require 'node_protocol'
#channel   :SndRequestVote, [:candidate, :@me, :term, :last_index, :last_term] 
#channel   :RspRequestVote, [:@candidate, :me, :term, :granted]
#channel   :SndAppendEntries, [:leader, :@me, :term, :prev_index, :prev_term, :entry, :commit_index]
#channel   :RspAppendEntries, [:@leader, :me, :term, :success]
module Follower
  include NodeProtocol
  
  state do
    table :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :voted_for, [] => [:term]
    scratch :valid_vote, [] => [:term]
    scratch :tester, [:term, :a, :b, :c]
  end
  
  bloom :leader_election do
    current_term <+ sndRequestVote do |s|
      p current_term
      p "-----"
      #[s.term] if s.term > current_term.first
    end
    voted_for <= sndRequestVote do |s|
      p current_term
      p "-----"
      #[s.term] if s.term > current_term.first
    end
    #first <= [SndRequestVote.reject {|s| s if s.term <= current_term.first}]
    #tester <= (voted_for * first).rights do |s|
    #  [s.candidate, s.me, s.term, true]
    #end
  end
  
end