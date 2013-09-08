#!/usr/bin/ruby

require 'rubygems'
require './include/BruteZip.rb'
require 'optparse'

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

def distributeDictionaryFile(dictionary,nthreads)
  puts "STUB: Distributing dictionary file..."
  offsets = calculateDictionaryOffsets(dictionary,nthreads)
  # Create N files
  
  dict = File.open(dictionary,"r")
  nline = 0
  dict.each { |line|
    ndict = 0
    for offset in offsets
      ndict += 1
      if nline = offset[0]
        subdict = File.open(".#{dictionary}.#{ndict}","w")
      end
      if nline > offset[0] and nline < offset[1]
        subdict.puts line
      end
    end
    if nline = offset[1]
      subdict.close
    end
  }
  c = gets
end

# ===================
# ====== MAIN =======
# ===================

opts = getArguments

# Split in N threads when brute forcing
# Separate the dictionary in N sets and distribute to each thread
puts "Calculating dictionary chunks to distribute to the threads..."
distributeDictionaryFile(opts[:dictionary],opts[:nthreads]) #offsets)

# TODO: Create static method to check if is password protected
# if BruteZip.isPasswordProtected?(opts[:file])
  # Create N threads
  brutezip = BruteZip.new(opts[:file],opts[:dictionary],opts[:result])
  brutezip.forceZip
  
  if (brutezip.passwordFound)
    brutezip.extractAllData
    puts "[SUCESS]:".color(:green) + " The zip file was unziped with password '#{brutezip.zipPassword}' :-)"
    puts "[SUCESS]:".color(:green) + " Check for the unzipped content in folder '#{opts[:result]}'!"
    # TODO: Send stop signal to the other threads and store password
  else
    puts "[FAIL]:".color(:red) + " It was not possible to unzip the file :-("
  end
  # TODO: Join all the threads and check if password was found
# else
#  puts "This file does not seems to be password protected. Unziping it"
#  brutezip.extractAllData
#end
