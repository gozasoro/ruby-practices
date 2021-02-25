#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

module LS
  class Command
    def initialize(options)
      @show_options = {}

      opt = OptionParser.new

      opt.on('-l') { |v| @show_options[:l] = v }
      opt.on('-a') { |v| @show_options[:a] = v }
      opt.on('-r') { |v| @show_options[:r] = v }
      opt.parse!(options)
    end

    def files_info
      files = pick_up_and_sort_files
      in_detail? ? create_files_in_detail(files) : create_files_simply(files)
    end

    private

    def in_detail?
      @show_options[:l]
    end

    def all?
      @show_options[:a]
    end

    def reverse?
      @show_options[:r]
    end

    def pick_up_and_sort_files
      files = if all?
                create_file_info(Dir.glob('*', File::FNM_DOTMATCH))
              else
                create_file_info(Dir.glob('*'))
              end
      reverse? ? files.reverse : files
    end

    def create_file_info(match_files)
      match_files.sort.map { |file| FileInfo.new(file) }
    end

    def create_files_simply(files)
      filenames = files.map(&:name)
      rows_count = (filenames.size.to_f / 3).ceil
      (rows_count * 3 - filenames.size).times { filenames.push '' }
      rows = create_rows(filenames, rows_count)
      rows.map { |row| row.join('     ') }.join("\n")
    end

    def create_rows(filenames, rows_count)
      rows = filenames.each_slice(rows_count).to_a
      rows.map do |columns|
        max_length = columns.map(&:length).max
        columns.map { |column| column.ljust(max_length) }
      end.transpose
    end

    def create_files_in_detail(files)
      nlink_digits = files.map(&:nlink).max.digits.length
      size_digits = files.map(&:size).max.digits.length
      total_blocks = 0
      lines = files.map do |file|
        words = create_words(file, nlink_digits, size_digits)
        total_blocks += file.blocks
        words.join(' ')
      end
      "total #{total_blocks}\n#{lines.join("\n")}"
    end

    def create_words(file, nlink_digits, size_digits)
      words = []
      words.push file.ftype + file.permission
      words.push file.nlink.to_s.rjust(nlink_digits)
      words.concat([file.owner, file.group])
      words.push file.size.to_s.rjust(size_digits)
      words.concat([file.timestamp, file.name])
      words
    end
  end

  class FileInfo
    attr_reader :name, :nlink, :size, :blocks

    def initialize(filename)
      @name = filename
      @filestat = File.lstat(filename)
      @nlink = @filestat.nlink
      @size = @filestat.size
      @blocks = @filestat.blocks
    end

    def ftype
      type = File.ftype(@name)[0]
      type == 'f' ? '-' : type
    end

    def permission
      binary = @filestat.mode.to_s(2)[-9, 9]
      permission_chars = 'rwxrwxrwx'.chars.map.with_index do |c, index|
        binary[index] == '0' ? '-' : c
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

puts LS::Command.new(ARGV).files_info
