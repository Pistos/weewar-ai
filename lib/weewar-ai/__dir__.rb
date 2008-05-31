# From Ramaze ( http://ramaze.net )
#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com

# Extensions for Kernel

module Kernel
  unless defined?__DIR__
  
    # This is similar to +__FILE__+ and +__LINE__+, and returns a String
    # representing the directory of the current file is.
    # Unlike +__FILE__+ the path returned is absolute.
    #
    # This method is convenience for the
    #  File.expand_path(File.dirname(__FILE__))
    # idiom.
    #
    
    def __DIR__()
      filename = caller[0][/^(.*):/, 1]
      File.expand_path(File.dirname(filename))
    end
  end
end
