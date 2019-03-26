#!/usr/bin/env ruby

require 'csv'
require 'tempfile'
require 'fileutils'
require 'logger'

################################################################################
#
# Recreate the OPenn repository CSV format for Walters MSS and Other books. A
# separate file will be needed for each collection. The following is a sample
# of an OPenn repository CSV.
#
# From '0007_contents.csv':
#
#   document_id,path,title,metadata_type,created,updated
#   665,0007/SCMS0142,"Copy of Engineers Private Journal on Harlem Bridge, 1860-1861",TEI,2015-08-12T19:57:01+00:00,2015-10-07T00:31:20+00:00
#   670,0007/SCMS0281_v01,Estelle Johnston Diaries,TEI,2015-08-13T14:04:52+00:00,2015-10-07T00:31:20+00:00
#   671,0007/SCMS0281_v02,Estelle Johnston Diaries,TEI,2015-08-13T14:35:51+00:00,2015-10-07T00:31:20+00:00
#   672,0007/SCMS0014_v01,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T15:21:20+00:00,2015-10-07T00:31:19+00:00
#   673,0007/SCMS0014_v02,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T16:11:36+00:00,2015-10-07T00:31:19+00:00
#   674,0007/SCMS0014_v03,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T17:22:34+00:00,2015-10-07T00:31:19+00:00
#   677,0007/SCMS0014_v04,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T18:53:56+00:00,2015-10-07T00:31:20+00:00
#   679,0007/SCMS0014_v05,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T19:38:47+00:00,2015-10-07T00:31:20+00:00
#   680,0007/SCMS0014_v06,"William L. Estes, Jr. Diaries of Army Service in France",TEI,2015-08-13T20:06:44+00:00,2015-10-07T00:31:20+00:00
#
# COLUMNS
#
#   document_id   -- not available, leave as ''
#
#   path          -- 0020/Data/{WaltersManuscripts,OtherColllections}
#
#   title         -- extract from metadata.xml '<dc:title>' (e.g., OtherCollections/PC1/data/metadata.xml)
#
#   metadata_type -- always 'Walters TEI'
#
#   created       -- directory mtime
#
#   updated       -- directory mtime
#
################################################################################

################################################################################
# CONSTANTS
################################################################################
OPENN_ROOT          = ENV['OPENN_ROOT']
BASEDIR             = "#{OPENN_ROOT}/Data/".freeze
CSV_DESTINATION     = File.join BASEDIR, '0020_contents.csv'
WALTERS_DIRECTORIES = %W{ #{OPENN_ROOT}/Data/0020/Data/WaltersManuscripts #{OPENN_ROOT}/Data/0020/Data/OtherCollections }.freeze

# 2015-10-07T00:31:19+00:00
DATE_FORMAT         = '%Y-%m-%dT%H:%M:%S%z'.freeze
HEADERS             = %w{ document_id path title metadata_type created updated }.freeze

CMD                 = File.basename __FILE__
LOGGER              = Logger.new STDOUT
LOGGER.level        = ENV['WALTERS_CSV_LOG_LEVEL'] || Logger::INFO

################################################################################
# METHODS
################################################################################
def valid_openn_root?
  return false if OPENN_ROOT.nil?
  return false if OPENN_ROOT.strip.empty?
  return false unless File.directory? OPENN_ROOT
  return false unless File.directory? "#{OPENN_ROOT}/Data"
  true
end # def valid_env?

def skip? subdirectory
  return true unless File.directory? subdirectory
  return true if subdirectory =~ /\b(WDL[-\w]*|html|wam-kiosks|ManuscriptDescriptions)$/
end # def skip? subdirectory

def extract_title subdirectory
  return 'Manuscript Descriptions directory' if subdirectory =~ /ManuscriptDescriptions/
  frag = IO.read File.join(subdirectory, 'data/metadata.xml'), 8192
  frag =~ /<dc:title>(.+)<\/dc:title>/m
  "#$1".strip
end

def get_metadata_type subdirectory
  return 'Walters NO-TEI' if subdirectory =~ /OtherCollections/
  return 'TEI Files' if subdirectory =~ /ManuscriptDescriptions/
  'Walters TEI'
end

def get_created subdirectory
  get_updated subdirectory
end # def get_created sub

def get_updated subdirectory
  File.mtime subdirectory
end # def get_updated subdirectory

def datetime_format date
  date.strftime DATE_FORMAT
end # def format date

abort "ERROR: OPENN_ROOT not set to OPenn root directory" unless valid_openn_root?


LOGGER.info(CMD) { "Generating Walters CSV" }

tmp_csv = Tempfile.new
begin
  CSV.open tmp_csv, "wb", headers: true do |csv|
    csv << HEADERS
    WALTERS_DIRECTORIES.each do |dir|
      Dir["#{dir}/*"].each do |subdir|
        next if skip? subdir
        reldir        = subdir.sub /^#{BASEDIR}/, ''
        title         = extract_title subdir
        metadata_type = get_metadata_type subdir
        created       = datetime_format get_created subdir
        updated       = datetime_format get_updated subdir
        csv << [ '', reldir, title, metadata_type, created, updated ]
      end
    end
  end

  if ! File.exist? CSV_DESTINATION
    FileUtils.cp tmp_csv.path, CSV_DESTINATION, verbose: true
    FileUtils.chmod 0644, CSV_DESTINATION
    LOGGER.info(CMD) { "New CSV written to: #{CSV_DESTINATION}" }
  elsif FileUtils.compare_file tmp_csv.path, CSV_DESTINATION
    LOGGER.info(CMD) { "No change to Walters CSV: #{CSV_DESTINATION}; exiting" }
  else
    FileUtils.cp tmp_csv.path, CSV_DESTINATION, verbose: true
    FileUtils.chmod 0644, CSV_DESTINATION
    LOGGER.info(CMD) { "Updated CSV written to: #{CSV_DESTINATION}" }
  end
ensure
  tmp_csv.close
  tmp_csv.unlink
end
