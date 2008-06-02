#!/usr/bin/env ruby

module WeewarAI
  class AI
    attr_reader :games
    
    # params: {
    #   :server,
    #   :username,
    #   :api_key,
    # }
    def initialize( params )
      WeewarAI::API.init( params )
      
      xml = XmlSimple.xml_in(
        WeewarAI::API.get( "/headquarters" ),
        { 'ForceArray' => [ 'game' ], }
      )
      @games = xml[ 'game' ].map { |g|
        WeewarAI::Game[ g[ 'id' ] ]
      }
    end

  end
end