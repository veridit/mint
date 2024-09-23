module Mint
  class Cli < Admiral::Command
    module Command
      def execute(message, *, env : String? = nil, & : -> T) : T? forall T
        # On Ctrl+C and abort and exit.
        Signal::INT.trap do
          terminal.puts
          terminal.divider
          terminal.puts "Aborted! Exiting..."
          exit(1)
        end

        # Print header and divider.
        terminal.header "Mint - #{message}"
        terminal.divider

        # Save terminal position in order to render divider in
        # case of an error.
        position =
          terminal.position

        # Have a variable for the result of the command.
        result = nil

        begin
          # Load environment variables.
          Env.init(env) do |file|
            terminal.puts "#{COG} Loaded environment variables from: #{file}"
          end

          # Measure elapsed time of a command.
          elapsed = Time.measure { result = yield }
        rescue CliException
          # In case of a CLI exception just exit.
          error nil, position
        rescue error : Error
          # In case of an error print it.
          error error.to_terminal, position
        rescue exception : Exception
          # In case of an exception print it.
          error exception.inspect_with_backtrace, position
        end

        # Format the elapsed time into a human readable format.
        formatted =
          TimeFormat.auto(elapsed).colorize.mode(:bold)

        # Print all done mssage.
        terminal.divider
        terminal.puts "All done in #{formatted}!"

        result
      end

      # Handles an error.
      def error(message, position)
        # Check if the command printed anything (last position of the IO is not
        # the current one).
        printed =
          terminal.position != position

        # If printed we need to print a divider.
        if printed
          terminal.puts
          terminal.divider
        end

        # If we have a message we need to print it and a divider.
        if message
          terminal.puts
          terminal.print message
          terminal.divider
        end

        terminal.puts "There was an error, exiting...".colorize.mode(:bold)

        # Exit with one to trigger failures in CI environments.
        exit(1)
      end

      def check_dependencies!(dependencies : Array(Installer::Dependency))
        dependencies.each do |dependency|
          next if Dir.exists?(".mint/packages/#{dependency.name}")

          terminal.puts "#{COG} Ensuring dependencies..."
          terminal.puts " ↳ Not all dependencies in your mint.json file are installed."
          terminal.puts "   Would you like to install them now? (Y/n)"

          answer = gets.to_s.downcase
          terminal.puts AnsiEscapes::Erase.lines(2)

          if answer == "y"
            Installer.new
            break
          else
            terminal.print "#{WARNING} Missing dependencies..."
            raise CliException.new
          end
        end
      end

      def terminal
        Render::Terminal::STDOUT
      end
    end
  end
end
