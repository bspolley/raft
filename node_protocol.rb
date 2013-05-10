require 'rubygems'
require 'bud'

module NodeProtocol
  FOLLOWER = 1
  CANDIDATE = 2
  LEADER = 3
  
  state do
    channel   :sndRequestVote, [:candidate, :@voter, :term, :last_index, :last_term] 
    channel   :rspRequestVote, [:@candidate, :voter, :term, :granted]
    channel   :sndAppendEntries, [:leader, :@follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    channel   :rspAppendEntries, [:@leader, :follower, :term, :success]
    #channel   :command, [:@leader, :command]
    #channel   :command_ack, 
    #interface input, :kdjf [:command]
  end
end