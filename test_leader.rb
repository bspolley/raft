require 'rubygems'
require 'bud'
require 'test/unit'
require 'leader'

class TestLeader < Test::Unit::TestCase
  class C
    include Bud
    include Leader
    
    state do
      table :see_server_type, [] => [:state]
      table :see_output_append_entries, [:num, :leader, :follower, :term, :prev_index, :prev_term, :entry, :commit_index]
    end
    
    bootstrap do
      log <= [[0, 0, "dummy"]]
      commit_index <= [[0]]
    end
    
    bloom do
      see_output_append_entries <= outputSndAppendEntries do |o|
        [budtime, o.leader, o.follower, o.term, o.prev_index, o.prev_term, o.entry, o.commit_index]
      end
      see_server_type <+- server_type
      member <= [ [1, 'localhost:23451'], [2, 'localhost:23452'],
                  [3, 'localhost:23453'], [4, 'localhost:23454'],
                  [5, 'localhost:12345']]
    end
  end
  
  def pseudo_tick(tick)
    @leader.current_term <+ [[tick]]
    @leader.tick
  end 

  def setup
    @leader = C.new(:port =>12345)
    @leader.run_bg
  end
  
  def teardown
    @leader.stop
  end
  
  def test_higher_opponent
    @leader.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @leader.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 43, 2, 3]]
    4.times { pseudo_tick(42) }
    @leader.sync_do do
      assert_equal(NodeProtocol::FOLLOWER, @leader.see_server_type.first.state)
    end
  end
  
  def test_lower_opponent
    @leader.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @leader.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 41, 2, 3]]
    4.times { pseudo_tick(42) }
    @leader.sync_do do
      assert_equal(0, @leader.see_server_type.length)
    end
  end
  
  def test_equal_opponent
    @leader.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @leader.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 42, 2, 3]]
    4.times { pseudo_tick(42) }
    @leader.sync_do do
      assert_equal(0, @leader.see_server_type.length)
    end
  end
  
  def test_heartbeat
    @leader.current_term <+- [[42]]
    sleep(0.5)
    4.times { pseudo_tick(42) }
    @leader.sync_do do
      assert_operator 5, :<, @leader.see_output_append_entries.length
    end
  end
  
end