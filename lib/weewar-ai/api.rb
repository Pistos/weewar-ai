require 'mechanize'

module WeewarAI
  class API
    # params: {
    #   :server,
    #   :username,
    #   :api_key,
    # }
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
    
    def self.agent
      trait[ :agent ]
    end
    def self.server
      trait[ :server ]
    end
    
    def self.get( path )
      agent.get( "http://#{server}/api1/#{path}" ).body
    end
    
    def self.send( xml )
      url = URI.parse( "http://#{server}/api1/eliza" )
      req = Net::HTTP::Post.new( url.path )
      req.basic_auth( trait[ :username ], trait[ :api_key ] )
      req[ 'Content-Type' ] = 'application/xml'
      Net::HTTP.new( url.host, url.port ).start { |http|
        http.request( req, xml )
      }
    end
  end
end