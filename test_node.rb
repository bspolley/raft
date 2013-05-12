require 'rubygems'
require 'bud'
require 'test/unit'
require 'node'
require 'ruby-debug'

class TestNode < Test::Unit::TestCase
  class N
    include Bud
    include Node
    
    bootstrap do
      add_member <= [
        [1, 'localhost:12345'],
        [2, 'localhost:12346'],
        [3, 'localhost:12347']
      ]
    end
  end
  
  
  def setup
    #debugger
    @p1 = N.new(:port => 12345)
    @p1.run_bg
    @p2 = N.new(:port => 12346)
    @p2.run_bg
    @p3 = N.new(:port => 12347)
    @p3.run_bg
  end
  
  def teardown
    @p1.stop
    @p2.stop
    @p3.stop
  end
  
  def test_basic
    sleep 3
    @p1.stop
    sleep 3
  end
  
end
