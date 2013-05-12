require 'rubygems'
require 'bud'
require 'test/unit'
require 'progress_timer'

class TestTimer < Test::Unit::TestCase
  class Timer
    include Bud
    include ProgressTimer
    
    state do 
      table :see_alarm, [:name, :time_out]
    end
    
    bloom do
      see_alarm <+ alarm
    end
    
  end
  
  
  def setup
    @p1 = Timer.new
    @p1.run_bg
  end
  
  def test_alarm
    @p1.set_alarm <+ [["random", 0.5]]  
    sleep(0.2)
    @p1.del_alarm <+ [["random"]]
    sleep(0.3)
    @p1.set_alarm <+ [["random", 0.5]]  
    sleep(0.7)
    assert_equal(1, @p1.see_alarm.length)
  end
  
end