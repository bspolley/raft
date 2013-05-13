require 'rubygems'
require 'bud'

module InnerNodeProtocol
  state do
    interface output,  :outputSndRequestVote, [:candidate, :voter, :term, :last_index, :last_term] 
    interface input,   :inputSndRequestVote, [:candidate, :voter, :term, :last_index, :last_term] 
    interface output,  :outputRspRequestVote, [:candidate, :voter, :term, :granted]
    interface input,   :inputRspRequestVote, [:candidate, :voter, :term, :granted]
    interface output,  :outputSndAppendEntries, [:leader, :follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    interface input,   :inputSndAppendEntries, [:leader, :follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    interface output,  :outputRspAppendEntries, [:leader, :follower, :index]
    interface input,   :inputRspAppendEntries, [:leader, :follower, :index]
    interface output,  :outputSndCommand, [:leader, :follower, :entry_id, :entry]
  end
end

