require 'mechanize'

module WeewarAI
  GOD_LOVES_YOU = true
  
  # The API class provides a means for your AI to accept and decline
  # invitations, and remove games from your AI's headquarters.  There
  # are also some lower-level methods, but you should not normally need
  # to use them.
  class API
    # Initializes the connection to the weewar.com API.  You do not need to
    # call this yourself; it is called for you when you subclass AI.
    def self.init( params )
      [ :server, :username, :api_key ].each do |required_param|
        if params[ required_param ].nil? or params[ required_param ].strip.empty?
          raise "Missing #{required_param}."
        end
      end
      
      trait[ :agent ] = agent = WWW::Mechanize.new
      trait[ :username ], trait[ :api_key ] = params[ :username ], params[ :api_key ]
      agent.basic_auth( params[ :username ], params[ :api_key ] )
      trait[ :server ] = params[ :server ]
      
      Hex.initialize_specs
    end
    
    def self.username
      trait[ :username ]
    end
    def self.agent
      trait[ :agent ]
    end
    def self.server
      trait[ :server ]
    end
    
    def self.get( path )
      result = nil
      retries = 0
      while GOD_LOVES_YOU
        url = "http://#{server}/api1/#{path}"
        begin
          result = agent.get( url ).body
          break
        rescue EOFError, Errno::EPIPE => e
          if retries < 10
            $stderr.puts "Communications error fetching '#{url}'.  Retrying (#{retries})..."
            sleep retries + 3
            retries += 1
          else
            break
          end
        end
      end
      if $debug
        $stderr.puts "XML RECEIVE: #{result}"
      end
      result
    end
    
    def self.send( xml )
      url = URI.parse( "http://#{server}/api1/eliza" )
      req = Net::HTTP::Post.new( url.path )
      req.basic_auth( trait[ :username ], trait[ :api_key ] )
      req[ 'Content-Type' ] = 'application/xml'
      result = Net::HTTP.new( url.host, url.port ).start { |http|
        if $debug
          $stderr.puts "XML SEND: #{xml}"
        end
        http.request( req, xml )
      }.body
      if $debug
        $stderr.puts "XML RECEIVE: #{result}"
      end
      result
    end
    
    # Accepts an invitation to a game.
    def self.accept_invitation( game_id )
      send "<weewar game='#{game_id}'><acceptInvitation/></weewar>"
    end
    
    # Declines an invitation to a game.
    def self.decline_invitation( game_id )
      send "<weewar game='#{game_id}'><declineInvitation/></weewar>"
    end
    
    # Removes a game from your AI's headquarters.
    def self.remove_game( game_id )
      send "<weewar game='#{game_id}'><removeGame/></weewar>"
    end
    
    class << self
      alias acceptInvitation accept_invitation
      alias declineInvitation decline_invitation
      alias removeGame remove_game
    end
    
  end
end