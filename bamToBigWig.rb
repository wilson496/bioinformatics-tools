#!/usr/bin/ruby
require 'fileutils'
include FileUtils
#require 'ptools'
require 'pathname'
require 'json'
require "net/http"


=begin

bamToBigWig is written and maintained by Cameron Wilson. 

July 27th, 2016



This program will take a BAM file and convert it to .bigwig format


NOTE: You must have appropriate file permissions (e.g. creating files) in your current working directory for this to work


TODO: Check to see if required packages are installed.

TODO: Parallel support

TODO: Improve feedback for missing packages

TODO: Add support for optional features for JSON configuration track

TODO: Sam support (Convert sam to bam)

?TODO: Add support for different configuration options for samtools when converting files

e.g. specifying -n will produce samtools -n input output, which sorts by read name 


TODO: Separate bam to bigwig conversation from bigwig data entry


=end





#Check to see if there is at least one argument supplied, or else the program will exit
if ARGV.empty?
  puts "Usage: #{__FILE__} <name>"
  puts "At least one argument is required"
  exit(2)


#Check to see if user has asked for help manual
elsif ARGV[1] == "--help" or ARGV[1] == "-h" 

   help = "Format: ./bamToBigWig.rb <bamFile> chrom.sizes type(Density, XYPlot)"
   puts help
   exit(2)

elsif ARGV.length < 3

	puts "Incorrect number of arguments"
	puts "Length should be 3, but is #{ARGV.length}"
	exit(2)

else

	puts "BAM FILE (ARGV[0]) IS #{ARGV[0]}"
	puts "ARGV[1] is #{ARGV[1]}"
	puts "ARGV[2] is #{ARGV[2]}"	


	bamFile = ARGV[0]
        chromSizes = ARGV[1]
	
#	system "grep '@HD' #{ARGV[0]} | grep unsorted"
	
	     
	
	#Sort the bam file
	puts "Sorting bam file"
	
	
	system "samtools sort #{bamFile} #{bamFile}" or raise "Error sorting bam file"

	
	#Create bedgraph using chrom.sizes file
	puts "Creating bedgraph file"


	#Use regex to chomp out everything after ".bam" to avoid redundancy	
  	bgFile = "#{bamFile.chomp(bamFile[/()*.bam\s*([^\n\r]*)/])}.bedgraph"	


	system "genomeCoverageBed -bg -ibam #{bamFile}.bam -g #{chromSizes} > #{bgFile}" or raise "Error with genomeCoverageBed"
        
        puts "Sorting bedgraph"	
	system "./bedSort #{bgFile} #{bgFile}"

	#Create bigwig file string
	bigwig = "#{bgFile.chomp(bgFile[/()*.bedgraph\s*([^\n\r]*)/])}.bigwig"
	
	puts "Creating bigwig"
	system "./bedGraphToBigWig  #{bgFile} #{chromSizes} #{bigwig}"

	#Enter newJsonFields into an array, then write them to file

	#this will allow the user to skip CERTAIN newJsonFields, but not all
	
	#NOTE: set conditions for valid track configuration (e.g. must have a label, but style is optional).	

	
	
        newJsonFields = Hash.new
        newJsonFields["label"] = "#{bigwig}, #{ARGV[2]}"
        newJsonFields["key"] = "#{bigwig}, #{ARGV[2]}"
        newJsonFields["storeClass"] = "JBrowse/Store/SeqFeature/BigWig"
	
	
		condition = true
        	while(condition) 

       			 urlTemplate = "#{Dir.pwd}/#{bigwig}"
			# puts urlTemplate
               		 #Check to see if the urlTemplate field exists as a file or a symlink
               		 if !(File.exist?(urlTemplate) || File.symlink?(urlTemplate)) and !File.directory?(urlTemplate)

                        	puts "INVALID PATH! File or symlink to file does not exist in the given path, or is a directory"
                        	exit(1)
                	 else
				
				if !File.symlink?("/var/www/JBrowse/dataFiles/#{bigwig}")
				 system "ln -s #{urlTemplate} /var/www/JBrowse/dataFiles/#{bigwig}"
				end

				 newJsonFields["urlTemplate"] = "../dataFiles/#{bigwig}"
                        	 condition = false
                	 end
        	end

        	#compares the type argument to whether it is Density or XYPlot
		if ARGV[2].casecmp("Density") == 0
		   # puts "Going with Density since ARGV[2] is #{ARGV[2]}"
                    newJsonFields["type"] = "JBrowse/View/Track/Wiggle/Density"  
  		elsif ARGV[2].casecmp("XYPlot") == 0
                    newJsonFields["type"] = "JBrowse/View/Track/Wiggle/XYPlot"
        	else
		    puts "Invalid type. Please change the trackList.json file to JBrowse/View/Track/Wiggle/Density or JBrowse/View/Track/Wiggle/XYPlot"
		end


        	#Reads trackList.json and converts it to a json hash    

        	file = File.read('/var/www/JBrowse/data/trackList.json')

        	json_hash = JSON.parse(file)

	        #Appends the newJsonFields hash to the trackList.json hash

	        json_hash["tracks"] << newJsonFields

        	#Writes the changes to trackList.json

	        File.open("/var/www/JBrowse/data/trackList.json", 'w+') do |f|

                f.write(JSON.pretty_generate(json_hash))

        	end
		
	
        
end

