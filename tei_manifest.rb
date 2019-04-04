#!/usr/bin/env ruby

require 'digest'
require 'tempfile'
require 'fileutils'
require 'logger'

abort "OPENN_ROOT environment variable must be set"  unless ENV['OPENN_ROOT']
OPENN_ROOT         = ENV['OPENN_ROOT']
TEI_DIRECTORY      = File.join OPENN_ROOT, 'Data/0020/Data/WaltersManuscripts/ManuscriptDescriptions'
MANIFEST           = File.join TEI_DIRECTORY, 'manifest-md5.txt'
GLOBS              = %w{ *_tei.xml *.{rng,rnc,xsd,dtd,odd} }.freeze

DEFAULT_BLOCK_SIZE = 1<<16

CMD                 = File.basename __FILE__
LOGGER              = Logger.new STDOUT
LOGGER.level        = ENV['WALTERS_TEI_LOG_LEVEL'] || Logger::INFO

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

LOGGER.info(CMD) { "Generating Walters TEI manifest" }

Dir.chdir TEI_DIRECTORY do
  changed = false
  data = {}
  files = GLOBS.flat_map { |glob| Dir[glob] }
  if File.exist? MANIFEST
    LOGGER.info(CMD) { "Manifest exists; checking for new/updated files" }
    manifest_mtime = File.mtime MANIFEST
    data = manifest_data MANIFEST
    files.each do |f|
      next if data.include?(f) && manifest_mtime > File.mtime(f)
      if data.include? f
        LOGGER.info(CMD) { "Setting checksum for updated file: #{f}" }
      else
        LOGGER.info(CMD) { "Setting checksum for new file: #{f}" }
      end
      data[f] = get_checksum f
      changed = true
    end
  else
    LOGGER.debug(CMD) { "No manifest exists; generating all checksums" }
    data = files.inject({}) { |hash,f| 
      LOGGER.debug(CMD) { "Setting checksum for file: #{f}" }
      hash[f] = get_checksum f
      hash
    }
    changed = true
  end
  if changed
    LOGGER.info(CMD) { "New data for manifest found; preparing new manifest" }
    begin
      tmp_file = Tempfile.new
      data.each { |file,checksum| tmp_file.puts "#{checksum}  #{file}" }
      tmp_file.flush

      if File.exist?(MANIFEST) && FileUtils.compare_file(tmp_file.path, MANIFEST)
        LOGGER.warn(CMD) { "Files changed, but manifest unchanged: #{MANIFEST}" }
      elsif File.exist? MANIFEST
        FileUtils.cp tmp_file.path, MANIFEST
        FileUtils.chmod 0644, MANIFEST
        LOGGER.info(CMD) { "Updated manifest: #{MANIFEST}" }
      else
        FileUtils.cp tmp_file.path, MANIFEST
        FileUtils.chmod 0644, MANIFEST
        LOGGER.info(CMD) { "Wrote new manifest: #{MANIFEST}" }
      end
    ensure
      if File.exist? tmp_file
        tmp_file.close
        tmp_file.unlink
      end
    end
  else
    LOGGER.info(CMD) { "INFO: No changes made to #{MANIFEST}" }
  end
end

