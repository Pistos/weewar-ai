#!/usr/bin/env ruby

# All parts of the library reside in the WeewarAI module.
module WeewarAI
  
  # Begin creating your bot by subclassing the WeewarAI::AI class.
  #
  #    class MyBot < WeewarAI::AI
  #    end
  #
  class AI
    # In your bot's initialize method, call the AI superclass's
    # initialize method with these parameters:
    #
    #   super(
    #     :server => 'test.weewar.com',
    #     :username => 'aiMyBot',
    #     :api_key => 'r0goujPhKJEM6udL3RNfBtcS9',
    #   )
    #
    # Retrieve your API key from http://test.weewar.com/apiToken .
    #
    # Once constructed, your AI instance will have the following instance
    # variables available:
    #
    # @games       : An Array of the Game s your AI is in.
    #
    # @needy_games : The subset of Game s in which it is your AI's turn.
    #
    # @invitations : The ids of Game s to which your AI is invited.
    def initialize( params )
      @username = params[ :username ]
      WeewarAI::API.init( params )
      refresh
    end

    # Retrieves your AI's headquarters data from the game server,
    # and updates the instance variables @games, @needy_games and
    # @invitations.
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
        WeewarAI::Game.new( g[ 'id' ] )
      }
      @needy_games = @games.find_all { |g|
        g.current_player and g.current_player.name == @username
      }
    end
    
    # Accepts the invitation to join the game identified by the game_id.
    def accept_invitation( game_id )
      response = WeewarAI::API.accept_invitation( game_id )
      %r{<ok/>} === response
    end
    
    # Accepts all game invitations.
    def accept_all_invitations
      one_accepted = false
      @invitations.each do |invitation|
        one_accepted ||= accept_invitation( invitation )
      end
      one_accepted
    end
  end
end