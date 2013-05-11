require 'rubygems'
require 'bud'
require 'time'
require 'progress_timer'

module RandomTimerProtocol
  state do
    interface :input, :reset, [] => [:timer]
    interface :output, :ring, [:name, :time_out]
  end
end

module RandomTimer
  include RandomTimerProtocol
  include ProgressTimer
  
  state do 
    scratch :one_alarm, [:name, :time_out]
  end
  
  bootstrap do
    set_alarm <= [random_input]
  end
  
  bloom do
    del_alarm <= reset do
      ["random"]
    end
    one_alarm <= [random_input]
    set_alarm <+ (one_alarm * reset).lefts
    set_alarm <+ (one_alarm * alarm).lefts
    ring <= alarm
  end
  
  def random_input
    ["random", (500.0+rand(1000.0))/1000.0]
  end
  
end