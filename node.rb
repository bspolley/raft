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

  state do
    table :server_type, [] => [:state]
    scratch :f, server_type.schema #Follower 
    scratch :c, server_type.schema #Candidate 
    scratch :l, server_type.schema #Leader 
    scratch :not_ringing, [] => [:blah]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    table :command_buffer, command.schema
    table :outside_commands, command.schema
    scratch :commited_commands, command.schema
    periodic :resend_commands, 5
  end
  
  bootstrap do
    log <= [[0,0,'dummy']]
    current_term <= [[0]]
    server_type <= [[NodeProtocol::FOLLOWER]]
    commit_index <= [[0]]
  end
  
  bloom :outside_commands do
    outside_commands <= command
    commited_commands <= (log * outside_commands * commit_index).combos do |l, o, c|
      o if l.command == o.entry_id.to_s + " " + o.entry and l.index <= c.index
    end
    outside_commands <- commited_commands
#    command <+ (resend_commands * outside_commands).rights
    command_ack <= commited_commands {|c| [c.entry_id]}
  end
  
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
    rspAppendEntries <~ (f * follower.outputRspAppendEntries).rights
    follower.log <= log
    log <+ follower.log_add
    log <- follower.log_del
    follower.current_term <= current_term
    current_term <+- follower.next_current_term
    follower.member <= member
    follower.commit_index <= commit_index
    commit_index <+- follower.new_commit_index
    server_type <+- ring do
      [NodeProtocol::CANDIDATE]
    end
    current_term <+- ring do
      [current_term.first.first + 1]
    end
    reset <= follower.reset
    command_buffer <= (f * command).rights
    follower.command_buffer <= command_buffer
    sndCommand <~ follower.outputSndCommand
    command_buffer <- follower.outputSndCommand do |o|
      [o.entry_id, o.entry]
    end
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
    server_type <+- candidate.server_type
    candidate.ring <= ring
    reset <= candidate.reset
    candidate.ip_port_scratch <= [[ip_port]]
    command_buffer <= (c * command).rights
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
    leader.inputRspAppendEntries <= (l * rspAppendEntries).rights
    sndAppendEntries <~ leader.outputSndAppendEntries
    leader.log <= log
    log <+ leader.log_add
    leader.current_term <= current_term
    leader.member <= member
    leader.commit_index <= commit_index
    commit_index <+- leader.new_commit_index
    server_type <+- leader.server_type
    leader.ip_port_scratch <= [[ip_port]]
    leader.new_entry <= (l * command_buffer).rights
    command_buffer <- (l * command_buffer).rights
    leader.new_entry <= (l * command).rights
    leader.new_entry <= (l * sndCommand).rights do |c|
      [c.entry_id, c.entry]
    end 
  end

  bloom :stdio do
    # Print useful things each tick
    #stdio <~ [["Server: #{ip_port} Type: #{server_type.first.first} Term: #{current_term.first.first} budtime: #{budtime}"]]
#    stdio <~ current_term {|s| [["Current term: #{s} #{ip_port} #{budtime} #{current_term.first.first}"]]}
#    stdio <~ server_type {|s| [["Server Type: #{s} #{ip_port} #{budtime} #{current_term.first.first}"]]}
#    stdio <~ candidate.outputSndRequestVote {|v| [["Candidate votes for me: #{v}"]]}
#    stdio <~ candidate.inputSndRequestVote {|v| [["Candidate in requests: #{v}"]]}
#    stdio <~ reset {|v| [["Reset: #{v} #{budtime}"]]}
#    stdio <~ rspAppendEntries { |s| [["rspAppendEntries: #{s} #{ip_port}"]]}
#    stdio <~ sndAppendEntries { |s| [["sndAppendEntries: #{s} #{ip_port}"]]}
#    stdio <~ follower.outputRspAppendEntries {|v| [["RspAppendEntries: #{v}"]]}
#    stdio <~ leader.inputRspAppendEntries {|v| [["input RspAppendEntries: #{v} #{ip_port}"]]}
#    stdio <~ leader.chosen_one { |s| [["Chosen One: #{s} #{ip_port} #{budtime}"]]}
#    stdio <~ leader.commited {|c| [["Commited: #{c} #{budtime}"]]}
#    stdio <~ leader.follower_logs {|l| [["Follower Logs: #{l}"]]}
#    stdio <~ command_ack {|c| [["Command ack: #{c}"]]}
#    stdio <~ commited_commands {|c| [["Commited commands: #{c} #{budtime} #{ip_port}"]]}
#    stdio <~ commit_index {|i| [["Commit index: #{i} #{ip_port} #{budtime}"]]}
#    stdio <~ leader.repeat_entry {|r| [["Repeat Entry: #{r} #{ip_port} #{budtime}"]]}
#    stdio <~ leader.chosen_one {|o| [["Chosen_one: #{o} #{ip_port} #{budtime}"]]}
#    stdio <~ leader.good_chosen_one {|o| [["Good chosen_one: #{o} #{ip_port} #{budtime}"]]}
#    stdio <~ sndCommand {|s| [["Send Command: #{s} #{ip_port} #{budtime}"]]}
    stdio <~ [["Server: #{ip_port} Type: #{server_type.first.first} log: #{log.inspected} outside_com: #{outside_commands.inspected} commit_index: #{commit_index.first.first} budtime: #{budtime}"]]
  end
end
