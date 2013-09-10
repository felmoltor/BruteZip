#!/usr/bin/ruby

require 'rubygems'
require './include/BruteZip.rb'
require 'optparse'
require 'pp'
require 'curses'

def getArguments
  # This hash will hold all of the options
  # parsed from the command-line by
  # OptionParser.
  options = {:file => nil, :dictionary => nil, :result => "unziped", :nthreads => 1}
  
  optparse = OptionParser.new do |opts|
    opts.on( '-f', '--file FILE', 'Zipped file protected with the password to guess (Mandatory)') do |file|
      options[:file] = file
    end
    opts.on( '-d', '--dictionary DICTIONARY', 'Dictionary file to use against the zipped file (Mandatory)' ) do |dict|
      options[:dictionary] = dict
    end
    opts.on( '-r', '--resultdir [RESULTDIR]', 'Directory where the result of unzipping the file will be stored' ) do |result|
      options[:result] = result
    end
    opts.on( '-t', '--threads [NTHREADS]', Integer, 'Number of threads to bruteforce the password' ) do |nthreads|
      options[:nthreads] = nthreads
    end
    opts.on( '-h', '--help', 'Display this screen' ) do
      print opts
      exit
    end
  end
  
  optparse.parse!(ARGV)
  
  if options[:file].nil? or options[:dictionary].nil?
    $stderr.puts "Arguments provided are not enough. Check mandatory fields"
    puts optparse
    exit(1)
  end
  
  options
end

# ===================

def printBanner
  banner = %q{
  ____             _       _______              __   ___  
 |  _ \           | |     |___  (_)            /_ | / _ \ 
 | |_) |_ __ _   _| |_ ___   / / _ _ __   __   _| || | | |
 |  _ <| '__| | | | __/ _ \ / / | | '_ \  \ \ / / || | | |
 | |_) | |  | |_| | ||  __// /__| | |_) |  \ V /| || |_| |
 |____/|_|   \__,_|\__\___/_____|_| .__/    \_/ |_(_)___/ 
                                  | |                     
                                  |_|                     

  Author: Felipe Molina (https://twitter.com/felmoltor)
  Date: 09/2013
  
  }
  puts banner.color(:blue)
end

# ===================

def captureKeystrokesCommands
  # TODO: Create a thread that will capture keystrokes to show completed percentage

  Curses.noecho # do not show typed keys
  Curses.init_screen
  Curses.stdscr.keypad(true) # enable arrow keys (required for pageup/down)
  
  loop do
    case Curses.getch
    when Curses::Key::ENTER 
      Curses.setpos(0,0)
      Curses.addstr("Showing percentage of process")
    when Curses::Key::EXIT
      Curses.setpos(0,0)
      Curses.addstr("Exiting application. Please wait...")
    end
  end
end

# ===================

def calculateDictionaryOffsets(dictionary,nparts)
  dictionarysize = %x{wc -l '#{dictionary}'}.split.first.to_i
  last_offset = 0
  dic_offsets = [[0,dictionarysize]]
  
  if (nparts > 1)
    dic_offsets = []
    # Calclulate offsets for each thread
    chunk_size = dictionarysize/nparts
    last_chunk_size = dictionarysize%nparts
    
    nparts.times {|part_n|
      # If this is not the last chunk
      if part_n < (nparts-1)
        dic_offsets[part_n] = [last_offset,last_offset+chunk_size]
        last_offset = last_offset + chunk_size
      else
        dic_offsets[part_n] = [last_offset,last_offset+chunk_size+last_chunk_size]
        last_offset = last_offset+chunk_size+last_chunk_size
      end
    }
  end # if (nparts > 1)
  return dic_offsets
end

# ===================

# TODO: Use seek method instead of counting lines of the dictionary
def distributeDictionaryFile(dictionary,nthreads)
  offsets = calculateDictionaryOffsets(dictionary,nthreads)
  subdictionaries = []
  subdict = nil
  ndict = 0
  
  if nthreads > 1
    # Create N files with the subdictionaries
    for offset in offsets
      dict = File.open(dictionary,"r")
      nline = 0
      ndict += 1
      
      dict.each { |line|
        if nline == offset[0]
          subdict = File.new("#{File.dirname(dictionary)}#{File::SEPARATOR}.#{File.basename(dictionary)}.#{ndict}","w")
          subdictionaries << subdict.path
        end
        
        if nline > offset[0] and nline < offset[1]
          subdict.puts line.chomp
        end
        
        # If is the last line of the subdictionary
        if nline == offset[1] - 1
          subdict.close
          break
        end
        nline += 1
      }
      dict.close
    end # Del for offset in offsets
  else
    subdictionaries << dictionary
  end
  
  return subdictionaries
end

# ===================

def freeSubdictionaryFiles(subdicts)
  for subdict in subdicts
    File.delete(subdict)
  end
end

# ===================
# ====== MAIN =======
# ===================

is_password_found = false
password_found = "<NOT_FOUND>"

opts = getArguments
printBanner

# TODO: curses thread is blocking the rest of the program
# captureKeystrokesCommands

# Split in N threads when brute forcing
# Separate the dictionary in N sets and distribute to each thread
puts "Splitting the dicctionary to the threads..."
# TODO: Optimice this dictionary distribution. Takes too much time to split the dictionary
#       Instead of creating N files, make the threads read the position of the original dictionary file
subdicts = distributeDictionaryFile(opts[:dictionary],opts[:nthreads])

# TODO: Create static method to check if is password protected
# if BruteZip.isPasswordProtected?(opts[:file])
# Create N threads
puts "Bruteforcing the password with #{opts[:nthreads]} threads. Please wait..."
threads = []
opts[:nthreads].times { |t|
  threads << Thread.new(t) do
    
    Thread.current[:success] = is_password_found
    Thread.current[:password] = password_found
      
    brutezip = BruteZip.new(opts[:file],subdicts[t],opts[:result])
    brutezip.forceZip
    
    if (brutezip.passwordFound)
      # TODO: Send stop signal to the other threads and store password and save time
      brutezip.extractAllData
      Thread.current[:success] = true
      Thread.current[:password] = brutezip.zipPassword
    end
  end
  threads[t].join
  
  # Check if any thread found the password
  if threads[t][:success]
    is_password_found = true
    password_found = threads[t][:password]
  end
}

puts "******************************"
if is_password_found
  puts "* " + "[SUCESS]: ".color(:green) + " The zip file was unziped with password '#{password_found}' :-)"
else
  puts "* " + "[FAIL]: ".color(:red) + " It was not possible to unzip the file :-("
end  
puts "******************************"

freeSubdictionaryFiles(subdicts)
# else
#  puts "This file does not seems to be password protected. Unziping it"
#  brutezip.extractAllData
#end
