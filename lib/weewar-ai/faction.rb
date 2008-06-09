module WeewarAI
  
  # Instances of the Faction class correspond to factions in a Game.
  # They provide some utility methods about factions, such as whether
  # or not a faction is currently playing in a Game, or whether it can
  # afford to buy a unit type.
  class Faction
    attr_reader :credits, :player_id, :player_name, :state
    
    # You should not need to instantiate any Faction s on your own;
    # they are created for you by Game instances.
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
    
    # Whether or not this Faction is the one whose turn it is in the Game.
    #   i = me = my = game.my_faction
    #   is_my_turn = i.current?
    def current?
      @current
    end
    
    def playing?
      @state == 'playing'
    end
    
    # True iff the faction has enough credits to purchase a unit of the given type.
    #   i = me = my = game.my_faction
    #   if i.can_afford? :hart
    #     my_base.build :hart
    #   end
    def can_afford?( type )
      @credits >= WeewarAI::Unit::UNIT_COSTS[ type ]
    end
    
    # An Array of the Unit s in the Game belonging to this Faction.
    #   i = me = my = game.my_faction
    #   my_units = my.units
    def units
      @game.units.find_all { |u| u.faction == self }
    end
   
    def to_s
      @player_name
    end
  end
end