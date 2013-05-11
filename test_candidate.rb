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
      table :see_output_req_vote, [:num, :candidate, :voter, :term, :last_index, :last_term]
      table :see_reset, reset.schema
    end
    
    bootstrap do
      current_term <= [[42]]
      log <= [[0, 0, "dummy"]]
    end
    
    bloom do
      see_server_type <+- server_type
      see_reset <= reset
      log <+ log
      current_term <+ current_term
      see_next_current_term <+- next_current_term
      member <= [ [1, 'localhost:23451'], [2, 'localhost:23452'],
                  [3, 'localhost:23453'], [4, 'localhost:23454'],
                  [5, 'localhost:12345']]
      see_output_req_vote <= outputSndRequestVote do |o|
        [budtime, o.candidate, o.voter, o.term, o.last_index, o.last_term]
      end
      ip_port_scratch <= [["somecandidatestring"]]
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
    4.times { pseudo_tick(42) }
    @candidate.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 43, 2, 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(NodeProtocol::FOLLOWER, @candidate.see_server_type.first.state)
    end
  end
  
  def test_lower_opponent
    4.times { pseudo_tick(42) }
    @candidate.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 1, 2, 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(0, @candidate.see_server_type.length)
    end
  end
  
  def test_equal_opponent
    4.times { pseudo_tick(42) }
    @candidate.inputSndRequestVote <+ [['localhost:12347', 'localhost:12345', 1, 2, 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(0, @candidate.see_server_type.length)
    end
  end
  
  def test_new_election
    4.times { pseudo_tick(42) }
    @candidate.ring <+ [["RINGED", "OMG"]]
    sleep(0.5) #ensure 300 ms has passed
    4.times { pseudo_tick(42)}
    @candidate.sync_do do
      assert_equal(1, @candidate.see_next_current_term.length)
    end
  end
  
  def test_elected_leader
    4.times { pseudo_tick(42) }
    @candidate.async_do {
      @candidate.inputRspRequestVote <+ [ ['localhost:12345', 'localhost:23451', 42, 'true'],
                                          ['localhost:12345', 'localhost:23454', 42, 'true']]
    }
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(NodeProtocol::LEADER, @candidate.see_server_type.first.state)
    end
  end
  
  def test_election_no_result_yet
    4.times { pseudo_tick(42) }
    @candidate.inputRspRequestVote <+ [ ['localhost:12345', 'localhost:23451', 42, 'true'] ]
    sleep(0.5) #ensure 300 ms has passed
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_operator 5, :<, @candidate.see_output_req_vote.length
      assert_equal(0, @candidate.see_server_type.length)
    end
  end
  
  def test_append_entry_greater_term_leader
    4.times { pseudo_tick(42) }
    @candidate.inputSndAppendEntries <+ [['localhost:12345', 'localhoast:23451', 43, 3, 42, "entry", 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(NodeProtocol::FOLLOWER, @candidate.see_server_type.first.state)
    end
  end
  
  def test_append_entry_less_term_leader
    4.times { pseudo_tick(42) }
    @candidate.inputSndAppendEntries <+ [['localhost:12345', 'localhoast:23451', 41, 3, 42, "entry", 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(0, @candidate.see_server_type.length)
      assert_equal(0, @candidate.see_reset.length)
    end
  end
  
  def test_append_entry_equal_term_leader
    4.times { pseudo_tick(42) }
    @candidate.inputSndAppendEntries <+ [['localhost:12345', 'localhoast:23451', 42, 3, 41, "entry", 3]]
    4.times { pseudo_tick(42) }
    @candidate.sync_do do
      assert_equal(NodeProtocol::FOLLOWER, @candidate.see_server_type.length)
      assert_equal(1, @candidate.see_reset.length)
    end
  end
  
end
