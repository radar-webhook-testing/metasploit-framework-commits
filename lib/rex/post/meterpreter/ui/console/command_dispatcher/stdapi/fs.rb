require 'rex/post/meterpreter'

module Rex
module Post
module Meterpreter
module Ui

###
#
# Stdapi
# ------
#
# Standard API extension.
#
###
class Console::CommandDispatcher::Stdapi::Fs

	Klass = Console::CommandDispatcher::Stdapi::Fs

	include Console::CommandDispatcher

	#
	# Options for the download command
	#
	@@download_opts = Rex::Parser::Arguments.new(
		"-r" => [ false, "Download recursively." ])

	#
	# List of supported commands
	#
	def commands
		{
			"cd"       => "Change directory",
			"download" => "Download a file or directory",
			"getwd"    => "Print working directory",
			"ls"       => "List files",
			"mkdir"    => "Make directory",
			"pwd"      => "Print working directory",
			"rmdir"    => "Remove directory",
			"upload"   => "Upload a file or directory",
		}
	end

	#
	# Name for this dispatcher
	#
	def name
		"Stdapi: File system"
	end

	#
	# Change the working directory
	#
	def cmd_cd(*args)
		if (args.length == 0)
			print_line("Usage: cd directory")
			return true
		end

		client.fs.dir.chdir(args[0])

		return true
	end

	#
	# Downloads a file or directory from the remote machine to the local
	# machine.
	#
	def cmd_download(*args)
		if (args.length == 0)
			print(
				"Usage: download [options] src1 src2 src3 ... destination\n\n" +
				"Downloads remote files and directories to the local machine.\n" +
				@@download_opts.usage)
			return true
		end

		recursive = false
		src_items = []
		last      = nil
		dest      = nil

		@@download_opts.parse(args) { |opt, idx, val|
			case opt
				when "-r"
					recursive = true
				when nil
					if (last)
						src_items << last
					end

					last = val
			end
		}

		dest = last

		# If there is no destination, assume it's the same as the source.
		if (!dest)
			dest = src_items[0]
		end

		# Go through each source item and download them
		src_items.each { |src|
			stat = client.fs.file.stat(src)

			if (stat.directory?)
				client.fs.dir.download(dest, src, recursive) { |step, src, dst|
					print_status("#{step.ljust(11)}: #{src} -> #{dst}")
				}
			elsif (stat.file?)
				client.fs.file.download(dest, src) { |step, src, dst|
					print_status("#{step.ljust(11)}: #{src} -> #{dst}")
				}
			end
		}
		
		return true
	end

	#
	# Lists files
	#
	# TODO: make this more useful
	#
	def cmd_ls(*args)
		path = args[0] || client.fs.dir.getwd
		tbl  = Rex::Ui::Text::Table.new(
			'Header'  => "Listing: #{path}",
			'Columns' => 
				[
					'Name',
					'Type',
					'Size',
				])

		items = 0

		# Enumerate each item...
		client.fs.dir.entries(path).sort.each { |p|
			s = client.fs.file.stat(p)

			tbl << [ p, s.ftype, s.size ]

			items += 1
		}

		if (items > 0)
			print(tbl.to_s)
		else
			print_line("No entries exist in #{path}")
		end

		return true
	end

	#
	# Make one or more directory
	#
	def cmd_mkdir(*args)
		if (args.length == 0)
			print_line("Usage: mkdir dir1 dir2 dir3 ...")
			return true
		end

		args.each { |dir|
			print_line("Creating directory: #{dir}")

			client.fs.dir.mkdir(dir)
		}

		return true
	end

	#
	# Display the working directory
	#
	def cmd_pwd(*args)
		print_line(client.fs.dir.getwd)
	end

	alias cmd_getwd cmd_pwd

	#
	# Removes one or more directory if it's empty
	#
	def cmd_rmdir(*args)
		if (args.length == 0)
		 	print_line("Usage: rmdir dir1 dir2 dir3 ...")
			return true
		end

		args.each { |dir|
			print_line("Removing directory: #{dir}")
			client.fs.dir.rmdir(dir)
		}

		return true
	end

end

end
end
end
end
