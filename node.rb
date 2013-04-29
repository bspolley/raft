require 'rubygems'
require 'bud'

module NodeProtocol

  state do
    channel   :SndRequestVote, [:candidate, :@me, :term, :last_index, :last_term] 
    channel   :RspRequestVote, [:@candidate, :me, :term, :granted]
    channel   :SndAppendEntries, [:leader, :@me, :term, :prev_index, :prev_term, :entry, :commit_index]
    channel   :RspAppendEntries, [:@leader, :me, :term, :success]
  end
end
  
module Node
  FOLLOWER = 1
  CANDIDATE = 2
  LEADER = 3
  include NodeProtocol
  include StaticMembership

  import Follower => :follower
  import Candidate => :candidate
  import Leader => :leader

  state do
    table :server_type, [] => [:state]
    scratch :f, server_type.schema #Follower 
    scratch :c, server_type.schema #Candidate 
    scratch :l, server_type.schema #Leader 
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
  end
  
  bootstrap do
    follower.member <= member
    candidate.member <= member
    leader.member <= member
  end
  
  bloom :follower do
    f <= server_type do |s|
      s if s.first == FOLLOWER
    end
    follower.SndRequestVote <~ (f * SndRequestVote).rights
    RspRequestVote <~ (f * follower.RspRequestVote).rights
    follower.SndAppendEntries <~ (f * SndAppendEntries).rights
    RspAppendEntries <~ (f * follower.RspAppendEntries).rights
    follower.log <= log
    log <+ follower.log
    follower.current_term <= current_term
    current_term <+ follower.current_term
    follower.commit_index <= commit_index
    commit_index <+ follower.commit_index
  end
  
  
  bloom :candidate do
    c <= server_type do |s|
      s if s.first == CANDIDATE
    end
    candidate.SndRequestVote <~ (c * SndRequestVote).rights
    RspRequestVote <~ (c * candidate.RspRequestVote).rights
    candidate.SndAppendEntries <~ (c * SndAppendEntries).rights
    RspAppendEntries <~ (c * candidate.RspAppendEntries).rights
    candidate.log <= log
    log <+ candidate.log
    candidate.current_term <= current_term
    current_term <+ candidate.current_term
    candidate.commit_index <= commit_index
    commit_index <+ candidate.commit_index
  end
  
  bloom :leader do
    l <= server_type do |s|
      s if s.first == LEADER
    end
    leader.SndRequestVote <~ (l * SndRequestVote).rights
    RspRequestVote <~ (l * leader.RspRequestVote).rights
    leader.SndAppendEntries <~ (l * SndAppendEntries).rights
    RspAppendEntries <~ (l * leader.RspAppendEntries).rights
    leader.log <= log
    log <+ leader.log
    leader.current_term <= current_term
    current_term <+ leader.current_term
    leader.commit_index <= commit_index
    commit_index <+ leader.commit_index
  end
end