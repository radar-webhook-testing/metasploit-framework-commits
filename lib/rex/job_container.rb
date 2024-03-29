module Rex

###
#
# This class is the concrete representation of an abstract job.
#
###
class Job

	#
	# Creates an individual job instance and initializes it with the supplied
	# parameters.
	#
	def initialize(container, jid, name, ctx, run_proc, clean_proc)
		self.container  = container
		self.jid        = jid
		self.name       = name
		self.run_proc   = run_proc
		self.clean_proc = clean_proc
		self.ctx        = ctx
	end

	#
	# Runs the job in the context of its own thread if the async flag is flase.
	# Otherwise, the job is run inline.
	#
	def start(async = false)
		if (async)
			begin
				run_proc.call(ctx)
			rescue ::Exception
				container.stop_job(jid)

				raise $!
			end
		else
			self.job_thread = Thread.new {
				begin
					run_proc.call(ctx)
				ensure
					clean_proc.call(ctx)
					container.remove_job(self)
				end
			}
		end
	end

	#
	# Stops the job if it's currently running and calls its cleanup procedure
	#
	def stop
		if (self.job_thread)
			self.job_thread.kill
			self.job_thread = nil
		end
			
		clean_proc.call(ctx) if (clean_proc)
	end

	#
	# The name of the job.
	#
	attr_reader :name
	#
	# The job identifier as assigned by the job container.
	#
	attr_reader :jid

protected

	attr_writer   :name #:nodoc:
	attr_writer   :jid #:nodoc:
	attr_accessor :job_thread #:nodoc:
	attr_accessor :container #:nodoc:
	attr_accessor :run_proc #:nodoc:
	attr_accessor :clean_proc #:nodoc:
	attr_accessor :ctx #:nodoc:

end

###
#
# This class contains zero or more abstract jobs that can be enumerated and
# stopped in a generic fashion.  This is used to provide a mechanism for
# keeping track of arbitrary contexts that may or may not require a dedicated
# thread.
#
###
class JobContainer < Hash

	def initialize
		self.job_id_pool = 0
	end

	#
	# Adds an already running task as a symbolic job to the container.
	#
	def add_job(name, ctx, run_proc, clean_proc)
		real_name = name
		count     = 0
		jid       = job_id_pool

		self.job_id_pool += 1

		# If we were not supplied with a job name, pick one from the hat
		if (real_name == nil)
			real_name = '#' + jid.to_s
		end

		# Find a unique job name
		while (j = self[real_name])
			real_name  = name + " #{count}"
			count     += 1
		end

		j = Job.new(self, jid, real_name, ctx, run_proc, clean_proc)

		self[jid.to_s] = j
	end

	#
	# Starts a job using the supplied name and run/clean procedures.
	#
	def start_job(name, ctx, run_proc, clean_proc = nil)
		j = add_job(name, ctx, run_proc, clean_proc)
		j.start

		j.jid
	end

	#
	# Starts a background job that doesn't call the cleanup routine or run
	# the run_proc in its own thread.  Rather, the run_proc is called
	# immediately and the clean_proc is never called until the job is removed
	# from the job container.
	#
	def start_bg_job(name, ctx, run_proc, clean_proc = nil, async = true)
		j = add_job(name, ctx, run_proc, clean_proc)
		j.start(async)

		j.jid
	end

	#
	# Stops the job with the supplied name and forces it to cleanup.  Stopping
	# the job also leads to its removal.
	#
	def stop_job(jid)
		if (j = self[jid.to_s])
			j.stop

			remove_job(j)
		end
	end

	#
	# Removes a job that was previously running.  This is typically called when
	# a job completes its task.
	#
	def remove_job(inst)
		self.delete(inst.jid.to_s)
	end

protected

	attr_accessor :job_id_pool # :nodoc:

end

end
