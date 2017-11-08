require 'find'
require 'iiif_s3'

Jekyll::Hooks.register :site, :after_reset do |site|

	FileUtils::mkdir_p 'tiles'
	hosturl = ""

	imagedata = []

	id_counter = 0
	imagedirs = Dir["./_iiif/*"].sort!
	imagedirs.each do |imagedir|
		id_counter = id_counter + 1
		collname = File.basename(imagedir, ".*")
    puts "Looking into _iiif/" + collname

		# collection of images
		imagefiles = Dir[imagedir + "/*"].sort!
		counter = 1
		imagefiles.each do |imagefile|
			basename = File.basename(imagefile, ".*")

			# TODO populate values for :label etc. from _config.yml
			opts = {}
			thiscoll = nil
			site.collections.each do |coll|
				thiscoll = coll if coll[0] == collname && coll[1].metadata["iiif"]
			end
			if thiscoll == nil
        puts "IIIF:", "Collection '" + collname + "' not found in _config.yml, or '" + collname + "' has 'iiif' set to false."
        break
				# Jekyll.logger.error("IIIF:", "Collection " + collname + " not found in _config.yml")
			else
				fields = thiscoll[1].metadata["fields"]
				if thiscoll[1].metadata["paged"]
					# opts[:id] = collname
					# opts[:page_number] = counter.to_s.rjust(4, "0")
					# opts[:is_document] = false
					# opts[:is_primary] = counter == 1
					# opts[:section] = counter.to_s
					# opts[:section_label] = "p. " + counter.to_s
          #
					# allowablefields = site.config["iiif_allowablefields"]
					# fields.each do |field|
					# 	if allowablefields.include? field[0]
					# 		if field[0] == 'logo'
					# 			# convert logo to absolute url if necessary
					# 			logo = field[1]
					# 			uri = URI(logo)
					# 			if !uri.host
					# 				logo = URI.join(hosturl, site.config["baseurl"] + "/", logo)
					# 			end
					# 			opts['logo'] = logo
					# 		else
					# 			opts[field[0]] = field[1]
					# 		end
					# 	else
					# 		Jekyll.logger.error("IIIF:", "Collection metadata for " + collname + " includes bad field '" + field[0] + "'")
					# 	end
					# end

					# opts[:path] = imagefile
				else
					opts[:id] = basename
					opts[:is_document] = true
					opts[:path] = imagefile
					opts[:label] = site.config["title"] + " - " + collname + " - " + basename
				end

				i = IiifS3::ImageRecord.new(opts)
				counter = counter + 1
				imagedata.push(i)
			end
		end
	end
	builder = IiifS3::Builder.new({
		:base_url => hosturl + site.baseurl + "/tiles",
		:output_dir => "./tiles"
	})
	builder.load(imagedata)
	builder.process_data()

end