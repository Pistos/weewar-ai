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
      gxml = xml[ 'game' ]
      @invitations = gxml.find_all { |g|
        g[ 'link' ] =~ /join/
      }.map { |g|
        g[ 'id' ].to_i
      }
      gxml = gxml.reject { |g|
        @invitations.include? g[ 'id' ].to_i
      }
      @games = gxml.map { |g|
        WeewarAI::Game[ g[ 'id' ] ]
      }
      @needy_games = @games.find_all { |g|
        g.current_player and g.current_player.name == @username
      }
    end
    
    def accept_invitation( game_id )
      response = WeewarAI::API.accept_invitation( game_id )
      %r{<ok/>} === response
    end
    
    def accept_all_invitations
      one_accepted = false
      @invitations.each do |invitation|
        one_accepted ||= accept_invitation( invitation )
      end
      one_accepted
    end
  end
end