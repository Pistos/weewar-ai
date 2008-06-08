require 'net/http'
require 'pistos'

module WeewarAI
  
  # The Game class is your interface to a game on the weewar server.
  # Game instances are used to do such things as finish turns, surrender,
  # and abandon.  Also, you access game maps and units through a Game
  # instance.
  class Game
    attr_reader :id, :name, :round, :state, :pending_invites, :pace, :type,
      :url, :map, :map_url, :credits_per_base, :initial_credits, :playing_since,
      :players, :units
    attr_accessor :last_attacked
    
    # Instantiate a new Game instance corresponding to the weewar game
    # with the given id number.
    def initialize( id )
      @id = id.to_i
      refresh
    end
    alias pendingInvites pending_invites
    alias mapUrl map_url
    alias creditsPerBase credits_per_base
    alias initialCredits initial_credits
    alias playingSince playing_since
    
    # Hits the weewar server for all the game state data as it sees it.
    # All internal variables are updated to match.
    def refresh
      xml = XmlSimple.xml_in(
        WeewarAI::API.get( "/gamestate/#{id}" ),
        { 'ForceArray' => [ 'faction', 'player', 'terrain', 'unit' ], }
      )
      #$stderr.puts xml.nice_inspect
      @name = xml[ 'name' ]
      @round = xml[ 'round' ].to_i
      @state = xml[ 'state' ]
      @pending_invites = ( xml[ 'pendingInvites' ] == 'true' )
      @pace = xml[ 'pace' ].to_i
      @type = xml[ 'type' ]
      @url = xml[ 'url' ]
      @players = xml[ 'players' ][ 'player' ].map { |p| WeewarAI::Player.new( p ) }
      @map = WeewarAI::Map.new( self, xml[ 'map' ].to_i )
      @map_url = xml[ 'mapUrl' ]
      @credits_per_base = xml[ 'creditsPerBase' ]
      @initial_credits = xml[ 'initialCredits' ]
      @playing_since = Time.parse( xml[ 'playingSince' ] )
      
      @units = Array.new
      @factions = Array.new
      xml[ 'factions' ][ 'faction' ].each_with_index do |faction_xml,ordinal|
        faction = Faction.new( self, faction_xml, ordinal )
        @factions << faction
        
        faction_xml[ 'unit' ].each do |u|
          hex = @map[ u[ 'x' ], u[ 'y' ] ]
          unit = Unit.new(
            self,
            hex,
            faction,
            u[ 'type' ],
            u[ 'quantity' ].to_i,
            u[ 'finished' ] == 'true',
            u[ 'capturing' ] == 'true'
          )
          @units << unit
          hex.unit = unit
        end
        
        faction_xml[ 'terrain' ].each do |terrain|
          hex = @map[ terrain[ 'x' ], terrain[ 'y' ] ]
          if hex.type == :base
            hex.faction = faction
          end
        end
      end
    end
    
    # Sends some command XML for this game to the server.  You should
    # generally never need to call this method directly; it is used
    # internally by the Game class.
    def send( command_xml )
      WeewarAI::API.send "<weewar game='#{@id}'>#{command_xml}</weewar>"
    end
    
    #-- -------------------------
    # API Commands
    #++
    
    # End turn in this game.
    def finish_turn
      send "<finishTurn/>"
    end
    alias finishTurn finish_turn
    
    # Surrender in this game.
    def surrender
      send "<surrender/>"
    end
    
    # Abandon this game.
    def abandon
      send "<abandon/>"
    end
    
    #-- -------------------------
    # Game state
    #++
    
    # The Player whose turn it is.
    def current_player
      @players.find { |p| p.current? }
    end
    
    #-- --------------------------------------------------
    # Utilities
    #++
    
    # The Faction of the given player.
    def faction_for_player( player_name )
      @factions.find { |f| f.player_name == player_name }
    end
    
    # Your AI's Faction in this game.
    def my_faction
      faction_for_player WeewarAI::API.username
    end
    
    # An Array of the Units not belonging to the given faction.
    def units_not_of( faction )
      @units.find_all { |u| u.faction != faction }
    end
    
    # An Array of the Units not belonging to your AI.
    def enemy_units
      units_not_of my_faction
    end
    
    # An Array of the base Hexes for this game.
    def bases
      @map.bases
    end
    
    # An Array of the base Hexes owned by the given faction.
    def bases_of( faction )
      @map.bases.find_all { |b| b.faction == faction }
    end
    
    # Your AI's bases in this game.
    def my_bases
      bases_of my_faction
    end
    
    # An Array of the base Hex es which are not owned by the given faction.
    def bases_not_of( faction )
      @map.bases.find_all { |b| b.faction != faction }
    end
    
    # An Array of bases not owned by your AI (including neutral bases).
    def enemy_bases
      bases_not_of my_faction
    end
        
  end
end