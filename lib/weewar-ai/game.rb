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



module WeewarAI
  class Game
    attr_reader :id
    
    def self.[]( id )
      id = id.to_i
      new( XmlSimple.xml_in( WeewarAI::API.get( "/api1/gamestate/#{id}" ) ) )
    end
    
    def initialize( xml )
      @id = xml[ 'id' ]
    end
  end
end