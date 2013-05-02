require 'rubygems'
require 'bud'
require 'node_protocol'

module Leader
  include NodeProtocol
  
  state do
    scratch :member, [:ident] => [:host]
    table :log, [:index] => [:term, :command]
    table :current_term, [] => [:term]
    table :commit_index, [] => [:index]
    scratch :server_type, [] => [:state]
    scratch :better_candidate, [] => sndRequestVote.schema
  end
  
  bootstrap do
    current_term <= [[0]]
  end
  
  bloom :leader_election do
    better_candidate <= sndRequestVote do |s|
      s if s.term > firsty(current_term)
    end
    server_type <= better_candidate.argagg(:choose, [], :candidate) do |p|
      [NodeProtocol::FOLLOWER]
    end
  end
  
end
