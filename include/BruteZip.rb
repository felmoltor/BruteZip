#!/usr/bin/env ruby
# https://bitbucket.org/winebarrel/zip-ruby/wiki/Home

require 'rubygems'
require 'zipruby'
require 'filemagic'
require 'fileutils'

class BruteZip
  
  attr_reader :file, :dictionary, :resultDir, :forceMethod
  
  # =========================
  
  def initialize(zippedFile=nil,dictionaryFile=nil,resultDir="./unziped")
    @@ZIPMESSAGE = /Zip archive data.*/
    
    @file = nil
    @dictionary = nil
    @resultDir = nil 
    @passwordFound = false
    @zipPassord = "<NOT_FOUND>"
    
    fm = FileMagic.new()
    
    if zippedFile != nil and File.exists?(zippedFile)
      # TODO: Check if it is a zip file
      @file = zippedFile
      if (fm.file(@file) =~ @@ZIPMESSAGE).nil?
        raise TypeError.new("File provided is not a zip file")
      end
    end
    
    if dictionaryFile != nil and File.exists?(dictionaryFile)
      @dictionary = dictionaryFile
    else
      raise ArgumentError.new("Dictionary file does not exist")
    end
    
    if resultDir != nil
      # TODO: Substract the lasts slashes '/' if specified
      if !File.exists?(resultDir) or !File.directory?(resultDir)
        FileUtils.mkdir_p(resultDir)
      end
    else
    end    
  end
  
  # =========================
  
  def printProgress
    # TODO: Print out the word being used to unzip and percentage
  end
  
  # =========================
  
  def extractAllData(filename)
    
    Zip::Archive.open(filename) do |ar|
      ar.each do |zf|
        if zf.directory?
          FileUtils.mkdir_p("#{@resultDir}#{zf.name}")
        else
          dirname = File.dirname("#{@resultDir}#{zf.name}")
          FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
    
          open(zf.name, 'wb') do |f|
            f << zf.read
          end
        end
      end
    end
  end
  
  # =========================
  
=begin
irb(main):072:0> extractAllData("password.txt.zip")
Zip::Error: Read file failed: File encrypted
  from (irb):63:in `read'
  from (irb):63:in `block (3 levels) in extractAllData'
  from (irb):62:in `open'
  from (irb):62:in `block (2 levels) in extractAllData'
  from (irb):55:in `each'
  from (irb):55:in `block in extractAllData'
  from (irb):54:in `open'
  from (irb):54:in `extractAllData'
  from (irb):72
  from /usr/bin/irb:12:in `<main>'
irb(main):073:0> extractAllData("nopassword.txt.zip")
=> nil
=end
  
  def forceZip
    password = "<NOT_FOUND>"
    
    # First, trying to unzip without a password
    if extractAllData().nil?
      # No password needed and it was correctly extracted
    else
      # If failed, then is password protected: Force
      dfile = File.open(@dictionary)
      dfile.each { |password|
        print "Trying to unzip with '#{password}'"
        sucess = Zip::Archive.decrypt(@file, password) # return true if decrypted
        if (success)
          @passwordFound = true
          @zipPassord = password
          break
        end
      }
      dfile.close
    end
    
    
    return password
  end
  
    
end

