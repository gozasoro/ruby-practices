#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

module WC
  class Command
    def initialize(options_and_files)
      @options_and_files = options_and_files
      @show_options = {}
    end

    def call
      opt = OptionParser.new

      opt.on('-l') { |v| @show_options[:l] = v }
      opt.parse!(@options_and_files)

      files = @options_and_files.empty? ? create_stdin_file : create_files(@options_and_files)
      puts show(files)
    end

    private

    def line_only?
      @show_options[:l]
    end

    def create_stdin_file
      [StdinFileInfo.new(readlines)]
    end

    def create_files(argv)
      filenames = argv.map { |arg| Dir.glob(arg) }.flatten
      filenames.map { |filename| FileInfo.new(filename) }
    end

    def show(files)
      width = calculate_width(files)
      create_file_info_strings(files, width)
    end

    def create_file_info_strings(files, width)
      rows = files.map { |file| line_only? ? [file.line_count, file.name] : [file.line_count, file.word_count, file.size, file.name] }
      rows.push create_total_line(files) if files.size > 1
      rows.map do |columns|
        columns.map { |column| column.to_s.rjust(width) }.join(' ')
      end.join("\n")
    end

    def create_total_line(files)
      line_only? ? [files.sum(&:lineno), 'total'] : [files.sum(&:line_count), files.sum(&:word_count), files.sum(&:size), 'total']
    end

    def calculate_width(files)
      return 7 if files.first.is_a?(StdinFileInfo)

      if line_only?
        files.map(&:line_count).max.to_s.length
      else
        files.map(&:size).max.to_s.length
      end
    end
  end

  class StdinFileInfo
    attr_reader :size, :name, :line_count, :word_count

    def initialize(lines)
      @size = lines.map(&:bytesize).sum
      @name = ''
      @line_count = lines.size
      @word_count = FileFunction.count_words(lines)
    end
  end

  class FileInfo
    attr_reader :size, :name, :line_count, :word_count

    def initialize(filename)
      @name = File.basename(filename)
      @size = File.lstat(filename).size
      @line_count, @word_count = count_lines_and_words(filename)
    end

    private

    def count_lines_and_words(filename)
      line_count = 0
      word_count = 0
      File.open(filename) do |file|
        lines = file.readlines
        line_count = lines.count
        word_count = FileFunction.count_words(lines)
      end
      [line_count, word_count]
    end
  end

  module FileFunction
    def self.count_words(lines)
      lines.join(' ').split(/\s+/).size
    end
  end
end

WC::Command.new(ARGV).call
