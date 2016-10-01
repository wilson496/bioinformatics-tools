#!/usr/bin/ruby
require 'fileutils'
include FileUtils
require 'pathname'
require 'json'
require "net/http"


=begin

VCFSetup is written and maintained by Cameron Wilson. 

August 12th, 2016


This program will take a VCF file and configure it for JBrowse


NOTE: You must have appropriate file permissions (e.g. creating files) in your current working directory for this to work


TODO: Check to see if required packages are installed.


TODO: Improve feedback for missing packages

=end


#Check to see if there is at least one argument supplied, or else the program will exit
if ARGV.empty?
  puts "Usage: #{__FILE__} <vcf>"
  puts "At least one argument is required"
  exit(2)


#Check to see if user has asked for help manual
elsif ARGV[1] == "--help" or ARGV[1] == "-h" 

   help = "Usage: #{__FILE__} <vcf>"
   puts help
   exit(2)


else

	puts "VCF FILE (ARGV[0]) IS #{ARGV[0]}"

	vcfFile = ARGV[0]        

	#Compress the vcf file
	puts "Compressing VCF"
	system "bgzip #{vcfFile}"


	compressedVCF = "#{vcfFile}.gz"
	compressIndexVCF = "#{vcfFile}.gz.tbi"

	#index vcf with tabix
	puts "Indexing with tabix"
	system "tabix -p vcf #{compressedVCF}"

	#Enter newJsonFields into an array, then write them to file	
	
        newJsonFields = Hash.new
        newJsonFields["label"] = "#{vcfFile}"
        newJsonFields["key"] = "#{vcfFile}"
        newJsonFields["storeClass"] = "JBrowse/Store/SeqFeature/VCFTabix"
	
	
	condition = true
       	while(condition) 
		
		
     		urlTemplate = "#{Dir.pwd}/#{compressedVCF}"
				
	 
               	 #Check to see if the urlTemplate field exists as a file or a symlink
            	if !File.exist?(urlTemplate)
                       	puts "INVALID PATH! File does not exist in the given path, or is a directory"
                       	exit(1)
             	
		
		puts "URL: #{urlTemplate}"
			
		
		else

			if !File.symlink?("/var/www/JBrowse*/dataFiles/#{vcfFile}.gz") || !File.symlink?("/var/www/JBrowse*/dataFiles/#{vcfFile}.gz.tbi")
		
				#Create symlinks for the compressed vcf and the compressed vcf index
				 system "ln -s #{urlTemplate} /var/www/JBrowse/dataFiles/#{compressedVCF}"
				 system "ln -s #{urlTemplate}.tbi /var/www/JBrowse/dataFiles/#{compressIndexVCF}"

			end
	
		newJsonFields["urlTemplate"] = "../dataFiles/#{compressedVCF}"
                condition = false
		
		end
                 
        end

        #Sets type field
	newJsonFields["type"] = "JBrowse/View/Track/HTMLVariants"


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
