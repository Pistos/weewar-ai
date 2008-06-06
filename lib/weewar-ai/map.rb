module WeewarAI
  class Map
    attr_reader :width, :height, :cols, :units
    
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
    
    def initialize( game, map_id )
      @game = game
      
      map_id = map_id.to_i
      xml = XmlSimple.xml_in(
        WeewarAI::API.get( "/maplayout/#{map_id}" ),
        { 'ForceArray' => [ 'terrain' ], }
      )
      
      @width = xml[ 'width' ].to_i
      @height = xml[ 'height' ].to_i
      @cols = Hash.new
      xml[ 'terrains' ][ 'terrain' ].each do |t|
        x = t[ 'x' ].to_i
        @cols[ x ] ||= Hash.new
        y = t[ 'y' ].to_i
        @cols[ x ][ y ] = Hex.new(
          @game,
          SYMBOL_FOR_TERRAIN[ t[ 'type' ] ],
          x, y
        )
      end
    end
    
    def hex( x, y )
      x = x.to_i
      y = y.to_i
      c = @cols[ x ]
      if c
        c[ y ]
      end
    end
    alias xy hex
    
    def []( *xy )
      hex xy[ 0 ], xy[ 1 ]
    end
    
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
      @cols.values.map { |col| col.values }.flatten.compact.each &block
    end
        
    # Returns all Hexes which match the conditions of the given block.
    def find_all( &block )
      @cols.values.map { |col| col.values }.flatten.compact.find_all &block
    end
        
    # Returns all base Hexes.
    def bases
      find_all { |hex| hex.type == :base }
    end
        
  end
end