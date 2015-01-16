# -*- coding: ISO-8859-1 -*-
#file: viewer_base.rb


class TheViewer
  attr_reader :name
  
  def initialize(name)
    @name = name
  end
  
  def game_action(*args)
  end
  
  def game_state(info)
  end
end
