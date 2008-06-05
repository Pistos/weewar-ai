module WeewarAI
  
  # A single unit in the game.
  class Unit
    attr_reader :faction, :hex, :type, :hp
    
    SYMBOL_FOR_UNIT = {
      'Trooper' => :linf,
      'Heavy Trooper' => :hinf,
      'Raider' => :raider,
      'Assault Artillery' => :aart,
      'Tank' => :tank,
      'Heavy Tank' => :htank,
      'Berserker' => :bers,
      'Light Artillery' => :lart,
      'Heavy Artillery' => :hart,
      'DFA' => :dfa,
      'Hovercraft' => :hover,
      #'capturing' => :capturing,
    }
    
    TYPE_FOR_SYMBOL = {
      :linf => 'Trooper',
      :hinf => 'Heavy Trooper',
      :raider => 'Raider',
      :tank => 'Tank',
      :htank => 'Heavy Tank',
      :lart => 'Light Artillery',
      :hart => 'Heavy Artillery',
      # TODO: rest
    }
    
    UNIT_CLASSES = {
      :linf => :soft,
      :hinf => :soft,
      :raider => :hard,
      :aart => :hard,
      :tank => :hard,
      :htank => :hard,
      :bers => :hard,
      :lart => :hard,
      :hart => :hard,
      :dfa => :hard,
      :capturing => :soft,
      :hover => :amphibic,
    }
    
    UNIT_COSTS = {
      :linf => 75,
      :hinf => 150,
      :raider => 200,
      :tank => 300,
      :hover => 300,
      :htank => 600,
      :lart => 200,
      :aart => 450,
      :hart => 600,
      :dfa => 1200,
      :bers => 900,
      :sboat => 200,
      :dest => 1100,
      :bship => 2000,
      :sub => 1200,
      :jet => 800,
      :heli => 600,
      :bomber => 900,
      :aa => 300,
    }
    
    INFINITY = 99999999
    
    # Units are created by the Map class.  No need to instantiate any on your own.
    def initialize( game, hex, faction, type, hp, finished, capturing = false )
      sym = SYMBOL_FOR_UNIT[ type ]
      if sym.nil?
        raise "Unknown type: '#{type}'"
      end
      
      @game, @hex, @faction, @type, @hp, @finished, @capturing =
        game, hex, faction, sym, hp.to_i, finished, capturing
    end
    
    def to_s
      "#{@faction} #{@type} @ (#{@hex.x},#{@hex.y})"
    end
    
    # The unit's current x coordinate.
    def x
      @hex.x
    end
    
    # The unit's current y coordinate
    def y
      @hex.y
    end
    
    # Whether or not the unit can be ordered to do anything.
    def moveable?
      not @finished
    end
    
    def capturing?
      @capturing
    end
    
    # The unit class of this unit. i.e. :soft, :hard, etc.
    def unit_class
      UNIT_CLASSES[ @type ]
    end
    
    def ==( other )
      @hex == other.hex and
      @faction == other.faction and
      @type == other.type
    end
    
    def can_capture?
      [ :linf, :hinf, :hover ].include? @type
    end

    # Returns an Array of the Units which this Unit can attack in this turn.
    # If the optional origin Hex is provided, the target list is calculated
    # as if the unit were on that Hex instead of its current Hex.
    def targets( origin = @hex )
      coords = XmlSimple.xml_in(
        @game.send( "<attackOptions x='#{origin.x}' y='#{origin.y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>" )
      )[ 'coordinate' ]
      if coords
        coords.map { |c|
          @game.map[ c[ 'x' ], c[ 'y' ] ].unit
        }.compact
      else
        []
      end
    end
    alias attack_options targets
    alias attackOptions targets
    
    def can_attack?( target )
      targets.include? target
    end
    
    # Returns an Array of the Hexes which the given Unit can move to in this turn.
    def destinations
      coords = XmlSimple.xml_in(
        @game.send( "<movementOptions x='#{x}' y='#{y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>" )
      )[ 'coordinate' ]
      coords.map { |c|
        @game.map[ c[ 'x' ], c[ 'y' ] ]
      }
    end
    alias movement_options destinations
    alias movementOptions destinations
    
    def can_reach?( hex )
      destinations.include? hex
    end
    
    # Returns an Array of the Units on the same side as the given Unit.
    def allied_units
      @game.units.find_all { |u| u.faction == @faction }
    end
    
    def allied_with?( unit )
      @faction == unit.faction
    end
    
    # ----------------------------------------------
    # Travel
    
    # Returns the cost in movement points for the unit to enter the given Hex.
    def entrance_cost( hex )
      return nil if hex.nil?
      
      specs_for_type = Hex.terrain_specs[ hex.type ]
      if specs_for_type.nil?
        raise "No specs for type '#{hex.type.inspect}': #{Hex.terrain_specs.inspect}"
      end
      specs_for_type[ :movement ][ unit_class ]
    end
        
    
    # Returns the cost in movement points for the unit to
    # travel along the given path.  The path should be an Array
    # of Hexes.
    def path_cost( path )
      path.inject( 0 ) { |sum,hex|
        sum + entrance_cost( hex )
      }
    end
    
    # Returns the cost in movement points for this unit to travel to the given
    # destination.
    def travel_cost( dest )
      sp = shortest_path( dest )
      path_cost( sp )
    end
    
    # Returns the shortest path (as an Array of Hexes) from the
    # unit's current location to the given destination.
    # If the optional exclusion array is provided, the path will not
    # pass through any Hex in the exclusion array.
    def shortest_path( dest, exclusions = [] )
      exclusions ||= []
      previous = shortest_paths( exclusions )
      s = []
      u = dest.hex
      while previous[ u ]
        s.unshift u
        u = previous[ u ]
      end
      s
    end
    
    # http://en.wikipedia.org/wiki/Dijkstra's_algorithm
    def shortest_paths( exclusions = [] )
      # Initialization
      exclusions ||= []
      source = hex
      dist = Hash.new
      previous = Hash.new
      q = []
      @game.map.each do |h|
        if not exclusions.include? h
          dist[ h ] = INFINITY
          q << h
        end
      end
      dist[ source ] = 0
      
      # Work
      while not q.empty?
        u = q.inject { |best,h| dist[ h ] < dist[ best ] ? h : best }
        q.delete u
        @game.map.hex_neighbours( u ).each do |v|
          next if exclusions.include? v
          alt = dist[ u ] + entrance_cost( v )
          if alt < dist[ v ]
            dist[ v ] = alt
            previous[ v ] = u
          end
        end
      end
      
      # Results
      previous
    end
    
    # --------------------------------------------------
    # Actions 
    
    def send( xml )
      @game.send "<unit x='#{x}' y='#{y}'>#{xml}</unit>"
    end
    
    # Moves the given Unit to the given destination if it is reachable
    # in one turn, otherwise moves the Unit towards it using the optimal path.
    #
    # If a Unit or an Array of Units is passed for :also_attack, those Units
    # will be prioritized for attack after moving, with the Units assumed to be
    # given from highest priority (index 0) to lowest.
    #
    # If an Array of hexes is provided as :exclusions, the Unit will not pass through
    # any of the exclusion Hexes on its way to the destination.
    #
    # By default, moving onto a base with a capturing unit will attempt a capture.
    # Set :no_capture => true to prevent this.
    #
    # Returns true on successful move, nil otherwise.
    def move_to( destination, options = {} )
      command = ""
      options[ :exclusions ] ||= []
      
      new_hex = @hex
      
      if destination != @hex
        # Travel
        
        path = shortest_path( destination, options[ :exclusions ] )
        if path.empty?
          $stderr.puts "No path from #{self} to #{destination}"
        else
          dests = destinations
          new_dest = path.pop
          while new_dest and not dests.include?( new_dest )
            new_dest = path.pop
          end
        end
        
        if new_dest.nil?
          $stderr.puts "  Can't move #{self} to #{destination}"
        else
          o = new_dest.unit
          if o and allied_with?( o )
            # Can't move through allied units
            options[ :exclusions ] << new_dest
            return move_to( destination, options )
          else
            x = new_dest.x
            y = new_dest.y
            new_hex = new_dest
            command << "<move x='#{x}' y='#{y}'/>"
          end
        end
      end
      
      target = nil
      also_attack = options[ :also_attack ]
      if also_attack
        enemies = targets( new_hex )
        if not enemies.empty?
          case also_attack
          when Array
            preferred = also_attack & enemies
          else
            preferred = [ also_attack ] & enemies
          end
          target = preferred.first# || enemies.random
          
          if target
            command << "<attack x='#{target.x}' y='#{target.y}'/>"
          end
        end
      end
      
      if(
        not options[ :no_capture ] and
        can_capture? and
        new_hex == destination and
        new_hex.capturable?
      )
        puts "#{self} capturing #{new_hex}"
        command << "<capture/>"
      else
        $stderr.puts "\tcan_capture? #{can_capture?.nice_inspect}"
        $stderr.puts "\tnew_hex: #{new_hex}"
        $stderr.puts "\tcapturable? #{new_hex.capturable?}"
      end
    
      result = send( command )
      success = ( /<ok>/ === result )
      if success
        @game.refresh
        puts "Moved #{self} to #{new_hex}"
        @hex = new_hex
        if target
          puts "  #{self} attacked #{target}"
          @game.last_attacked = target
        end
      end
      success
    end
    alias move move_to
    
    #<ok>
    #<attack target='[3,4]' damageReceived='2' damageInflicted='7' remainingQuantity='8' />
    #<finished/>
    #</ok>
    
    # Provide either a Unit or coordinates to attack.
    # Returns true iff the unit successfully attacked.
    def attack( unit )
      x = unit.x
      y = unit.y
      
      result = send "<attack x='#{x}' y='#{y}'/>"
      success = ( /<ok>/ === result )
      if success
        @game.refresh
        @game.last_attacked = @game.map[ x, y ].unit
      end
      success
    end
    
    def repair
      send "<repair/>"
    end
  end
end