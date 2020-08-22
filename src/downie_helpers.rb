class DownieHelpers
	def version
		get_info('CFBundleShortVersionString')
	end

	def is_saving_metadata
		get_defaults("XUWriteMetadataIntoExternalFile")
	end

	def is_saving_thumbnails
		get_defaults("XUSaveThumbnails")
	end

	def download_folder_path
		get_defaults("XUDownloadFolderURLPath")
	end

	def bundle_id
		get_info("CFBundleIdentifier")
	end

	#private

	def get_application_path
		result = `mdfind -onlyin /Applications -onlyin ~/Applications -name "Downie 4"`.split("\n").first
		return nil if result.nil? or result.empty?
		result.sub(" ", "\\ ")
	end

	def get_info(key)
		path = get_application_path
		if path.nil?
			raise "Cannot locate Downie 4.app"
		end
		`defaults read #{path}/Contents/Info.plist #{key}`.strip
	end

	def get_defaults(key)
		`defaults read #{bundle_id} #{key}`.strip
	end
end
