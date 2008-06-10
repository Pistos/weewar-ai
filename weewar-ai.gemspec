#!/usr/bin/env ruby

spec = Gem::Specification.new do |s|
    s.name = 'weewar-ai'
    s.version = '2008.06.10.0'
    s.summary = 'weewar.com API interface library'
    s.description = 'weewar-ai lets you interface the weewar.com API using Ruby.'
    s.homepage = 'http://weewar.purepistos.net/ai-doc/'
    s.add_dependency( 'mechanize' )
    s.add_dependency( 'hpricot' )
    s.add_dependency( 'xml-simple' )
    
    s.authors = [ 'Pistos' ]
    s.email = 'pistos at purepistos dot net'
    
    s.files = [
        'THAT',
        'READTHAT',
        #'CHANGELOG',
        *( Dir[
          'lib/weewar-ai.rb',
          'lib/weewar-ai/api.rb',
          'lib/weewar-ai/traits.rb',
          'lib/weewar-ai/game.rb',
          'lib/weewar-ai/__dir__.rb',
          'lib/weewar-ai/player.rb',
          'lib/weewar-ai/map.rb',
          'lib/weewar-ai/hex.rb',
          'lib/weewar-ai/faction.rb',
          'lib/weewar-ai/unit.rb',
          'lib/weewar-ai/ai.rb',
          'Rakefile',
          'examples/basic.rb',
          #'spec/**/*.rb',
        ] )
    ]
    s.extra_rdoc_files = [
      'THAT', 'READTHAT', # 'CHANGELOG'
    ]
    
    #s.test_files = Dir.glob( 'spec/*.rb' )
end

if $PROGRAM_NAME == __FILE__
    Gem::Builder.new( spec ).build
end
