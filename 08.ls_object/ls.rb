#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

module LS
  class Command
    def initialize(argv)
      @argv = argv
    end

    def call
      opt = OptionParser.new

      options = {}
      opt.on('-l') { |v| options[:l] = v }
      opt.on('-a') { |v| options[:a] = v }
      opt.on('-r') { |v| options[:r] = v }
      opt.parse!(@argv)

      show_files(options)
    end

    private

    def show_files(options)
      files = pick_up_and_sort_files(options)
      options[:l] ? show_in_detail(files) : show_simply(files)
    end

    def pick_up_and_sort_files(options)
      files = Dir.entries('.').sort.map do |file|
        next if file[0] == '.' && options[:a].nil?

        LS::File.new(file)
      end.compact
      files.reverse! if options[:r]
      files
    end

    def show_simply(files)
      filenames = files.map(&:name)
      rows_count = (filenames.size.to_f / 3).ceil
      (rows_count * 3 - filenames.size).times { filenames.push '' }
      rows = create_rows(filenames, rows_count)
      rows.each { |row| puts row.join('     ') }
    end

    def create_rows(filenames, rows_count)
      columns = filenames.each_slice(rows_count).to_a
      columns.map do |column|
        max_length = column.map(&:length).max
        column.map! { |filename| filename.ljust(max_length) }
      end
      columns.transpose
    end

    def show_in_detail(files)
      max_size = Math.log10(files.map(&:size).max).to_i + 1
      total_blocks = 0
      lines = files.map do |file|
        words = create_words(file, max_size)
        total_blocks += file.blocks
        words.join(' ')
      end
      puts "total #{total_blocks}"
      puts lines.join("\n")
    end

    def create_words(file, max_size)
      words = []
      words.push file.ftype + file.permission
      words.concat([file.nlink, file.owner, file.group])
      words.push file.size.to_s.rjust(max_size)
      words.concat([file.timestamp, file.name])
      words
    end
  end

  class File
    attr_reader :name, :nlink, :size, :blocks

    def initialize(filename)
      @name = filename
      @filestat = ::File.lstat(filename)
      @nlink = @filestat.nlink
      @size = @filestat.size
      @blocks = @filestat.blocks
    end

    def ftype
      type = ::File.ftype(@name)[0]
      type == 'f' ? '-' : type
    end

    def permission
      binary = @filestat.mode.to_s(2)[-9, 9]
      permission_chars = 'rwxrwxrwx'.chars.map.with_index do |c, index|
        c = '-' if binary[index] == '0'
        c
      end
      permission_chars.join
    end

    def owner
      Etc.getpwuid(@filestat.uid).name
    end

    def group
      Etc.getgrgid(@filestat.gid).name
    end

    def timestamp
      @filestat.mtime.strftime('%_m %e %R')
    end
  end
end

LS::Command.new(ARGV).call
