#!/usr/bin/env ruby

module WeewarAI
  # @games
  # @needy_games
  class AI
    # params: {
    #   :server,
    #   :username,
    #   :api_key,
    # }
    def initialize( params )
      @username = params[ :username ]
      WeewarAI::API.init( params )
      refresh
    end

    def refresh
      xml = XmlSimple.xml_in(
        WeewarAI::API.get( "/headquarters" ),
        { 'ForceArray' => [ 'game' ], }
      )
      @games = xml[ 'game' ].map { |g|
        WeewarAI::Game[ g[ 'id' ] ]
      }
      @needy_games = @games.find_all { |g|
        g.current_player.name == @username
      }
    end
  end
end