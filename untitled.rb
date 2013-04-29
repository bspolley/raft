

module Caterpillar
  def initialize(percent_done)
    attr_accessor percent_done
  end
  
  def update(p)
    percent_done.replace(p)
  end
  
  def done
    percent_done
  end
  
  
  
end

module Butterfly
  def initialize(percent_done)
    attr_accessor percent_done
  end
  
  def update(p)
    percent_done.replace(p)
  end
  
  def done
    percent_done
  end
  
end

Class Transition
  include Caterpillar
  include Butterfly
  
  def initialize

  end
  def faster
    percent_done = 0
    c = Caterpillar.new(percent_done)
    b = Butterfly.new(percent_done)
    p c.done
    c.update(50)
    p b.done
  end
  
end

t = Transition.new
t.faster