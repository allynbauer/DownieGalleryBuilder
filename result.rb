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