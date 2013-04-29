require 'rubygems'
require 'bud'

module LeaderElection
FOLLOWER = 1
CANDIDATE = 2
LEADER = 3

  state do
    table :server_type, [] => [:state]
    scratch :course, server_type.schema
  end
  
  bootstrap do
  
  end
  
  bloom :follower do
    some_var <= (server_type * [[FOLLOWER]]).pairs(:state => :state)
    
    
  end
  
  bloom :candidate do
    course <= server_type do |t|
      t if t.first == CANDIDATE
    end

  end
  
  bloom :leader do
    course <= server_type do |t|
      t if t.first == LEADER
    end
    
  end
  
end