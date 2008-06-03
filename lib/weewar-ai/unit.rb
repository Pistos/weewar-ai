module WeewarAI
  
  # A single unit in the game.
  class Unit
    attr_reader :faction, :hex, :type, :hp
    
    SYMBOL_FOR_UNIT = {
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
    
    TYPE_FOR_SYMBOL = {
      :linf => 'Trooper',
      :hinf => 'Heavy Trooper',
      :raider => 'Raider',
      :tank => 'Tank',
      :htank => 'Heavy Tank',
      :lart => 'Light Artillery',
      :hart => 'Heavy Artillery',
      # TODO: rest
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
      :lart => 200,
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
      :bomber => 900,
      :aa => 300,
    }
    
    # Units are created by the Map class.  No need to instantiate any on your own.
    def initialize( game, hex, faction, type, hp, finished, capturing = false )
      sym = SYMBOL_FOR_UNIT[ type ]
      if sym.nil?
        raise "Unknown type: '#{type}'"
      end
      
      @game, @hex, @faction, @type, @hp, @finished, @capturing =
        game, hex, faction, sym, hp.to_i, finished, capturing
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
      not @finished
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

    # Returns an Array of the Hexes which the given Unit can attack in this turn.
    def targets
      coords = XmlSimple.xml_in(
        @game.send( "<attackOptions x='#{x}' y='#{y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>" )
      )
      coords.map { |c|
        @game.map[ c[ 'x' ], c[ 'y' ] ]
      }
    end
    alias attack_options targets
    alias attackOptions targets
    
    # Returns an Array of the Hexes which the given Unit can move to in this turn.
    def destinations
      coords = XmlSimple.xml_in(
        @game.send( "<movementOptions x='#{x}' y='#{y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>" )
      )
      coords.map { |c|
        @game.map[ c[ 'x' ], c[ 'y' ] ]
      }
    end
    alias movement_options destinations
    alias movementOptions destinations
    
    # Returns an Array of the Units on the same side as the given Unit.
    def allied_units
      @game.units.find_all { |u| u.faction == @faction }
    end
    
  end
end