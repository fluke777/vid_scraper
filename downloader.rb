require 'bundler/setup'
require "capybara"
require "capybara/dsl"
require "capybara-webkit"
require 'active_support/all'
require 'pry'
require 'json'
require "open-uri"
require 'pathname'

params = JSON.parse(File.read('params.json'), :symbolize_names => true)

DRIVE_PATH = params[:drive_path]
STATE_FILE = 'result.json'

base = Pathname(DRIVE_PATH)

files = JSON.parse(File.read(STATE_FILE))
files.each do |item|
  filename = item["filename"]
  uri = item["uri"]

  puts "Downloading #{filename}"
  target = base + filename
  if File.exist?(target)
    puts "Skipping #{filename}"
  else
    begin
      open(uri) do |f|
         File.open(target,"wb") do |file|
           file.puts f.read
         end
      end
    rescue  RuntimeError => e
      binding.pry
      puts "----- FAIL: Download of #{filename} from #{uri} failed"
    end
  end
end
