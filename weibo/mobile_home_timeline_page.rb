# -*- coding: utf-8 -*-
# 
# 
# 
# Somebody's Timeline Page
# 
# 
# 
# 
module Crawler
  module Weibo
    module Mobile
      module Home
        class TimelinePage < Page

          module WeiboSetting
            BASE_URL = "http://weibo.cn/"
          end

          def initialize(uid, page_no, cookie)
            @cookie = cookie
            @page_no = page_no
            @url = "#{WeiboSetting::BASE_URL}#{uid}/profile?page=#{@page_no}"
          end

          def get
            super("utf-8", @cookie, @url)
          end

          def get_cookie_for_test
            @cookie = Cook.where("page_type = ? and frequent = ? and expired = ? and owner = ? and remark=?", "mobile", false, false, 'zhejiang2', 'update').first
          end
          
          def weibos_dom
            parse(ParseRule::InMobileTimelinePage::CSS_WEIBOS)
          end

          def weibos
            weibos_dom.map{|wd| {
              :wid => wd['id'].split('_').last,
              :content => wd.css(ParseRule::InMobileTimelinePage::CSS_WEIBO_CONTENT).text,
              :source => wd.css(ParseRule::InMobileTimelinePage::CSS_WEIBO_TIME_AND_SOURCE).text.split('来自').last,
              :create_time => Time.parse(time_transmit(wd.css(ParseRule::InMobileTimelinePage::CSS_WEIBO_TIME_AND_SOURCE).text.split('来自').first)).utc
            }}
          end

          def page_count
            ParseRule::InMobileTimelinePage::REG_PAGE_COUNT.match(parse("#pagelist").text).to_s.delete("/").to_i
          end

          def user_unexist?
            contains?(ParseRule::InMobileTimelinePage::WORD_UNEXIST)
          end

          def logged?
            contains?(ParseRule::InMobileTimelinePage::WORD_QUIT)
          end

          def is_bad_account?
          end

          def time_transmit(weibo_time)
            if !weibo_time.index('分钟前').nil?
              number_of_minute = weibo_time.match(/^[0-9]+/).to_s.to_i
              weibo_time = number_of_minute.minutes.ago.to_s
            elsif /.+月.+日.+/.match(weibo_time)
              time = Date._strptime(weibo_time, "%m月%d日 %H:%M")
              weibo_time = Time.local(Time.now.year, time[:mon], time[:mday], time[:hour], time[:min]).utc.to_s
            end
            weibo_time
          end

        end
      end
    end
  end
end

