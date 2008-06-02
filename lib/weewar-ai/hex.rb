require 'open-uri'
require 'hpricot'

module WeewarAI
  
  # One hex in a map.
  class Hex
    attr_reader :x, :y, :type
    attr_accessor :faction
    
    SYMBOL_FOR_NAME = {
      'Airfield' => :airfield,
      'Base' => :base,
      'Desert' => :desert,
      'Harbor' => :harbour,
      'Mountains' => :mountains,
      'Plains' => :plains,
      'Repair patch' => :repairshop,
      'Swamp' => :swamp,
      'water' => :water,
      'Woods' => :woods,
    }
    
    # No need to call this yourself.  Hexes are parsed and built
    # by the Map class.
    def initialize( type, x, y )
      @type, @x, @y = type, x, y
    end
    
    # Downloads the specs from weewar.com.  This is called from Weewar::AI::AI.
    # No need to call this yourself.
    def Hex.initialize_specs
      trait[ :terrain_specs ] = Hash.new
      doc = Hpricot( open( 'http://weewar.com/specifications' ) )
      doc.search( 'tr' ).each do |tr|
        type = SYMBOL_FOR_NAME[ tr.at( 'b' ).inner_text ]
        if type
          trait[ :terrain_specs ][ type ] = {
            :attack => parse_numbers( tr.search( 'td' )[ 2 ].inner_text ),
            :defense => parse_numbers( tr.search( 'td' )[ 3 ].inner_text ),
            :movement => parse_numbers( tr.search( 'td' )[ 4 ].inner_text ),
          }
        end
      end
    end
    
    # Used by initialize_specs.
    def Hex.parse_numbers( text )
      retval = Hash.new
      text.scan( /(\w+): (\d+)/ ) do |data|
        retval[ data[ 0 ].to_sym ] = data[ 1 ].to_i
      end
      retval
    end
    
    # Accessor for trait[ :terrain_specs ]
    def Hex.terrain_specs
      trait[ :terrain_specs ]
    end
    
    def to_s
      "#{@type} @ (#{@x},#{@y})"
    end
    
    def hex
      self
    end
    
    def ==( other )
      @x == other.x and @y == other.y and @type == other.type
    end

    # (legacy methods from previous library)
    
    def brighten
      @brightness = :bright
      self
    end
    def bright?
      @brightness == :bright
    end
    
    def darken
      @brightness = :dark
      self
    end
    def dark?
      @brightness == :dark
    end
    
    def mark
      @marked = true
    end
    def unmark
      @marked = false
    end
    def marked?
      @marked
    end
    
    def reset
      @brightness = :normal
      @marked = false
    end
    
  end
end
