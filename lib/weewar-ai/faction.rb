module WeewarAI
  class Faction
    attr_reader :credits, :player_id, :player_name, :state
    
    def initialize( game, xml, ordinal )
      @game, @ordinal = game, ordinal
      @credits = xml[ 'credits' ].to_i
      @current = ( xml[ 'current' ] == 'true' )
      @player_id = xml[ 'playerId' ].to_i
      @player_name = xml[ 'playerName' ]
      @state = xml[ 'state' ]
    rescue Exception => e
      $stderr.puts "Input XML: " + xml.inspect
      raise e
    end
    alias playerId player_id
    alias playerName player_name
    
    def current?
      @current
    end
    
    def playing?
      @state == 'playing'
    end
    
    # Returns true iff the faction has enough credits to purchase a unit of the given type.
    def can_afford?( type )
      @credits >= WeewarAI::Unit::UNIT_COSTS[ type ]
    end
    
    # Returns an Array of the Units belonging to this faction.
    def units
      @game.units.find_all { |u| u.faction == self }
    end
   
    def to_s
      @player_name
    end
  end
end