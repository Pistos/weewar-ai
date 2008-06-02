module WeewarAI
  
  # A single unit in the game.
  class Unit
    attr_reader :faction, :hex, :type, :hp
    
    SYMBOLS_FOR_UNITS = {
      'Trooper' => :linf,
      'Heavy Trooper' => :hinf,
      'Raider' => :raider,
      'Assault Artillery' => :aart,
      'Tank' => :tank,
      'Heavy Tank' => :htank,
      'Berserker' => :bers,
      'Light Artillery' => :lart,
      'Heavy Artillery' => :hart,
      'DFA' => :dfa,
      'Hovercraft' => :hover,
      #'capturing' => :capturing,
    }
    
    UNIT_CLASSES = {
      :linf => :soft,
      :hinf => :soft,
      :raider => :hard,
      :aart => :hard,
      :tank => :hard,
      :htank => :hard,
      :bers => :hard,
      :lart => :hard,
      :hart => :hard,
      :dfa => :hard,
      :capturing => :soft,
      :hover => :amphibic,
    }
    
    UNIT_COSTS = {
      :linf => 75,
      :hinf => 150,
      :raider => 200,
      :tank => 300,
      :hover => 300,
      :htank => 600,
      :lart => 400,
      :aart => 450,
      :hart => 600,
      :dfa => 1200,
      :bers => 900,
      :sboat => 200,
      :dest => 1100,
      :bship => 2000,
      :sub => 1200,
      :jet => 800,
      :heli => 600,
      :bomber => 1200,
      :aa => 400,
    }
    
    # Units are created by the Map class.  No need to instantiate any on your own.
    def initialize( hex, faction, type, capturing, hp )
      sym = SYMBOLS_FOR_UNITS[ type ]
      if sym.nil?
        raise "Unknown type: '#{type}'"
      end
      
      @hex, @faction, @type, @capturing, @hp = hex, faction, sym, capturing, hp.to_i
    end
    
    def to_s
      "#{@faction} #{@type} @ (#{@hex.x},#{@hex.y})"
    end
    
    # The unit's current x coordinate.
    def x
      @hex.x
    end
    
    # The unit's current y coordinate
    def y
      @hex.y
    end
    
    # Whether or not the unit can be ordered to do anything.
    def moveable?
      @state != 'greyed' and @type != :capturing
    end
    
    def capturing?
      @capturing
    end
    
    # The unit class of this unit. i.e. :soft, :hard, etc.
    def unit_class
      UNIT_CLASSES[ @type ]
    end
    
    def ==( other )
      @hex == other.hex and
      @faction == other.faction and
      @type == other.type
    end
  end
end