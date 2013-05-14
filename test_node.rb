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
  
  def set_leader(hash, index, term)
    if not hash[term]
       hash[term] = [0,0,0]
    end
    hash[term][index] = 1
  end
  
  def find_leader
    leader_hash = {}
    @p1.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        set_leader(leader_hash, 0, s.term)
      end
    end
    @p2.state.each do |s| 
      if s.server_type == NodeProtocol::LEADER 
        set_leader(leader_hash, 1, s.term)
      end
    end
    @p3.state.each do |s|
      if s.server_type == NodeProtocol::LEADER 
        set_leader(leader_hash, 2, s.term)
      end
    end
    return leader_hash
  end
  
  def hmi(hash) #gets the value at the max index of the hash
    return hash[hash.keys.max]
  end
  
  def test_someone_becomes_leader
    sleep 5
    leader_hash = find_leader
    leader_hash.keys.each do |k|
      assert(1 <= leader_hash[k].inject(:+))
    end
  end

  def test_kill_a_node
    sleep 4
    leader_hash = find_leader
    current_leader = leader_hash[leader_hash.keys.max].index(1)
    @nodes[current_leader].stop # kill the leader
    sleep 3
    leader_hash = find_leader
    leader_hash.keys.each do |k|
      assert(1 <= leader_hash[k].inject(:+))
    end
  end

  def test_add_one_entry
    sleep 4
    leader_hash = find_leader
    resp = @nodes[hmi(leader_hash).index(1)].sync_callback(:command, [[1, "hello world"]], :command_ack)
    sleep 2
    @nodes.each do |n|
      counter = 0
      n.log.each do |l|  
        counter += 1
      end
      assert_equal(2, counter) # two things in log, bootstrap & our new entry
    end 
  end
  
  def test_add_one_entry_to_follower
    sleep 4
    leader_hash = find_leader
    resp = @nodes[hmi(leader_hash).index(0)].sync_callback(:command, [[1, "hello world"]], :command_ack)
    sleep 2
    @nodes.each do |n|
      counter = 0
      n.log.each do |l|
        counter += 1
      end
      assert_equal(2, counter) # two things in log, bootstrap & our new entry
    end 
  end
  
  def test_acks_from_leader
    sleep 4
    leader_hash = find_leader
    resp = @nodes[hmi(leader_hash).index(1)].sync_callback(:command, [[1, "hello world"]], :command_ack)
    assert_equal([1], resp.first)
  end
  
  def test_acks_from_follower
    sleep 4
    leader_hash = find_leader
    resp = @nodes[hmi(leader_hash).index(0)].sync_callback(:command, [[1, "hello world"]], :command_ack)
    assert_equal([1], resp.first)
  end
  
end
