# -*- coding: utf-8 -*-
module Crawler
  module Weibo
    module Mobile
      module Home
        class InfoPage < Page

          module WeiboSetting
            BASE_URL = "http://weibo.cn/"
          end

          def initialize(provincename_to_id_hash, cityname_to_id_hash)
            @tags_page = nil
            @cookie = nil
            @provincename_to_id_hash = provincename_to_id_hash
            @cityname_to_id_hash = cityname_to_id_hash
          end

          def get(uid, cookie)
            @cookie = cookie
            url = WeiboSetting::BASE_URL + uid.to_s+ "/info"
            #puts "url: #{url}"
            super("utf-8", @cookie, url)
          end
          
          def get_info(uid)
            screen_name = get_screen_name
            region = get_region
            return StatusCode::USER_UNEXIST if user_unexist?
            return StatusCode::COOKIE_ERROR if cookie_is_error?(screen_name, region)
            introduce = get_introduce
            certification = get_certification 
            daren = get_daren
            schools = get_schools
            jobs = get_jobs
            tags = get_tags(uid, @cookie)
            #print_log(screen_name, introduce, tags, schools, jobs, certification, daren, region)
            return {
              :uid => uid,
              :screen_name => screen_name,
              :description => introduce,
              :tags => tags.to_s.gsub('$',' ').strip,
              :school => schools.to_s.gsub('$',' ').gsub('·','$').strip,
              :job => jobs.to_s.gsub('$',' ').gsub('·','$').strip,
              :certification => certification,
              :daren => daren,
              :city => get_city_id(region)
            }
          end

          def save_info(info)
            begin
              user = User.find_by_uid(info[:uid])
              if !user.nil? && !info[:screen_name].empty?
                user.screen_name = info[:screen_name]
                user.description = info[:description]
                user.tags = info[:tags]
                user.school = info[:school]
                user.job = info[:job]
                user.certification = info[:certification]
                user.daren = info[:daren]
                user.city = info[:city] if user.city==1000 && info[:city]>0
                user.has_name = true
                #p user
                user.save
                puts "user with uid #{user.uid} saved."
              end
            rescue Exception => details
              puts "error occured when save moble info, caused by #{details}."
            end
          end

          private
            def build_search_option(limit, start)
              {
                :batch_size => limit,
                :start => start
              }
            end

            def get_screen_name
              screen_name_html = match(ParseRule::InMobileInfoPage::REG_GET_SCREEN_NAME)
              screen_name_html.nil?? "" : screen_name_html[1].to_s
            end

            def get_introduce
              introduce_html = match(ParseRule::InMobileInfoPage::REG_GET_INTRODUCE_HTML)
              introduce_html.nil?? "" : introduce_html[1].to_s
            end

            def get_certification
              certification_html = match(ParseRule::InMobileInfoPage::REG_GET_CERTIFICATION)
              certification_html.nil?? "" : certification_html[1].to_s
            end

            def get_daren
              daren_html = match(ParseRule::InMobileInfoPage::REG_GET_DAREN)
              daren_html.nil?? "" : daren_html[1].to_s
            end

            def get_region
              region_html = match(ParseRule::InMobileInfoPage::REG_REGION)
              region_html.nil?? "" : region_html[1].to_s
            end

            def get_schools
              schools = ""
              schools_html = match(ParseRule::InMobileInfoPage::REG_GET_SCHOOL_HTML)
              if !schools_html.nil?
                schools_html[1].split('<br>').each do |school|
                  schools += "$"+school
                end
              end
              schools         
            end

            def get_jobs
              jobs = ""
              jobs_html = match(ParseRule::InMobileInfoPage::REG_GET_JOB_HTML)
              if !jobs_html.nil?
                jobs_html[1].split('<br>').each do |job|
                  jobs += "$"+job
                end
              end
              jobs
            end

            def user_unexist?
              contains?(ParseRule::InMobileInfoPage::WORD_UNEXIST)
            end

            def cookie_is_error?(screen_name, region)
              screen_name.empty? && region.empty?
            end

            def get_tags(uid, cookie)
              sleep 1
              @tags_page = TagsPage.new
              @tags_page.get(uid, @cookie)
              return @tags_page.tags
            end

            def get_city_id(region)
              if !region.empty? && region.split(' ').length == 2
                province_name = region.split(' ')[0]
                city_name = region.split(' ')[1]
                province_id = @provincename_to_id_hash[province_name]
                if !province_id.nil?
                  city_id = @cityname_to_id_hash["#{province_id} #{city_name}"]
                  puts "city id in page: #{city_id}"
                  return city_id.to_i if !city_id.nil?
                end
              end
              return -1
            end

            def print_log(screen_name, introduce, tags, schools, jobs, certification, daren, region)
              puts screen_name if !screen_name.empty?
              puts introduce if !introduce.empty?
              puts tags if !tags.empty?
              puts schools if !schools.empty?
              puts jobs if !jobs.empty?
              puts certification if !certification.empty?
              puts daren if !daren.empty?
              puts region if !region.empty?
            end

        end
      end
    end
  end
end

