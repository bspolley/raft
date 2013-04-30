require 'rubygems'
require 'bud'
require 'test/unit'
require 'progress_timer'

class TestTimer < Test::Unit::TestCase
  class Timer
    include Bud
    include ProgressTimer
  end
  
  
  def setup
    @p1 = Timer.new
    @p1.run_bg
  end
  
  def test_rowo
    @p1.set_alarm <+ [["test", 0.15]]
    @p1.tick
    sleep(5)
  end
  
end