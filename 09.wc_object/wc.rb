#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

module WC
  class Command
    def initialize(argv)
      @argv = argv
    end

    def call
      opt = OptionParser.new

      options = {}
      opt.on('-l') { |v| options[:l] = v }
      opt.parse!(@argv)

      files = @argv.empty? ? create_stdin_file : create_files(@argv)
      show(files, options)
    end

    private

    def create_stdin_file
      [WC::StdinFile.new(readlines)]
    end

    def create_files(argv)
      filenames = argv.each_with_object([]) { |arg, file_args| file_args.concat(Dir.glob(arg)) }
      filenames.map { |filename| WC::File.new(filename) }
    end

    def show(files, options)
      width = calculate_width(files, options)
      display_lines(files, options, width)
      display_total(files, options, width) if files.size > 1
    end

    def display_lines(files, options, width)
      files.each do |f|
        line = [f.lineno, f.name]
        line.insert(1, f.wordno, f.size) unless options[:l]
        puts line.map { |l| l.to_s.rjust(width) }.join(' ')
      end
    end

    def display_total(files, options, width)
      line = [files.sum(&:lineno), 'total']
      line.insert(1, files.sum(&:wordno), files.sum(&:size)) unless options[:l]
      puts line.map { |l| l.to_s.rjust(width) }.join(' ')
    end

    def calculate_width(files, options)
      return 7 if files.first.is_a?(WC::StdinFile)

      if options[:l]
        files.map(&:lineno).max.to_s.length
      else
        files.map(&:size).max.to_s.length
      end
    end
  end

  class StdinFile
    attr_reader :size, :name, :lineno

    def initialize(lines)
      @lines = lines
      @size = lines.map(&:bytesize).sum
      @name = ''
      @lineno = lines.size
    end

    def wordno
      @lines.join(' ').split(/\s+/).size
    end
  end

  class File
    attr_reader :size, :name

    def initialize(filename)
      @filename = filename
      @name = ::File.basename(filename)
      @size = ::File.lstat(filename).size
    end

    def lineno
      ::File.open(@filename) { |f| f.readlines.count }
    end

    def wordno
      ::File.open(@filename) { |f| f.readlines.join(' ').split(/\s+/).size }
    end
  end
end

WC::Command.new(ARGV).call
