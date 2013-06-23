#!/usr/bin/ruby1.8

require 'rubygems'
require './include/BruteZip.rb'
require 'optparse'

def getArguments
  # This hash will hold all of the options
  # parsed from the command-line by
  # OptionParser.
  options = {:file => nil, :dictionary => nil, :result => "./unziped"}
  
  optparse = OptionParser.new do |opts|
    opts.on( '-f', '--file FILE', 'Zipped file protected with the password to guess' ) do |file|
      options[:file] = file
    end
    opts.on( '-d', '--dictionary DICTIONARY', 'Dictionary file to use against the zipped file.' ) do |dict|
      options[:dictionary] = dict
    end
    opts.on( '-r', '--resultdir [RESULTDIR]', 'Directory where the result of unzipping the file will be stored' ) do |result|
      options[:result] = result
    end
=begin
    opts.on( '-s', '--set [BRUTE_SET]', [:NUMERIC,:ALPHA,:APHANUMERIC,:ALPHASPEC,:ALPHANUMSPEC], 'Use brute force method instead of dictionary method.' ) do
      puts opts
      exit
    end
    opts.on( '-c', '--case [CASE]', [:UPPER,:LOW,:MIXED], 'In case of brute force method, set the case preferences when using chars' ) do
      puts opts
      exit
    end
=end
    opts.on( '-h', '--help', 'Display this screen' ) do
      print opts
      exit
    end
  end
  
  # Parse the command-line. Remember there are two forms
  # of the parse method. The 'parse' method simply parses
  # ARGV, while the 'parse!' method parses ARGV and removes
  # any options found there, as well as any parameters for
  # the options. What's left is the list of files to resize.
  optparse.parse!(ARGV)
  options
end

# ===================

opts = getArguments
print opts
