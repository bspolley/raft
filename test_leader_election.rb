require 'rubygems'
require 'bud'
require 'test/unit'
require 'leader_election'

class TestLeaderElection < Test::Unit::TestCase
  class LE
    include Bud
    include LeaderElection
  end
  
  def setup
    @p1 = LE.new
    @p1.run_bg
    @p2 = LE.new
    @p2.run_bg
    @p3 = LE.new
    @p3.run_bg
  end
  
  def test_rowo
    @p1.server_type <+ [[LE::FOLLOWER]]
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
  end
  
end
