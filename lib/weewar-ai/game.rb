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

module WeewarAI
  class Game
    attr_reader :id, :name, :round, :state, :pending_invites, :pace, :type,
      :url, :map, :map_url, :credits_per_base, :initial_credits, :playing_since,
      :players
    
    def self.[]( id )
      id = id.to_i
      new(
        XmlSimple.xml_in(
          WeewarAI::API.get( "/gamestate/#{id}" ),
          { 'ForceArray' => [ 'player' ], }
        )
      )
    end
    
    def initialize( xml )
      @id = xml[ 'id' ].to_i
      @name = xml[ 'name' ]
      @round = xml[ 'round' ].to_i
      @state = xml[ 'state' ]
      @pending_invites = ( xml[ 'pendingInvites' ] == 'true' )
      @pace = xml[ 'pace' ].to_i
      @type = xml[ 'type' ]
      @url = xml[ 'url' ]
      @players = xml[ 'players' ][ 'player' ].map { |p| WeewarAI::Player.new( p ) }
      @map = xml[ 'map' ].to_i
      @map_url = xml[ 'mapUrl' ]
      @credits_per_base = xml[ 'creditsPerBase' ]
      @initial_credits = xml[ 'initialCredits' ]
      @playing_since = Time.parse( xml[ 'playingSince' ] )
    end
    alias pendingInvites pending_invites
    alias mapUrl map_url
    alias creditsPerBase credits_per_base
    alias initialCredits initial_credits
    alias playingSince playing_since
    
    def send( command_xml )
      WeewarAI::API.send "<weewar game='#{@id}'>#{command_xml}</weewar>"
    end
    
    def finish_turn
      send "<finishTurn/>"
    end
    alias finishTurn finish_turn
    def accept_invitation
      send "<acceptInvitation/>"
    end
    alias acceptInvitation accept_invitation
    def decline_invitation
      send "<declineInvitation/>"
    end
    alias declineInvitation decline_invitation
    def surrender
      send "<surrender/>"
    end
    def abandon
      send "<abandon/>"
    end
    def remove_game
      send "<removeGame/>"
    end
    alias removeGame remove_game
    
  end
end