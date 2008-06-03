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
    
    INFINITY = 99999999
    
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
      )[ 'coordinate' ]
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
    
    # ----------------------------------------------
    # Travel
    
    # Returns the cost in movement points for the unit to enter the given Hex.
    def entrance_cost( hex )
      return nil if hex.nil?
      
      specs_for_type = Hex.terrain_specs[ hex.type ]
      if specs_for_type.nil?
        raise "No specs for type '#{hex.type.inspect}': #{Hex.terrain_specs.inspect}"
      end
      specs_for_type[ :movement ][ unit_class ]
    end
        
    
    # Returns the cost in movement points for the unit to
    # travel along the given path.  The path should be an Array
    # of Hexes.
    def path_cost( path )
      path.inject( 0 ) { |sum,hex|
        sum + entrance_cost( hex )
      }
    end
    
    # Returns the cost in movement points for this unit to travel to the given
    # destination.
    def travel_cost( dest )
      sp = shortest_path( dest )
      path_cost( sp )
    end
    
    # Returns the shortest path (as an Array of Hexes) from the
    # unit's current location to the given destination.
    # If the optional exclusion array is provided, the path will not
    # pass through any Hex in the exclusion array.
    def shortest_path( dest, exclusions = [] )
      previous = shortest_paths( exclusions )
      s = []
      u = dest.hex
      while previous[ u ]
        s.unshift u
        u = previous[ u ]
      end
      s
    end
    
    # http://en.wikipedia.org/wiki/Dijkstra's_algorithm
    def shortest_paths( exclusions = [] )
      # Initialization
      source = hex
      dist = Hash.new
      previous = Hash.new
      q = []
      @game.map.each do |h|
        if not exclusions.include? h
          dist[ h ] = INFINITY
          q << h
        end
      end
      dist[ source ] = 0
      
      # Work
      while not q.empty?
        u = q.inject { |best,h| dist[ h ] < dist[ best ] ? h : best }
        q.delete u
        @game.map.hex_neighbours( u ).each do |v|
          next if exclusions.include? v
          alt = dist[ u ] + entrance_cost( v )
          if alt < dist[ v ]
            dist[ v ] = alt
            previous[ v ] = u
          end
        end
      end
      
      # Results
      previous
    end
    
    # --------------------------------------------------
    # Actions 
    
    def send( xml )
      @game.send "<unit x='#{x}' y='#{y}'>#{xml}</unit>"
    end
    
    # Returns true iff the unit successfully moved.
    def move_to( hex_or_x, y = nil )
      if y
        x = hex_or_x
      else
        x = hex_or_x.x
        y = hex_or_x.y
      end
      
      result = send "<move x='#{x}' y='#{y}'/>"
      /<ok>/ === result
    end
    alias move move_to
    
    # Returns true iff the unit successfully attacked.
    def attack( hex_or_x, y = nil )
      if y
        x = hex_or_x
      else
        x = hex_or_x.x
        y = hex_or_x.y
      end
      
      $debug = true
      result = send "<attack x='#{x}' y='#{y}'/>"
      $debug = false
      
      success = ( /<ok>/ === result )
      if success
        @game.last_attacked = @game.map[ x, y ].unit
      end
      success
    end
    
    def repair
      send "<repair/>"
    end
  end
end