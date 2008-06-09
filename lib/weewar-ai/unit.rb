module WeewarAI
  
  # An instance of the Unit class corresponds to a single unit in a game.
  #
  # The Unit class provides access to Unit attributes like coordinates (x, y),
  # health (hp), and type (trooper, raider, etc.).  Also available are tactical
  # calculation data, such as enemy targets that can be attacked, and hexes that
  # can be reached in the current turn.
  #
  # Unit s can be ordered to move, attack or repair.
  #
  # Read the full method listing to see everything you can do with a Unit.
  class Unit
    attr_reader :faction, :hex, :type
    attr_accessor :hp
    
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
    
    # <Pistos> These need to be checked, I was just going by memory
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
    
    # <Pistos> These need to be checked, I was just going by memory
    REPAIR_RATE = {
      :linf => 1,
      :hinf => 1,
      :raider => 2,
      :tank => 2,
      :hover => 2,
      :htank => 2,
      :lart => 1,
      :aart => 2,
      :hart => 1,
      :dfa => 1,
      :bers => 1,
      :sboat => 2,
      :dest => 1,
      :bship => 1,
      :sub => 1,
      :jet => 3,
      :heli => 3,
      :bomber => 3,
      :aa => 1,
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
    
    # The Unit's current x coordinate (column).
    def x
      @hex.x
    end
    
    # The Unit's current y coordinate (row).
    def y
      @hex.y
    end
    
    # Whether or not the unit can be ordered to do anything further.
    def finished?
      @finished
    end
    
    # Whether or not the unit is capturing a base at the moment.
    def capturing?
      @capturing
    end
    
    # The unit class of this unit. i.e. :soft, :hard, etc.
    def unit_class
      UNIT_CLASSES[ @type ]
    end
    
    # Comparison for equality with another Unit.
    # A Unit equals another Unit if it is standing on the same Hex,
    # is of the same Faction, and is the same type.
    def ==( other )
      @hex == other.hex and
      @faction == other.faction and
      @type == other.type
    end
    
    # Whether or not the Unit type can capture bases or not.
    # Be aware that this can return true even if the Unit is finished.
    def can_capture?
      [ :linf, :hinf, :hover ].include? @type
    end

    # An Array of the Units which this Unit can attack in the current turn.
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
    
    # Whether or not the Unit can attack the given target.
    # Returns true iff the Unit can still take action in the current round,
    # and the target is in range.
    def can_attack?( target )
      not @finished and targets.include?( target )
    end
    
    # An Array of the Hex es which the given Unit can move to in the current turn.
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
    
    # Whether or not the Unit can reach the given Hex in the current turn.
    def can_reach?( hex )
      destinations.include? hex
    end
    
    # An Array of the Unit s of the Game which are on the same side as this Unit.
    def allied_units
      @game.units.find_all { |u| u.faction == @faction }
    end
    
    # Whether or not the given unit is an ally of this Unit.
    def allied_with?( unit )
      @faction == unit.faction
    end
    
    #-- ----------------------------------------------
    # Travel
    #++
    
    # The cost in movement points for the unit to enter the given Hex.  This
    # is an internal method used for travel-related calculations; you should not
    # normally need to use this yourself.
    def entrance_cost( hex )
      return nil if hex.nil?
      
      specs_for_type = Hex.terrain_specs[ hex.type ]
      if specs_for_type.nil?
        raise "No specs for type '#{hex.type.inspect}': #{Hex.terrain_specs.inspect}"
      end
      specs_for_type[ :movement ][ unit_class ]
    end
    
    # The cost in movement points for the unit to travel along the given path.
    # The path given should be an Array of Hexes.  This
    # is an internal method used for travel-related calculations; you should not
    # normally need to use this yourself.
    def path_cost( path )
      path.inject( 0 ) { |sum,hex|
        sum + entrance_cost( hex )
      }
    end
    
    # The cost in movement points for this unit to travel to the given
    # destination.
    def travel_cost( dest )
      sp = shortest_path( dest )
      path_cost( sp )
    end
    
    # The shortest path (as an Array of Hexes) from the
    # Unit's current location to the given destination.
    #
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
    
    # Calculate all shortest paths from the Unit's current Hex to every other
    # Hex, as per Dijkstra's algorithm
    # ( http://en.wikipedia.org/wiki/Dijkstra's_algorithm ).
    # Most AIs will only need to make use of the shortest_path method instead.
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
    
    #-- --------------------------------------------------
    # Actions 
    #++

    # Sends an XML command to the server regarding this Unit. This is an
    # internal method that you should normally not need to call yourself.
    def send( xml )
      command = "<unit x='#{x}' y='#{y}'>#{xml}</unit>"
      response = @game.send command
      doc = Hpricot.XML( response )
      @finished = !! doc.at( 'finished' )
      if not @finished
        $stderr.puts "  #{self} NOT FINISHED:\n\t#{response}"
      end
      if not doc.at( 'ok' )
        error = doc.at 'error'
        if error
          message = "ERROR from server: #{error.inner_html}"
        else
          message = "RECEIVED:\n#{response}"
        end
        raise "Failed to execute:\n#{command}\n#{message}"
      end
      response
    end
    
    # Moves the given Unit to the given destination if it is reachable
    # in one turn, otherwise moves the Unit towards it using the optimal path.
    #
    # If a Unit or an Array of Units is passed as the :also_attack option,
    # those Units will be prioritized for attack after moving, with the Units
    # assumed to be given from highest priority (index 0) to lowest.
    #
    # If an Array of hexes is provided as the :exclusions option, the Unit will
    # not pass through any of the exclusion Hex es on its way to the destination.
    #
    # By default, moving onto a base with a capturing unit will attempt a capture.
    # Set the :no_capture option to true to prevent this.
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
      end
    
      if not command.empty?
        result = send( command )
        puts "Moved #{self} to #{new_hex}"
        @hex.unit = nil
        new_hex.unit = self
        @hex = new_hex
        if target
          #<attack target='[3,4]' damageReceived='2' damageInflicted='7' remainingQuantity='8' />
          process_attack result
          @game.last_attacked = target
        end
        
        # Success
        true
      end
    end
    alias move move_to
    
    # This is an internal method used to update the Unit attributes after a
    # command is sent to the weewar server.  You should not call this yourself.
    def process_attack( xml_text )
      xml = XmlSimple.xml_in( xml_text, { 'ForceArray' => false } )[ 'attack' ]
      if xml[ 'target' ] =~ /\[(\d+),(\d+)\]/
        x, y = $1, $2
        enemy = @game.map[ x, y ].unit
      end
      
      if enemy.nil?
        raise "Server says enemy attacked was at (#{x},#{y}), but we have no record of an enemy there."
      end
      
      damage_inflicted = xml[ 'damageInflicted' ].to_i
      enemy.hp -= damage_inflicted
      
      damage_received = xml[ 'damageReceived' ].to_i
      @hp = xml[ 'remainingQuantity' ].to_i
      
      puts "  #{self} (-#{damage_received}: #{@hp}) ATTACKED #{enemy} (-#{damage_inflicted}: #{enemy.hp})" 
    end
    
    # Commands this Unit to attack another Unit.
    # Provide either a Unit or a Hex to attack.
    def attack( unit )
      x = unit.x
      y = unit.y
      
      result = send "<attack x='#{x}' y='#{y}'/>"
      process_attack result
      @game.last_attacked = @game.map[ x, y ].unit
      true
    end
    
    # Commands the Unit to undergo repairs.
    def repair
      send "<repair/>"
      @hp += REPAIR_RATE[ @type ]
    end
  end
end