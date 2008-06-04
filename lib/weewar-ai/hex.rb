require 'open-uri'
require 'hpricot'

module WeewarAI
  
  # One hex in a map.
  class Hex
    attr_reader :x, :y, :type
    attr_accessor :faction, :unit
    
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
      'Water' => :water,
      'Woods' => :woods,
    }
    
    # Downloads the specs from weewar.com.  This is called from WeewarAI::AI.
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
    
    # No need to call this yourself.  Hexes are parsed and built
    # by the Map class.
    def initialize( game, type, x, y )
      @game, @type, @x, @y = game, type, x, y
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
    
    def build( unit_type )
      @game.send "<build x='#{@x}' y='#{@y}' type='#{WeewarAI::Unit::TYPE_FOR_SYMBOL[unit_type]}'/>"
    end
    
    def occupied?
      not @unit.nil?
    end
  end
end
