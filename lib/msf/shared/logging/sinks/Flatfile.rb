module Msf
module Logging
module Sinks

###
#
# Flatfile
# --------
#
# This class implements the LogSink interface and backs it against a 
# file on disk.
#
###
class Flatfile

	include Msf::Logging::LogSink

	def initialize(file)
		self.fd = File.new(file, "a")
	end

	def cleanup
		fd.close
	end

	def log(sev, src, level, msg, from)
		if (sev == LOG_RAW)
			fd.write(msg)
		else
			fd.write("[#{get_current_timestamp}] (src=#{src},sev=#{sev},level=#{level}): #{msg}\n")
		end
	end

protected

	attr_accessor :fd

end

end; end; end
