require 'rubygems'
require 'bud'
require 'test/unit'
require 'follower'

class TestFollower < Test::Unit::TestCase
  class F
    include Bud
    include Follower  
  end
  
  def setup
    @follower = F.new(:port =>12345)
    @follower.run_bg
    #@p2 = N.new
    #@p2.run_bg
    #@p3 = N.new
    #@p3.run_bg
  end
  
  def test_follower
    @follower.sndRequestVote <~ [['localhost:12346', 'localhost:12345', 1, 2, 2], ['localhost:12347', 'localhost:12345', 1, 2, 3]]
    @follower.tick
    @follower.tick
    @follower.tick
    sleep 2
  end
  
end
