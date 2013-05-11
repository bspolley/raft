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
  
  def teardown
    @p1.stop
  end
  
  def test_alarm
    @p1.reset <+ [["Reset"]]
    sleep(0.5)
    @p1.reset <+ [["Reset"]]
    sleep(0.5)
    @p1.reset <+ [["Reset"]]
    sleep(0.5)
    @p1.reset <+ [["Reset"]]
    sleep(0.5)
    @p1.reset <+ [["Reset"]]
    sleep(0.5)
    @p1.reset <+ [["Reset"]]
    sleep(0.5)
    @p1.reset <+ [["Reset"]]
    sleep(1.5)
  end
  
end