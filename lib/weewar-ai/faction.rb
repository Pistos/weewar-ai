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
  end
end