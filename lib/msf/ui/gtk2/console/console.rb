module Msf
  module Ui
    module Gtk2

      class Console

        ###
        #
        # Classic console herited from SkeletonConsole
        #
        ###
        class Shell < Msf::Ui::Gtk2::SkeletonConsole

          def initialize(iter)
            session = iter[3]
            super(iter)

            if (session.type == "meterpreter")
              require 'msf/ui/gtk2/console/interactive_channel.rb'

              self.type = "shell"

              meterconsole = Rex::Post::Meterpreter::Ui::Console.new(session)
              meterconsole.extend(Pipe)
              cmd_exec = "cmd.exe"
              cmd_args = nil
              channelized = true
              hidden = true
              from_mem = false
              dummy_exec = "cmd"
              p = session.sys.process.execute(cmd_exec, cmd_args,
              'Channelized' => channelized,
              'Hidden'      => hidden,
              'InMemory'    => (from_mem) ? dummy_exec : nil)

              # Create a new pipe to not use the pipe class
              @pipe = Rex::IO::BidirectionalPipe.new

              # Create a subscriber with a callback for the UI
              @pipe.create_subscriber_proc() do |data|
                self.insert_text(Rex::Text.to_utf8(data))
              end

              # Interact with the supplied channel
              meterconsole.interact_with_channel(p.channel, @pipe)
            end
          end

          #
          # Send command to bidirectionnal_pipe
          #
          def send_cmd(cmd)
            # Write the command plus a newline to the input
            @pipe.write_input(cmd + "\n")
          end

        end # Console::Shell

        ###
        #
        # Meterpreter Console herited from SkeletonConsole
        #
        ###
        class Meterpreter < Msf::Ui::Gtk2::SkeletonConsole
          #require 'msf/ui/gtk2/console/interactive_channel.rb'

          def initialize(iter)
            # meterpreter client
            session = iter[3]

            # call the parent
            super(iter)

            meterconsole = Rex::Post::Meterpreter::Ui::Console.new(session)
            # meterconsole.extend(Pipe)

            # Create a new pipe to not use the pipe class
            @pipe = Rex::IO::BidirectionalPipe.new

            # Create a subscriber with a callback for the UI
            @pipe.create_subscriber_proc() do |data|
              self.insert_text(Rex::Text.to_utf8(data))
            end
            
            meterconsole.init_ui(@pipe, @pipe)

            @t_run = Thread.new do
              meterconsole.interact { self.interacting != true }
            end
          end

          #
          # Send command to bidirectionnal_pipe
          #
          def send_cmd(cmd)
            # Write the command plus a newline to the input
            @pipe.write_input(cmd + "\n")
          end

        end # Console::Meterpreter

      end # Console

    end
  end
end
