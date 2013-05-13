require 'rubygems'
require 'bud'
require 'membership'
require 'node_protocol'
require 'follower'
require 'candidate'
require 'leader'
require 'random_timer'
  
module Node
  include NodeProtocol
  include StaticMembership
  include RandomTimer
  
  import Follower => :follower
  import Candidate => :candidate
  import Leader => :leader

  #TODO: need to add responses to append entries so leader can update commit index
  #TODO: command inputs and acks back to client
  state do
    table :server_type, [] => [:state]
    scratch :f, server_type.schema #Follower 
    scratch :c, server_type.schema #Candidate 
    scratch :l, server_type.schema #Leader 
    scratch :not_ringing, [] => [:blah]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    #table :leader, [] => [:ip]
    #table :command_buffer, [:command]
  end
  
  bootstrap do
    log <= [[0,0,'dummy']]
    current_term <= [[0]]
    server_type <= [[NodeProtocol::FOLLOWER]]
    commit_index <= [[0]]
  end
  
  #bloom :command do
    #command_buffer <= command
  #end
  
  bloom :election_timeout do
    not_ringing <= server_type do 
      ring.empty? ? [" "] : [] #Independent Party
    end
  end

  bloom :follower do
    f <= server_type do |s|
      s if s.first == NodeProtocol::FOLLOWER
    end
    follower.inputSndRequestVote <= (not_ringing * f * sndRequestVote).combos {|r, c, v| v}
    rspRequestVote <~ (f * follower.outputRspRequestVote).rights
    follower.inputSndAppendEntries <= (not_ringing * f * sndAppendEntries).combos {|r, c, v| v}
    follower.log <= log
    log <+ follower.log_add
    log <- follower.log_del
    follower.current_term <= current_term
    current_term <+- follower.next_current_term
    follower.member <= member
    follower.commit_index <= commit_index
    commit_index <+ follower.commit_index
    server_type <+- ring do
      [NodeProtocol::CANDIDATE]
    end
    current_term <+- ring do
      [current_term.first.first + 1]
    end
    reset <= follower.reset
  end

  bloom :candidate do
    c <= server_type do |s|
      s if s.first == NodeProtocol::CANDIDATE
    end
    candidate.candidate <= server_type do |s|
      s if s.first == NodeProtocol::CANDIDATE
    end
    candidate.inputSndRequestVote <= (not_ringing * c * sndRequestVote).combos {|r, c, v| v}
    candidate.inputRspRequestVote <= (not_ringing * c * rspRequestVote).combos {|r, c, v| v}
    rspRequestVote <~ (c * candidate.outputRspRequestVote).rights
    sndRequestVote <~ candidate.outputSndRequestVote
    candidate.inputSndAppendEntries <= (c * sndAppendEntries).rights
    candidate.log <= log
    log <+ candidate.log
    candidate.current_term <= current_term
    current_term <+- candidate.next_current_term
    candidate.member <= member
    candidate.commit_index <= commit_index
    commit_index <+ candidate.commit_index
    server_type <+- candidate.server_type
    candidate.ring <= ring
    reset <= candidate.reset
    candidate.ip_port_scratch <= [[ip_port]]
  end

  bloom :leader do
    l <= server_type do |s|
      s if s.first == NodeProtocol::LEADER
    end
    leader.leader <= server_type do |s|
      s if s.first == NodeProtocol::LEADER
    end
    reset <= server_type do |s|
      ["RESET"] if s.first == NodeProtocol::LEADER
    end
    leader.inputSndRequestVote <= (l * sndRequestVote).rights
    leader.inputSndAppendEntries <= (l * sndAppendEntries).rights
    sndAppendEntries <~ leader.outputSndAppendEntries
    leader.log <= log
    log <+ leader.log
    leader.current_term <= current_term
    leader.member <= member
    leader.commit_index <= commit_index
    commit_index <+ leader.commit_index
    server_type <+- leader.server_type
    leader.ip_port_scratch <= [[ip_port]]
  end

  bloom :stdio do
    # Print useful things each tick
    #stdio <~ [["Server: #{ip_port} Type: #{server_type.first.first} Term: #{current_term.first.first} budtime: #{budtime}"]]
#    stdio <~ current_term {|s| [["Current term: #{s} #{ip_port} #{budtime} #{current_term.first.first}"]]}
#    stdio <~ server_type {|s| [["Server Type: #{s} #{ip_port} #{budtime} #{current_term.first.first}"]]}
#    stdio <~ candidate.outputSndRequestVote {|v| [["Candidate votes for me: #{v}"]]}
#    stdio <~ candidate.inputSndRequestVote {|v| [["Candidate in requests: #{v}"]]}
#    stdio <~ reset {|v| [["Reset: #{v} #{budtime}"]]}
  end
end
