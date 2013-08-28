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
    opts.on( '-t', '--threads [NTHREADS]', 'Number of threads to bruteforce the password' ) do |nthreads|
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

opts = getArguments

brutezip = BruteZip.new(opts[:file],opts[:dictionary],opts[:result])

if brutezip.isPasswordProtected?
  brutezip.forceZip
  if (brutezip.passwordFound)
    brutezip.extractAllData
    puts "[SUCESS]:".color(:green) + " The zip file was unziped with password '#{brutezip.zipPassword}' :-)"
    puts "[SUCESS]:".color(:green) + " Check for the unzipped content in folder #{opts[:result]}!"
  else
    puts "[FAIL]:".color(:red) + " It was not possible to unzip the file :-("
  end
else
  puts "This file does not seems to be password protected. Unziping it"
  brutezip.extractAllData
end


