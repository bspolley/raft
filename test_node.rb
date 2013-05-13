require 'rubygems'
require 'bud'
require 'test/unit'
require 'node'
require 'node_protocol'

class TestNode < Test::Unit::TestCase
  include NodeProtocol
  class N
    include Bud
    include Node
    
    bootstrap do
      add_member <= [
        [1, 'localhost:12345'],
        [2, 'localhost:12346'],
        [3, 'localhost:12347']
      ]
    end
    state do
      table :state, [:budtime, :term, :server_type]
    end

    bloom do
      state <= (current_term * server_type).pairs do |c, s|
        [budtime, c.term, s.state]
      end 
    end
  end
  
  
  def setup
    #debugger
    @p1 = N.new(:port => 12345)
    @p1.run_bg
    @p2 = N.new(:port => 12346)
    @p2.run_bg
    @p3 = N.new(:port => 12347)
    @p3.run_bg
    @nodes = [@p1, @p2, @p3]
  end
  
  def teardown
    @p1.stop
    @p2.stop
    @p3.stop
  end
  
  def test_someone_becomes_leader
    sleep 3
    leader = [0, 0, 0] 
    @p1.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[0] = 1
      end
    end
    @p2.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[1] = 1
      end
    end
    @p3.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[2] = 1
      end
    end
    assert(leader.inject(:+) == 1)
  end

   def test_kill_a_node
    sleep 3
    leader = [0, 0, 0] 
    @p1.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[0] = 1
      end
    end
    @p2.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[1] = 1
      end
    end
    @p3.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[2] = 1
      end
    end
    assert(leader.inject(:+) == 1)
    first_leader = leader.index(1)
    @nodes[first_leader].stop
    sleep 3
    @p1.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[0] = 1
      end
    end
    @p2.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[1] = 1
      end
    end
    @p3.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        leader[2] = 1
      end
    end
    leader[first_leader] = 0
    assert(leader.inject(:+) == 1)
 
  end


  
end
