require 'bundler/setup'
require "capybara"
require "capybara/dsl"
require "capybara-webkit"
require 'active_support/all'
require 'pry'
require 'json'

params = JSON.parse(File.read('params.json'), :symbolize_names => true)

APP_HOST = params[:app_host]
PAGE_URI = params[:page_uri]

Capybara.run_server = false
Capybara.register_driver :selenium_no_flash do |app|
  require 'selenium/webdriver'
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => "capybara") 
end

Capybara.current_driver = :selenium_no_flash
Capybara.app_host = APP_HOST

module Test
  class Google
    include Capybara::DSL

    def get_results
      
      stuff = []
      
      visit(PAGE_URI)
      sleep(1)
      iframe_id = first('iframe')[:id]

      imgs = all('#video-list img')
      imgs.each do |img|
        img.click
        filename = img[:alt].titleize.gsub(' ', '').gsub('/', '_').underscore + ".mpg"
        sleep(1)
        begin
          within_frame(iframe_id) do |f|
            first('canvas').click
            sleep(1)
            video_id = first('video')[:id]
            html = page.evaluate_script("document.getElementById('#{video_id}').innerHTML")
            doc = Nokogiri.parse(html)
            id_to_download = doc.css('source').first[:src]
            stuff << {
              :filename => filename,
              :uri => id_to_download
            }
            puts id_to_download
          end
        rescue
          puts "UNABLE TO PROCESS #{filename}"
        end
      end

      File.open('result.json', 'w') do |f|
        f.write(JSON.pretty_generate(stuff))
      end

    end
  end
end

spider = Test::Google.new
spider.get_results