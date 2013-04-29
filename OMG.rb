

class Caterpillar
  def initialize(percent_done)
    @percent_done = percent_done
  end
  
  def update(p)
    @percent_done << p
  end
  def remove(p)
    @percent_done.delete(p)
  end
  
  def done
    @percent_done
  end
  
  
  
end

class Butterfly
  def initialize(percent_done)
    @percent_done = percent_done
  end
  
  
  
  def done
    @percent_done
  end
  
end

class Tran
  
  def initialize

  end
  def faster
    percent_done = []
    c = Caterpillar.new(percent_done)
    b = Butterfly.new(percent_done)
    p c.done
    c.update(5)
    p b.done
    c.remove(5)
    p b.done
  end
  
end


t = Tran.new
t.faster