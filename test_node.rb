require 'rubygems'
require 'bud'
require 'test/unit'
require 'node'

class TestNode < Test::Unit::TestCase
  class N
    include Bud
    include Node
  end
  
  def setup
    @p1 = N.new
    @p1.run_bg
    @p2 = N.new
    @p2.run_bg
    @p3 = N.new
    @p3.run_bg
  end
  
  def test_rowo
    @p1.server_type <+ [[N::FOLLOWER]]
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
    @p1.tick
  end
  
end
