#!/usr/bin/ruby
# https://bitbucket.org/winebarrel/zip-ruby/wiki/Home
# Zip Specification: http://www.pkware.com/documents/APPNOTE/APPNOTE-6.3.0.TXT

require 'rubygems'
require 'zipruby'
require 'filemagic'
require 'fileutils'
require 'rainbow'

class BruteZip
  
  attr_reader :file, :dictionary, :dictionarysize, :processingline, :resultDir, :forceMethod, :passwordFound, :zipPassword
  
  # =========================
  
  def initialize(zippedFile=nil,dictionaryFile=nil,resultDir=nil)
    @@ZIPMESSAGE = /Zip archive data.*/
    
    @file = nil
    @dictionary = nil
    @dictionarysize = 0
    @processingline = 0
    @resultDir = nil 
    @passwordFound = false
    @zipPassword = "<NOT_FOUND>"
    
    fm = FileMagic.new()
    
    if zippedFile != nil and File.exists?(zippedFile)
      @file = zippedFile
      # Check if is realy a zip file
      if (fm.file(@file) =~ @@ZIPMESSAGE).nil?
        raise TypeError.new("File provided is not a zip file")
      end
    end
    
    if dictionaryFile != nil and File.exists?(dictionaryFile)
      @dictionary = dictionaryFile
      # Read dictionary size
      @dictionarysize = %x{wc -l '#{@dictionary}'}.split.first.to_i # Will only work in Unix like SO
    else
      raise ArgumentError.new("Dictionary file does not exist")
    end
    
    if resultDir != nil
      # TODO: Substract the lasts slashes '/' if specified
      @resultDir = resultDir
      if !File.exists?(resultDir) or !File.directory?(resultDir)
        FileUtils.mkdir_p(resultDir)
      end
    else
    end    
  end
  
  # =========================
  
  def getProgress
    # TODO: Print out the word being used to unzip and percentage
  end
  
  # =========================
  
  def extractAllData
    puts "Trying to unzip '#{@file}' in folder '#{@resultDir}'..."
    Zip::Archive.open(@file) do |ar|
      ar.each do |zf|
        if zf.directory?
          FileUtils.mkdir_p("#{@resultDir}/#{zf.name}")
        else
          dirname = "#{@resultDir}/#{File.dirname(zf.name)}"
          FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
    
          open("#{@resultDir}/#{zf.name}", 'wb') do |f|
            f << zf.read
          end
        end
      end
    end
  end
  
  # =========================
  
  # TODO: This should raise a exception to dettect if is password protected (Zip::Error: Read file failed: File encrypted)
  # but it's failling now, unzip even without password, so think on other 
  # possible way to check if is password protected.
  # It seems this method is failing when the zip file contains folders. With a zip file with only one file it raises
  # an exception and the detection of the password works fine ¿?¿?:doc:
  # Maybe we can use CRC checking as 7z does. Thus, we need to improve zipruby library
  
  def isPasswordProtected?
    password_protected = true
    
=begin
    puts "Checking if '#{@file}' is password protected..."
    
    Zip::Archive.open(@file) do |ar|
      ar.each do |zf|
        if zf.directory?
          puts "#{zf.name} is a directory"
          FileUtils.mkdir_p("#{@resultDir}/#{zf.name}")
        else
          dirname = "#{@resultDir}/#{File.dirname(zf.name)}"
          puts "#{zf.name} is a file"
          FileUtils.mkdir_p(dirname) unless File.exist?(dirname)  
          
          open("#{@resultDir}/#{zf.name}", 'wb') do |f|
            begin
              f << zf.read
            rescue => e
              puts "Exception: #{e.message}"
              if e.message == "Read file failed: File encrypted"
                password_protected = true
              else
                puts "Unknown error ocurred when uncompressing the file #{zf.name}."
              end
              break
            end # begin - rescue
          end # open
        end # if zf.directory? - else 
      end # ar.each
    end # Zip::Archive.open
    
    # Detele the created folders
    FileUtils.remove_dir(@resultDir,force=true) 
=end
    return password_protected    
  end
  
  # =========================
  
  def forceZip
    password = "<NOT_FOUND>"
    sucess = false
    
    # First, trying to unzip without a password
    if isPasswordProtected?
      # If failed, then is password protected: Force
      # puts "Yep. This file is password protected, using dictionary attack..."
      dfile = File.open(@dictionary)
      @processingline = 0
      dfile.each { |password|
        password.chomp!
        @processingline += 1
        print "Trying to decrypt with '#{password}' "
        begin
          if (Zip::Archive.decrypt(@file, password))
            puts "\t[SUCCESS]".color(:green)
            @passwordFound = true
            @zipPassword = password
            break
          else
            puts "\t[FAILED]".color(:red)
          end
        rescue => e_decrypt
          # puts e_decrypt.message # "Decrypt archive failed - test/password_dir.zip: Wrong password"
          puts "\t[FAILED]".color(:red)
        end
      }
      dfile.close
    else
      puts "This file was not password protected!"
    end

    return password
  end
  
    
end

