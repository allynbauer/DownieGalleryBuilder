#!/usr/bin/env ruby

require_relative 'src/galleryrenderer'

if __FILE__ == $0
	x = GalleryRenderer.new(ARGV)
	x.run
end
