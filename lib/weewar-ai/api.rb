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
      agent.basic_auth( params[ :username ], params[ :api_key ] )
      trait[ :server ] = params[ :server ]
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
  end
end