module WeewarAI
  class Player
    attr_reader :name
    
    def self.[]( id )
      #id = id.to_i
      #new(
        #XmlSimple.xml_in(
          #WeewarAI::API.get( "/api1/gamestate/#{id}" ),
          #{ 'ForceArray' => false, }
        #)
      #)
    end
    
    def initialize( h )
      @name = h[ 'content' ]
      @current = ( h[ 'current' ] == 'true' )
    end
    
    def current?
      @current
    end
  end
end