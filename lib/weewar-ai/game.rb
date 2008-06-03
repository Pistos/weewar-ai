# <game>
# <id>34</id>
# <name>AI test.</name>
# <round>1</round>
# <state>running</state>
# <pendingInvites>false</pendingInvites>
# <pace>86400</pace>
# <type>Basic</type>
# <url>http://test.weewar.com/game/34</url>
# <players>
# <player current='true' >Pistos2</player>
# </players>
# <map>8</map>
# <mapUrl>http://test.weewar.com/map/8</mapUrl>
# <creditsPerBase>100</creditsPerBase>
# <initialCredits>300</initialCredits>
# <playingSince>Thu May 29 17:39:51 UTC 2008</playingSince>
# <factions>
# <faction current='true' playerId='49' playerName='Pistos2' credits='400' state='playing'  >
# <unit x='2' y='2' type='Trooper' quantity='10' finished='false'  />
# <terrain x='1' y='2' type='Base' finished='false' />
# </faction>
# </factions>
# </game>

require 'net/http'
require 'pistos'

module WeewarAI
  class Game
    attr_reader :id, :name, :round, :state, :pending_invites, :pace, :type,
      :url, :map, :map_url, :credits_per_base, :initial_credits, :playing_since,
      :players, :units
    
    def self.[]( id )
      id = id.to_i
      new(
        XmlSimple.xml_in(
          WeewarAI::API.get( "/gamestate/#{id}" ),
          { 'ForceArray' => [ 'faction', 'player', 'terrain', 'unit' ], }
        )
      )
    end
    
    def initialize( xml )
      #$stderr.puts xml.nice_inspect
      @id = xml[ 'id' ].to_i
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
        $stderr.puts faction_xml.nice_inspect
        
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
    alias pendingInvites pending_invites
    alias mapUrl map_url
    alias creditsPerBase credits_per_base
    alias initialCredits initial_credits
    alias playingSince playing_since
    
    def send( command_xml )
      WeewarAI::API.send "<weewar game='#{@id}'>#{command_xml}</weewar>"
    end
    
    # ---------------------------
    # API Commands
    
    def finish_turn
      send "<finishTurn/>"
    end
    alias finishTurn finish_turn
    
    def surrender
      send "<surrender/>"
    end
    
    def abandon
      send "<abandon/>"
    end
    
    # ---------------------------
    # Game state
    
    def current_player
      @players.find { |p| p.current? }
    end
    
    #-- --------------------------------------------------
    # Utilities
    #++
    
    def faction_for_player( player_name )
      @factions.find { |f| f.player_name == player_name }
    end
    
    def my_faction
      faction_for_player WeewarAI::API.username
    end
    
    # Returns an Array of the Units not belonging to the given faction.
    def units_not_of( faction )
      @units.find_all { |u| u.faction != faction }
    end
    
    def enemy_units
      units_not_of my_faction
    end
    
    # Returns an Array of the base Hexes for this game.
    def bases
      @map.bases
    end
    
    # Returns an Array of the base Hexes owned by the given faction.
    def bases_of( faction )
      @map.bases.find_all { |b| b.faction == faction }
    end
    
    def my_bases
      bases_of my_faction
    end
    
    # Returns an Array of the base Hexes which are not owned by the given faction.
    def bases_not_of( faction )
      @map.bases.find_all { |b| b.faction != faction }
    end
        
    #-- --------------------------------------------------
    # Actions
    #++
  end
end