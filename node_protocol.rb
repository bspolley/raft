require 'rubygems'
require 'bud'

module NodeProtocol
  state do
    channel   :sndRequestVote, [:candidate, :@me, :term, :last_index, :last_term] 
    channel   :rspRequestVote, [:@candidate, :me, :term, :granted]
    channel   :sndAppendEntries, [:leader, :@me, :term, :prev_index, :prev_term, :entry, :commit_index]
    channel   :rspAppendEntries, [:@leader, :me, :term, :success]
  end
end