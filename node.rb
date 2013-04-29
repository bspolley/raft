require 'rubygems'
require 'bud'
require 'membership'
require 'node_protocol'
require 'follower'
require 'candidate'
require 'leader'
  
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
    scratch :mm, [:ident] => [:wiggy]
  end
  
  bootstrap do
  end
  
  bloom :follower do
    f <= server_type do |s|
      s if s.first == FOLLOWER
    end
    follower.sndRequestVote <~ (f * sndRequestVote).rights
    rspRequestVote <~ (f * follower.rspRequestVote).rights
    follower.sndAppendEntries <~ (f * sndAppendEntries).rights
    rspAppendEntries <~ (f * follower.rspAppendEntries).rights
    follower.log <= log
    log <+ follower.log
    follower.current_term <= current_term
    current_term <+ follower.current_term
    follower.member <= member
    #follower.commit_index <= commit_index
    #commit_index <+ follower.commit_index
  end
  
  bloom :candidate do
    c <= server_type do |s|
      s if s.first == CANDIDATE
    end
    candidate.sndRequestVote <~ (c * sndRequestVote).rights
    rspRequestVote <~ (c * candidate.rspRequestVote).rights
    candidate.sndAppendEntries <~ (c * sndAppendEntries).rights
    rspAppendEntries <~ (c * candidate.rspAppendEntries).rights
    candidate.log <= log
    log <+ candidate.log
    candidate.current_term <= current_term
    current_term <+ candidate.current_term
    candidate.member <= member
    #candidate.commit_index <= commit_index
    #commit_index <+ candidate.commit_index
  end
  
  bloom :leader do
    l <= server_type do |s|
      s if s.first == LEADER
    end
    leader.sndRequestVote <~ (l * sndRequestVote).rights
    rspRequestVote <~ (l * leader.rspRequestVote).rights
    leader.sndAppendEntries <~ (l * sndAppendEntries).rights
    rspAppendEntries <~ (l * leader.rspAppendEntries).rights
    leader.log <= log
    log <+ leader.log
    leader.current_term <= current_term
    current_term <+ leader.current_term
    leader.member <= member
    leader.commit_index <= commit_index
    commit_index <+ leader.commit_index
  end
end