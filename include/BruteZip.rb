#!/usr/bin/env ruby
# https://bitbucket.org/winebarrel/zip-ruby/wiki/Home

require 'rubygems'
require 'zipruby'
# require 'filemagic'

class BruteZip
  
  attr_reader :file, :dictionary, :resultDir, :forceMethod
  
  def initialize(zippedFile=nil,dictionaryFile=nil,resultDir="./unziped")
    @file = nil
    @dictionary = nil
    @resultDir = nil 
    
    if zippedFile != nil and File.exists?(zippedFile)
      # TODO: Check if it is a zip file
      @file = zippedFile
    end
    
    if dictionaryFile != nil and File.exists?(dictionaryFile)
      @forceMethod = "Dictionary" 
      @dictionary = dictionaryFile
    else
      @forceMethod = "Brute Force" 
    end
    
    if resultDir != nil and File.exists?(resultDir) and File.directory?(resultDir)
      @resultDir = resultDir
    end    
  end
  
  def forceZip
    password = "<NOT_FOUND>"
    if (@forceMethod != "Dictionary")
      # Ataque por diccionario
      f = File.open(@dictionary)
      f.each { |password|
        print "Trying to unzip with '#{password}'"
        sucess = Zip::Archive.decrypt(@file, password) # return true if decrypted
        if (success)
          @passwordFound = true
          @zipPassord = password
          break
        end
      }
      f.close
    elsif (@forceMethod != "Brute Force")
      # Ataque por fuerza bruta
      
    else
      # Algo raro ha pasado
      $stderr.print "Incorrect force method!"  
    end
    return password
  end
  
    
end

