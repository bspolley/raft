require 'rubygems'
require 'bud'
require 'test/unit'
require 'follower'

class TestFollower < Test::Unit::TestCase
  class F
    include Bud
    include Follower  
    
    state do
      table :see_output_rsp_req, outputRspRequestVote.schema
      table :see_log_add, log.schema
      table :see_current_term, current_term.schema
      table :see_output_rsp_entries, outputRspAppendEntries.schema
      table :see_log_del, log.schema
      table :see_reset, reset.schema
    end
    
    bootstrap do
      log <= [[0, 0, "dummy"]]
    end
    
    bloom do
      log <+ log
      see_reset <= reset
      see_log_add <= log_add
      see_log_del <= log_del
      see_output_rsp_entries <= outputRspAppendEntries
      see_current_term <+- current_term
      see_output_rsp_req <= outputRspRequestVote
    end
  end
  
  def setup
    @follower = F.new(:port =>12345)
    @follower.run_bg
  end
  
  def teardown
    @follower.stop
  end
  
  def test_one_request
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 1, 2, 3]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.see_output_rsp_req.length)
      @follower.see_output_rsp_req.each do |f|
        assert_equal('localhost:12346', f.candidate)
        assert_equal(1, f.term)
      end
    end
  end
  
  def test_grant_none_if_less_term
    @follower.sync_do { @follower.current_term <+- [[3]] }
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 2, 2, 1]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(0, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_grant_none_if_equal_term
    @follower.sync_do { @follower.current_term <+- [[3]] }
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 3, 2, 1]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(0, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_grant_none_if_less_last_term
    @follower.sync_do { @follower.current_term <+- [[3]] }
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 4, 2, 1]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(0, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_grant_if_greater_last_term
    @follower.sync_do { @follower.current_term <+- [[3]] }
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 4, 2, 3]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_grant_if_equal_last_term_equal_index
    @follower.sync_do { @follower.current_term <+- [[3]] }
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 4, 2, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_grant_none_if_equal_last_term_less_index
    @follower.sync_do { @follower.current_term <+- [[3]] }
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 4, 1, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(0, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_grant_if_equal_last_term_greater_index
    @follower.sync_do { @follower.current_term <+- [[3]] }
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndRequestVote <+ [['localhost:12346', 'localhost:12345', 4, 4, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.see_output_rsp_req.length)
    end
  end
  
  def test_multiple_req_mult_candidate
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.inputSndRequestVote <+ [ ['localhost:12346', 'localhost:12345', 1, 2, 1], 
                                                      ['localhost:12347', 'localhost:12345', 3, 2, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.see_output_rsp_req.length)
      @follower.see_output_rsp_req.each do |f|
        assert_equal('localhost:12347', f.candidate)
        assert_equal(3, f.term)
      end
    end
  end
  
  def test_multiple_req_same_candidate
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.inputSndRequestVote <+ [ ['localhost:12346', 'localhost:12345', 1, 2, 1], 
                                                      ['localhost:12346', 'localhost:12345', 3, 2, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.see_output_rsp_req.length)
      @follower.see_output_rsp_req.each do |f|
        assert_equal('localhost:12346', f.candidate)
        assert_equal(3, f.term)
      end
    end
  end
  
  def test_append_equal_indices
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndAppendEntries <+ [['localhost:12346', 'localhost:12345', 3, 3, 2, 'entry', 2]]}
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(3, @follower.see_current_term.first.first)
      assert_equal(1, @follower.see_log_add.length)
      assert_equal(1, @follower.see_reset.length)
    end
  end
  
  def test_append_greater_indices
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndAppendEntries <+ [['localhost:12346', 'localhost:12345', 3, 4, 2, 'entry', 2]]}
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(3, @follower.see_current_term.first.first)
      assert_equal(0, @follower.see_log_add.length)
    end
  end
  
  def test_append_less_indices
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndAppendEntries <+ [['localhost:12346', 'localhost:12345', 3, 1, 2, 'entry', 2]]}
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(3, @follower.see_current_term.first.first)
      assert_equal(0, @follower.see_log_add.length)
      assert_equal(2, @follower.see_output_rsp_entries.first.index)
      assert_equal(2, @follower.see_log_del.length)
    end
  end
  
  def test_append_equal_indices_wrong_prev_term
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndAppendEntries <+ [['localhost:12346', 'localhost:12345', 3, 3, 1, 'entry', 2]]}
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(3, @follower.see_current_term.first.first)
      assert_equal(0, @follower.see_log_add.length)
      assert_equal(3, @follower.see_output_rsp_entries.first.index)
      assert_equal(1, @follower.see_log_del.length)
    end
  end
  
  def test_append_equal_indices_multiple_append_requests
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndAppendEntries <+ [['localhost:12346', 'localhost:12345', 3, 3, 2, 'entry1', 2],
                                                            ['localhost:12344', 'localhost:12345', 4, 3, 2, 'entry2', 2]]}
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(4, @follower.see_current_term.first.first)
      assert_equal(1, @follower.see_log_add.length)
      assert_equal('entry2', @follower.see_log_add.first.command)
      assert_equal(0, @follower.see_output_rsp_entries.length)
      assert_equal(0, @follower.see_log_del.length)
    end
  end
  
  def test_append_less_term
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.log <+ [[1, 1, 'a'], [2, 2, 'a'], [3, 2, 'b']]}
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.inputSndAppendEntries <+ [['localhost:12346', 'localhost:12345', 1, 3, 2, 'entry1', 2]]}
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(2, @follower.see_current_term.first.term)
      assert_equal(0, @follower.see_reset.length)
    end
  end
  
end
