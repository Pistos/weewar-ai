module WeewarAI
  class Map
    attr_reader :width, :height, :terrain
    
    SYMBOL_FOR_TERRAIN = {
      'Plains' => :plains,
      'Water' => :water,
      'Mountains' => :mountains,
      'Desert' => :desert,
      'Woods' => :woods,
      'Swamp' => :swamp,
      'Base' => :base,
      'harbor' => :harbour,
      'repairshop' => :repairshop,
      'airfield' => :airfield,
      'red_city' => :red_base,
      'blue_city' => :blue_base,
      'purple_city' => :purple_base,
      'yellow_city' => :yellow_base,
      'green_city' => :green_base,
      'white_city' => :white_base,
      'red_harbor' => :red_harbour,
      'blue_harbor' => :blue_harbour,
      'purple_harbor' => :purple_harbour,
      'yellow_harbor' => :yellow_harbour,
      'green_harbor' => :green_harbour,
      'white_harbor' => :white_harbour,
      'red_airfield' => :red_airfield,
      'blue_airfield' => :blue_airfield,
      'purple_airfield' => :purple_airfield,
      'yellow_airfield' => :yellow_airfield,
      'green_airfield' => :green_airfield,
      'white_airfield' => :white_airfield,
    }
    
    def self.[]( id )
      id = id.to_i
      new(
        XmlSimple.xml_in(
          WeewarAI::API.get( "/maplayout/#{id}" ),
          { 'ForceArray' => [ 'terrain' ], }
        )
      )
    end
    
    def initialize( xml )
      @width = xml[ 'width' ].to_i
      @height = xml[ 'height' ].to_i
      @rows = Array.new
      xml[ 'terrains' ][ 'terrain' ].each do |t|
        x = t[ 'x' ].to_i
        @rows[ x ] ||= Array.new
        y = t[ 'y' ].to_i
        @rows[ x ][ y ] = Hex.new(
          SYMBOL_FOR_TERRAIN[ t[ 'type' ] ],
          x, y
        )
      end
    end
    
    def hex( x, y )
      x = x.to_i
      y = y.to_i
      c = @rows[ x ]
      if c
        c[ y ]
      end
    end
    alias xy hex
    
    # row-column
    def rc( y, x )
      hex( x, y )
    end
    
    # Returns an Array of Hexes for the given Hex.
    # The result will not contain any nil elements.
    def hex_neighbours( h )
      if h.y % 2 == 0
        # Even row (not shifted)
        [
          hex( h.x    , h.y - 1 ), # NE
          hex( h.x + 1, h.y     ), # E
          hex( h.x    , h.y + 1 ), # SE
          hex( h.x - 1, h.y + 1 ), # SW
          hex( h.x - 1, h.y     ), # W
          hex( h.x - 1, h.y - 1 ), # NW
        ].compact
      else
        # Odd row (shifted right)
        [
          hex( h.x + 1, h.y - 1 ), # NE
          hex( h.x + 1, h.y     ), # E
          hex( h.x + 1, h.y + 1 ), # SE
          hex( h.x    , h.y + 1 ), # SW
          hex( h.x - 1, h.y     ), # W
          hex( h.x    , h.y - 1 ), # NW
        ].compact
      end
    end
    
    # Iterates over every Hex in the map.
    # Takes a block argument, as per the usual Ruby each method.
    def each( &block )
      @rows.flatten.compact.each &block
    end
        
    # Returns all Hexes which match the conditions of the given block.
    def find_all( &block )
      @rows.flatten.compact.find_all &block
    end
        
    # Returns all base Hexes.
    def bases
      find_all { |hex| hex.type == :base }
    end
        
    # Returns the cost in movement points for the given unit to enter the given Hex.
    def entrance_cost( unit, hex )
      if unit and hex
        specs_for_type = Hex.terrain_specs[ hex.type ]
        if specs_for_type.nil?
          raise "No specs for type '#{hex.type}'"
        end
        movement_specs = specs_for_type[ :movement ]
        movement_specs[ unit.unit_class ]
      else
        nil
      end
    end
        
    # Returns the shortest path (as an Array of Hexes) from the given
    # unit's current location to the given destination.
    # If the optional exclusion array is provided, the path will not
    # pass through any Hex in the exclusion array.
    def shortest_path( unit, dest, exclusions = [] )
      previous = shortest_paths( unit, exclusions )
      s = []
      u = dest.hex
      while previous[ u ]
        s.unshift u
        u = previous[ u ]
      end
      s
    end
    
    # Returns the cost in movement points for the given unit to
    # travel along the given path.  The path should be an Array
    # of Hexes.
    def path_cost( unit, path )
      path.inject( 0 ) { |sum,hex|
        sum + entrance_cost( unit, hex )
      }
    end
    
    # Returns the cost in movement points for the given unit to
    # travel to the given destination
    def travel_cost( unit, dest )
      sp = shortest_path( unit, dest )
      path_cost(
        unit,
        sp
      )
    end
    
    private
    
    # http://en.wikipedia.org/wiki/Dijkstra's_algorithm
    def shortest_paths( unit, exclusions = [] )
      # Initialization
      source = unit.hex
      dist = Hash.new
      previous = Hash.new
      q = []
      each do |h|
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
        hex_neighbours( u ).each do |v|
          next if exclusions.include? v
          alt = dist[ u ] + entrance_cost( unit, v )
          if alt < dist[ v ]
            dist[ v ] = alt
            previous[ v ] = u
          end
        end
      end
      
      # Results
      previous
    end
  end
end