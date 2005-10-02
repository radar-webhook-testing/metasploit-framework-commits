module Rex
module Proto
module SMB
class SimpleClient

require 'rex/text'
require 'rex/struct2'
require 'rex/proto/smb/constants'
require 'rex/proto/smb/exceptions'
require 'rex/proto/smb/evasions'
require 'rex/proto/smb/crypt'
require 'rex/proto/smb/utils'
require 'rex/proto/smb/client'

# Some short-hand class aliases
CONST = Rex::Proto::SMB::Constants
CRYPT = Rex::Proto::SMB::Crypt
UTILS = Rex::Proto::SMB::Utils
XCEPT = Rex::Proto::SMB::Exceptions
EVADE = Rex::Proto::SMB::Evasions


	class OpenFile
		attr_accessor	:name, :tree_id, :file_id, :mode, :client, :chunk_size
		
		def initialize(client, name, tree_id, file_id)
			self.client = client
			self.name = name
			self.tree_id = tree_id
			self.file_id = file_id
			self.chunk_size = 48000
		end
		
		def delete
			begin
				self.close
			rescue
			end
			self.client.delete(self.name, self.tree_id)
		end
		
		# Close this open file
		def close
			self.client.close(self.file_id, self.tree_id)
		end
		
		# Read data from the file
		def read (length = nil, offset = 0)	
			if (length == nil)
				data = ''
				fptr = offset
				ok = self.client.read(self.file_id, fptr, self.chunk_size)
				while (ok['Payload'].v['DataLenLow'] > 0)
					buff = ok.to_s.slice(
						ok['Payload'].v['DataOffset'] + 4,
						ok['Payload'].v['DataLenLow']
					)
					data << buff
					fptr += ok['Payload'].v['DataLenLow']
					ok = self.client.read(self.file_id, fptr, self.chunk_size)
				end
				return data
			else
				ok = self.client.read(self.file_id, offset, length)
				data = ok.to_s.slice(
					ok['Payload'].v['DataOffset'] + 4,
					ok['Payload'].v['DataLenLow']
				)
				return data
			end
		end

		def << (data)
			self.write(data)
		end

		# Write data to the file
		def write(data, offset = 0)	
			# Track our offset into the remote file
			fptr = offset
			
			# Duplicate the data so we can use slice!
			data = data.dup
			
			# Take our first chunk of bytes
			chunk = data.slice!(0, self.chunk_size)
			
			# Keep writing data until we run out
			while (chunk.length > 0)
				ok = self.client.write(self.file_id, fptr, chunk)	
				cl = ok['Payload'].v['CountLow']
				
				# Partial write, push the failed data back into the queue
				if (cl != chunk.length)
					data = chunk.slice(cl - 1, chunk.length - cl) + data
				end
				
				# Increment our painter and grab the next chunk
				fptr += cl
				chunk = data.slice!(0, self.chunk_size)
			end
		end
	end
	

# Public accessors
attr_accessor	:last_error

# Private accessors
attr_accessor	:socket, :client, :direct, :shares, :last_share

	# Pass the socket object and a boolean indicating whether the socket is netbios or cifs
	def initialize (socket, direct = false)
		self.socket = socket
		self.direct = direct
		self.client = Rex::Proto::SMB::Client.new(socket)
		self.shares = { }
	end
	
	def login (name = '*SMBSERVER', user = '', pass = '', domain = '')
		begin
			
			if (self.direct != true)
				self.client.session_request(name)
			end
			
			self.client.negotiate
			ok = self.client.session_setup(user, pass, domain)
		rescue
			e = XCEPT::LoginError.new
			e.source = $!.to_s 
			raise e
		end
		
		return true
	end
	
	def connect (share)
		ok = self.client.tree_connect(share)
		tree_id = ok['Payload']['SMB'].v['TreeID']
		self.shares[share] = tree_id
		self.last_share = share
	end
	
	def disconnect (share)
		ok = self.client.tree_disconnect(self.shares[share])
		self.shares.delete(share)
	end	
	
	def open (path, mode=0)
		ok = self.client.open(path, mode)
		file_id = ok['Payload'].v['FileID']
		
		fh = OpenFile.new(self.client, path, self.client.last_tree_id, file_id)
	end
	
	def delete (*args)
		self.client.delete(*args)
	end

end
end
end
end