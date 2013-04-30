require 'rubygems'
require 'bud'
require 'test/unit'
require 'candidate'

class TestCandidate < Test::Unit::TestCase
  class C
    include Bud
    include Candidate
  end
  
  def setup
    @candidate = C.new(:port =>12345)
    @candidate.run_bg
    #@p2 = N.new
    #@p2.run_bg
    #@p3 = N.new
    #@p3.run_bg
  end
  
  def test_candidate
    @candidate.sndRequestVote <~ [['localhost:12347', 'localhost:12345', 1, 2, 3]]
    @candidate.tick
    @candidate.tick
    @candidate.tick
    sleep 2
  end
  
end
