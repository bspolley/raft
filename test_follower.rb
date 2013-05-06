require 'rubygems'
require 'bud'
require 'test/unit'
require 'follower'

class TestFollower < Test::Unit::TestCase
  class F
    include Bud
    include Follower  
    
    state do
      table :validVote, sndRequestVote.schema
    end
    
    bloom do
      validVote <= valid_vote
    end
  end
  
  def setup
    @follower = F.new(:port =>12345)
    @follower.run_bg
    #@p2 = N.new
    #@p2.run_bg
    #@p3 = N.new
    #@p3.run_bg
  end
  
  def teardown
    @follower.stop
  end
  
  def test_one_request
    @follower.sync_do { @follower.sndRequestVote <~ [['localhost:12346', 'localhost:12345', 1, 2, 3]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.validVote.length)
      @follower.validVote.each do |f|
        assert_equal('localhost:12346', f.candidate)
        assert_equal(1, f.term)
      end
    end
  end
  
  def test_grant_none_if_less_term
    @follower.sync_do { @follower.current_term <+- [[3]] }
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.sndRequestVote <~ [['localhost:12346', 'localhost:12345', 2, 2, 1]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(0, @follower.validVote.length)
    end
  end
  
  def test_grant_none_if_equal_term
    @follower.sync_do { @follower.current_term <+- [[3]] }
    4.times { @follower.sync_do }
    @follower.sync_do { @follower.sndRequestVote <~ [['localhost:12346', 'localhost:12345', 3, 2, 1]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(0, @follower.validVote.length)
    end
  end
  
  def test_multiple_req_mult_candidate
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.sndRequestVote <~ [['localhost:12346', 'localhost:12345', 1, 2, 1], ['localhost:12347', 'localhost:12345', 3, 2, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.validVote.length)
      @follower.validVote.each do |f|
        assert_equal('localhost:12347', f.candidate)
        assert_equal(3, f.term)
      end
    end
  end
  
  def test_multiple_req_same_candidate
    @follower.sync_do { @follower.current_term <+- [[2]]}
    @follower.sync_do { @follower.sndRequestVote <~ [['localhost:12346', 'localhost:12345', 1, 2, 1], ['localhost:12346', 'localhost:12345', 3, 2, 2]] }
    4.times { @follower.sync_do }
    @follower.sync_do do
      assert_equal(1, @follower.validVote.length)
      @follower.validVote.each do |f|
        assert_equal('localhost:12346', f.candidate)
        assert_equal(3, f.term)
      end
    end
  end
  
end

=begin

  state do 
    table :timed_xget_resps, [:timestamp, :xid, :key, :reqid, :data]
    table :timed_xput_resps, [:timestamp, :xid, :key, :reqid]
    table :xget_resps, [:xid, :key, :reqid, :data]
    table :xput_resps, [:xid, :key, :reqid]
  end
  
  bloom do
    timed_xget_resps <= xget_response {|t| [budtime, t.xid, t.key, t.reqid, t.data]}
    timed_xput_resps <= xput_response {|t| [budtime, t.xid, t.key, t.reqid]}
    xput_resps <= xput_response
    xget_resps <= xget_response
  end

end


class TestXactKVS < Test::Unit::TestCase

  def test_write_write_read
    kvs = XactKVS.new
    kvs.run_bg
    kvs.sync_do { kvs.xput <+ [["t0", "key1", "req0", "data0"]]}
    kvs.sync_do { kvs.xput <+ [["t0", "key1", "req1", "data1"]]}
    4.times {kvs.sync_do}
    kvs.sync_do do
      assert_equal(2, kvs.timed_xput_resps.length)
    end
    kvs.sync_do { kvs.xget <+ [["t0", "key1", "req3"]]}
    4.times {kvs.sync_do}
    kvs.sync_do do
      assert_equal(1, kvs.timed_xget_resps.length)
      kvs.timed_xget_resps.each do |k|
        assert_equal("data1", k.data)
      end
    end
  end
=end