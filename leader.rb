require 'rubygems'
require 'bud'
require 'node_protocol'
#channel   :SndRequestVote, [:candidate, :@me, :term, :last_index, :last_term] 
#channel   :RspRequestVote, [:@candidate, :me, :term, :granted]
#channel   :SndAppendEntries, [:leader, :@me, :term, :prev_index, :prev_term, :entry, :commit_index]
#channel   :RspAppendEntries, [:@leader, :me, :term, :success]
module Leader
  include NodeProtocol
  
  state do
    table :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    
  end
end
