# wx-shapes command handler base
# Copyright (c) M.J.N. Corino, The Netherlands

require 'optparse'
require "rbconfig"

module WxShapes

  RUBY = ENV["RUBY"] || File.join(
    RbConfig::CONFIG["bindir"],
    RbConfig::CONFIG["ruby_install_name"] + RbConfig::CONFIG["EXEEXT"]).sub(/.*\s.*/m, '"\&"')

  module Commands

    class << self

      def commands
        @commands ||= ::Hash.new do |hash, key|
          STDERR.puts "Unknown command #{key} specified."
          exit(1)
        end
      end
      private :commands

      def options
        @options ||= {
          :verbose => false
        }
      end
      private :options

      def register(cmdid, cmdhandler)
        commands[cmdid.to_s] = case
                               when Proc === cmdhandler || Method === cmdhandler
                                 cmdhandler
                               when cmdhandler.respond_to?(:run)
                                 Proc.new { |args| cmdhandler.run(args) }
                               else
                                 raise RuntimeError, "Invalid wx-shapes command handler : #{cmdhandler}"
                               end
      end

      def describe_all
        puts "    wx-shapes commands:"
        commands.each do |id, cmd|
          puts
          puts cmd.call(:describe)
        end
        puts
      end

      def run(cmdid, args)
        commands[cmdid.to_s].call(args)
      end

      def parse_args(args)
        opts = OptionParser.new
        opts.banner = "Usage: wx-shapes [global options] COMMAND [arguments]\n\n" +
            "    COMMAND\t\t\tSpecifies wx-shapes command to execute."
        opts.separator ''
        opts.on('-v', '--verbose',
                'Show verbose output') { |v| ::WxShapes::Commands.options[:verbose] = true }
        opts.on('-h', '--help',
                 'Show this message.') do |v|
          puts opts
          puts
          describe_all
          exit(0)
        end
        opts.raise_unknown = false
        opts.parse!(args)
      end
    end
  end

  def self.run(argv = ARGV)
    # parse global options (upto first command)
    argv = WxShapes::Commands.parse_args(argv)
    while !argv.empty?
      WxShapes::Commands.run(argv.shift, argv)
    end
  end
end

Dir[File.join(__dir__, 'cmd', '*.rb')].each do |file|
  require file
end
