module WeewarAI
  class Map
    attr_reader :width, :height, :terrain
    
    def self.[]( id )
      id = id.to_i
      new(
        XmlSimple.xml_in(
          WeewarAI::API.get( "/maplayout/#{id}" ),
          { 'ForceArray' => [ 'terrain' ], }
        )
      )
    end
    
    def initialize( xml )
      @width = xml[ 'width' ].to_i
      @height = xml[ 'height' ].to_i
      @terrain = Hash.new
      xml[ 'terrains' ][ 'terrain' ].each do |t|
        x = t[ 'x' ].to_i
        @terrain[ x ] ||= Hash.new
        y = t[ 'y' ].to_i
        @terrain[ x ][ y ] = t[ 'type' ]
      end
    end
    
    def at( x, y )
      c = @terrain[ x ]
      if c
        c[ y ]
      end
    end
    alias xy at
    
    # row-column
    def rc( y, x )
      at( x, y )
    end
  end
end