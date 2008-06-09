#!/usr/bin/env ruby

require 'weewar-ai'
#$debug = true

# A simple, working example of using the WeewarAI library.
# This bot's strategy is simply to build infantry and move them onto any
# bases it does not own.  It will attack any enemies it meets along the way.

class AIBasic < WeewarAI::AI
  
  def initialize
    super(
      :server => 'test.weewar.com',
      :username => 'aiBasic',  # change this to your bot's username
      :api_key => 'GMmTBxE2ztNbdABAW5vgVZVhH'  # change this to your bot's API key
    )
  end
  
  def run_once
    one_accepted = accept_all_invitations
    if one_accepted
      puts "Accepted some invitations."
      refresh
    end
    
    @needy_games.each do |g|
      take_turn g
    end
  end
  
  def take_turn( game )
    puts
    puts "*" * 80
    puts "Taking turn for game #{game.id}"
    i = me = my = game.my_faction

    # Find a place to go, things to shoot
    destination = game.enemy_bases.first
    enemies = game.enemy_units
    
    # Move units
    my.units.find_all { |u| not u.finished? }.each do |unit|
      unit.move_to(
        destination,
        :also_attack => enemies
      )
    end
    
    # Build
    game.my_bases.each do |base|
      next if base.occupied?
      
      if i.can_afford?( :linf )
        base.build :linf
      end
    end
    
    puts "Ending turn for game #{game.id}"
    game.finish_turn
  end
  
end

begin
  bot = AIBasic.new
  bot.run_once
rescue Exception => e
  $stderr.puts "#{e.class}: #{e.message}"
  $stderr.puts e.backtrace.join( "\n\t" )
end
