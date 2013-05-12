require 'rubygems'
require 'bud'
require 'test/unit'
require 'random_timer'

class TestTimer < Test::Unit::TestCase
  class Timer
    include Bud
    include RandomTimer
    
    state do
      table :see_alarm, alarm.schema
    end
    
    bloom do
      see_alarm <= alarm
    end
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
    @p1.tick
    @p1.reset <+ [["Reset"]]
    @p1.tick
    @p1.reset <+ [["Reset"]]
    sleep(0.1)
    @p1.reset <+ [["Reset"]]
    sleep(0.1)
    @p1.reset <+ [["Reset"]]
    sleep(0.1)
    @p1.reset <+ [["Reset"]]
    sleep(0.1)
    @p1.reset <+ [["Reset"]]
    sleep(0.1)
    @p1.reset <+ [["Reset"]]
    sleep(0.1)
    @p1.reset <+ [["Reset"]]
    sleep(1.5)
    assert_equal(1, @p1.see_alarm.length)
  end
  
end