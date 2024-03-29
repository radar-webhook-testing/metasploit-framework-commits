module Msf
  module Ui
    module Gtk2

      module InteractiveChannel

        include Rex::Ui::Interactive

        #
        # Interacts with self.
        #
        def _interact
          # If the channel has a left-side socket, then we can interact with it.
          if (self.lsock)
            self.interactive(true)

            interact_stream(self)

            self.interactive(false)
          else
            print_error("Channel #{self.cid} does not support interaction.")

            self.interacting = false
          end
        end

        #
        # Called when an interrupt is sent.
        #
        def _interrupt
          prompt_yesno("Terminate channel #{self.cid}?")
        end

        #
        # Suspends interaction with the channel.
        #
        def _suspend
          # Ask the user if they would like to background the session
          if (prompt_yesno("Background channel #{self.cid}?") == true)
            self.interactive(false)

            self.interacting = false
          end
        end

        #
        # Closes the channel like it aint no thang.
        #
        def _interact_complete
          begin
            self.interactive(false)

            self.close
          rescue IOError
          end
        end

        #
        # Reads data from local input and writes it remotely.
        #
        def _stream_read_local_write_remote(channel)
          data = user_input.gets

          self.write(data)
        end

        #
        # Reads from the channel and writes locally.
        #
        def _stream_read_remote_write_local(channel)
          data = self.lsock.sysread(16384)

          user_output.print(data)
        end

        #
        # Returns the remote file descriptor to select on
        #
        def _remote_fd(stream)
          self.lsock
        end

      end

      module Pipe
        #
        # Interacts with the supplied channel.
        #
        def interact_with_channel(channel, pipe)
          channel.extend(InteractiveChannel) unless (channel.kind_of?(InteractiveChannel) == true)
          @t_run = Thread.new do
            channel.interact(pipe, pipe)
          end
        end
      end

    end
  end
end
