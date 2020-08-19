# !/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'erb'
require 'json'
require 'date'

class GalleryRenderer
	include ERB::Util

	VERSION = '1.0.0'

	attr_reader :options
	
	def initialize(arguments = "")
		@arguments = arguments
		@options = OpenStruct.new
		@template = File.open('gallery.template').read
	end
	
	def run
		if parsed_options?
			execute
		else
			output_usage
		end
	end


	protected
	
	def parsed_options?
		opts = OptionParser.new
		opts.on('-v', '--version') { output_version; exit }
		opts.on('-h', '--help')  { output_help }
		opts.on('-i', '--input FILE') { |file| @options.input = file }
		opts.on('-o', '--output FILE') { |file| @options.output = file }
		opts.on('-t', '--title TITLE') { |title| @options.title = title }
		
		opts.parse!(@arguments) rescue return false
		true
	end
	
	def output_help
		output_version
		# puts RDoc::usage
	end
	
	def output_usage
		# RDoc::usage('usage')
	end
	
	def output_version
		puts "#{File.basename(__FILE__)} version #{VERSION}"
	end
	

	private
	
	def render
		ERB.new(@template).result(binding)
	end

	def load
		candidates = {}

		Dir[File.join(@options.input, '**', "*.*")].each do |path|
			element = candidates[DownieResult.name(path)]
			if element.nil?
				element = DownieResult.new(path, @options.input)
				candidates[element.name] = element
			else
				element.append(path)
			end
		end

		result = candidates.values
		result = result.select(&:has_result)
		result.each(&:populate_json)
		result.sort_by(&:name)
	end

	def execute
		if @options.input.nil? || @options.output.nil?
			puts "Unknown/invalid arguments."
			output_usage
		end

		@results = load
		File.open(@options.output, 'w') do |f|
			f.write(render)
		end
	end
end

class DownieResult
	attr_reader :name
	attr_reader :location
	attr_accessor :image, :json, :video, :subtitle # Downie 4 files
	attr_accessor :prepareDate, :authors, :bitrate # JSON properties

	def self.name(path)
		File.basename(path, '.*')
	end

	def self.location(path, input)
		File.dirname(path.sub(input, ""))
	end

	def initialize(path, input)
		@name = DownieResult.name(path)
		@location = DownieResult.location(path, input)
		append(path)
	end

	def has_result
		 !@image.nil? && !@json.nil? && !@video.nil?
	end

	def append(path)
		ext = File.extname(path)
		if ext == '.jpg' or ext == '.png' or ext == '.jpeg'
			self.image = path
		elsif ext == '.json'
			self.json = path
		elsif ext == '.srt'
			self.subtitle = path
		elsif ext == '.mp4' or ext == '.m4v' or ext == '.mkv'
			self.video = path
		end
	end

	def populate_json
		return if self.json.nil?
		jsonFile = File.open(self.json, 'r')
		values = JSON.parse(jsonFile.read)
		self.prepareDate = DateTime.iso8601(values['prepareDate'])
		self.authors = values['authors'] || []
		self.bitrate = values['bitrate'] || ""
	end

	def to_s
		self.name
	end
end

if __FILE__ == $0
	x = GalleryRenderer.new(ARGV)
	x.run
end
