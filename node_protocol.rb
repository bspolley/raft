require 'rubygems'
require 'bud'

module NodeProtocol
  FOLLOWER = 1
  CANDIDATE = 2
  LEADER = 3
  
  state do
    channel   :sndRequestVote, [:candidate, :@me, :term, :last_index, :last_term] 
    channel   :rspRequestVote, [:@candidate, :me, :term, :granted]
    channel   :sndAppendEntries, [:leader, :@me, :term, :prev_index, :prev_term, :entry, :commit_index]
    channel   :rspAppendEntries, [:@leader, :me, :term, :success]
  end
end