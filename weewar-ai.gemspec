#!/usr/bin/env ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
    s.name = 'weewar-ai'
    s.version = '2008.06.09.1'
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
          'lib/**/*.rb',
          'Rakefile',
          'examples/*.rb',
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
