#!/usr/bin/env ruby

require 'digest'
require 'tempfile'
require 'fileutils'

abort "OPENN_ROOT environment variable must be set"  unless ENV['OPENN_ROOT']
OPENN_ROOT         = ENV['OPENN_ROOT']
TEI_DIRECTORY      = File.join OPENN_ROOT, 'Data/0020/Data/WaltersManuscripts/ManuscriptDescriptions'
MANIFEST           = File.join TEI_DIRECTORY, 'manifest-md5.txt'
GLOBS              = %w{ *_tei.xml *.{rng,rnc,xsd,dtd,odd} }.freeze

DEFAULT_BLOCK_SIZE = 1<<16

descriptions = Dir["#{TEI_DIRECTORY}/*_tei.xml"]

def manifest_data file
  open(file, 'r').readlines.map(&:chomp).inject({}) { |memo,line|
    memo[line.split.last] = line.split.first
    memo
  }
end # def manifest_data file

def get_checksum file, blocksize: DEFAULT_BLOCK_SIZE
  digest = Digest::MD5.new
  data = File.open file, 'rb'
  digest << data.read(blocksize) until data.eof?
  digest.hexdigest
end # def get_checksum file, blocksize: DEFAULT_BLOCK_SIZE

Dir.chdir TEI_DIRECTORY do
  changed = false
  data = {}
  if File.exist? MANIFEST
    manifest_mtime = File.mtime MANIFEST
    data = manifest_data MANIFEST
    files = GLOBS.flat_map { |glob| Dir[glob] }
    files.each do |f|
      next if data.include?(f) && manifest_mtime > File.mtime(f)
      data[f] = get_checksum f
      changed = true
    end
  else
    data = files.inject({}) { |hash,f| 
      hash[f] = get_checksum f
      hash
    }
    changed = true
  end
  if changed
    tmp_file = Tempfile.new
    data.each do |file,checksum|
      tmp_file.puts "#{checksum}  #{file}"
    end

    tmp_file.flush
    if File.exist?(MANIFEST) && FileUtils.compare_file(tmp_file.path, MANIFEST)
      puts "WARNING: Manifest unchanged"
    else
      FileUtils.cp tmp_file.path, MANIFEST
      FileUtils.chmod 0644, MANIFEST
      puts "INFO: Wrote new manifest: #{MANIFEST}"
    end
    tmp_file.close
    tmp_file.unlink
  else
    puts "INFO: No changes made to #{MANIFEST}"
  end
end
