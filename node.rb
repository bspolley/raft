require 'rubygems'
require 'bud'
require 'membership'
require 'node_protocol'
require 'follower'
require 'candidate'
require 'leader'
  
module Node
  include NodeProtocol
  include StaticMembership
  include RandomTimer
  
  import Follower => :follower
  import Candidate => :candidate
  import Leader => :leader

  state do
    table :server_type, [] => [:state]
    scratch :f, server_type.schema #Follower 
    scratch :c, server_type.schema #Candidate 
    scratch :l, server_type.schema #Leader 
    scratch :ringing, [] => [:blah]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :election_timeout do
    ringing <= server_type do 
      ring.empty? ? [" "] : [] #Independent Party
    end
  end
  
  bloom :follower do
    f <= server_type do |s|
      s if s.first == NodeProtocol::FOLLOWER
    end
    follower.sndRequestVote <~ (ringing * f * sndRequestVote).rights
    rspRequestVote <~ (f * follower.rspRequestVote).rights
    follower.sndAppendEntries <~ (f * sndAppendEntries).rights
    rspAppendEntries <~ (f * follower.rspAppendEntries).rights
    follower.log <= log
    log <+ follower.log
    follower.current_term <= current_term
    current_term <+ follower.current_term
    follower.member <= member
    follower.commit_index <= commit_index
    commit_index <+ follower.commit_index
    server_type <= follower.server_type
  end
  
  bloom :candidate do
    c <= server_type do |s|
      s if s.first == NodeProtocol::CANDIDATE
    end
    candidate.sndRequestVote <~ (ringing * c * sndRequestVote).rights
    rspRequestVote <~ (c * candidate.rspRequestVote).rights
    candidate.sndAppendEntries <~ (c * sndAppendEntries).rights
    rspAppendEntries <~ (c * candidate.rspAppendEntries).rights
    candidate.log <= log
    log <+ candidate.log
    candidate.current_term <= current_term
    current_term <+ candidate.current_term
    candidate.member <= member
    candidate.commit_index <= commit_index
    commit_index <+ candidate.commit_index
    server_type <= candidate.server_type
    sndRequestVote <~ candidate.sndRequestVote
  end
  
  bloom :leader do
    l <= server_type do |s|
      s if s.first == NodeProtocol::LEADER
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
    server_type <= leader.server_type
  end
end