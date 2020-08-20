# !/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'erb'
require 'json'
require 'date'
require_relative 'result'

class GalleryRenderer
	include ERB::Util

	VERSION = '1.0.0'

	attr_reader :options
	
	def initialize(arguments = "")
		@arguments = arguments
		@options = OpenStruct.new
		template = File.join(__dir__, 'gallery.template')
		@template = File.open(template).read
	end
	
	def run
		if parsed_options?
			configure_environment
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

	def each_gallery_item
		Dir[File.join(@options.input, '**', "*.*")].each do |path|
			key = DownieResult.name(path)
			yield path, key
		end
	end

	def load
		candidates = {}
		each_gallery_item do |path, key|
			element = candidates[key]
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

	def configure_environment
		@source = __dir__
		def append_includes(*files)
			files.collect { |file| File.join(@source, 'includes', file) }
		end
		@stylesheets = append_includes('DataTables/datatables.min.css')
		@scripts = append_includes('DataTables/datatables.min.js')
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

if __FILE__ == $0
	x = GalleryRenderer.new(ARGV)
	x.run
end
