require 'rubygems'
require 'bud'
require 'test/unit'
require 'random_timer'

class TestTimer < Test::Unit::TestCase
  class Timer
    include Bud
    include RandomTimer
  end
  
  
  def setup
    @p1 = Timer.new
    @p1.run_bg
  end
  
  def test_rowo
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
    sleep(5)
  end
  
end