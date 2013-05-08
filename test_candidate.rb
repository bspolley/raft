require 'rubygems'
require 'bud'
require 'test/unit'
require 'candidate'

class TestCandidate < Test::Unit::TestCase
  class C
    include Bud
    include Candidate
    
    state do
      table :see_server_type, [] => [:state]
      table :see_next_current_term, [] => [:state]
      #scratch :see_current_term, [] => [:term]
    end
    
    bootstrap do
      log <= [[0, 0, "dummy"]]
    end
    
    bloom do
      see_server_type <+- server_type
      see_next_current_term <+- next_current_term
      member <= [ [1, 'localhost:23451'], [2, 'localhost:23452'],
                  [3, 'localhost:23453'], [4, 'localhost:23454'],
                  [5, 'localhost:12345']]
      #current_term <= see_current_term
    end
  end
  
  def pseudo_tick(tick)
    @candidate.current_term <+ [[tick]]
    @candidate.tick
  end 

  def setup
    @candidate = C.new(:port =>12345)
    @candidate.run_bg
  end
  
  def teardown
    @candidate.stop
  end
  
  def test_higher_opponent
    @candidate.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @candidate.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 43, 2, 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(NodeProtocol::FOLLOWER, @candidate.see_server_type.first.state)
    end
  end
  
  def test_lower_opponent
    @candidate.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @candidate.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 1, 2, 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(0, @candidate.see_server_type.length)
    end
  end
  
  def test_equal_opponent
    @candidate.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @candidate.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 1, 2, 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(0, @candidate.see_server_type.length)
    end
  end
  
  def test_new_election
    @candidate.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @candidate.ring <+ [["RINGED", "OMG"]]
    sleep(0.5) #ensure 300 ms has passed
    4.times { pseudo_tick(42)}
    @candidate.sync_do do
      assert_equal(1, @candidate.see_next_current_term.length)
    end
  end
  
  def test_elected_leader
    @candidate.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @candidate.async_do {
      @candidate.inputRspRequestVote <+ [ ['localhost:12345', 'localhost:23451', 42, 'true'],
                                          ['localhost:12345', 'localhost:23454', 42, 'true']]
    }
    #@candidate.ring <+ [["RINGED", "OMG"]]
    #sleep(0.5) #ensure 300 ms has passed
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(NodeProtocol::LEADER, @candidate.see_server_type.first.state)
    end
  end
  
  def test_election_no_result_yet
    @candidate.current_term <+- [[42]]
    4.times { pseudo_tick(42) }
    @candidate.inputRspRequestVote <+ [ ['localhost:12345', 'localhost:23451', 42, 'true'] ]
    #@candidate.ring <+ [["RINGED", "OMG"]]
    sleep(0.5) #ensure 300 ms has passed
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(0, @candidate.see_server_type.length)
    end
  end
  
end
