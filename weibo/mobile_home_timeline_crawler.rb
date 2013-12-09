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
        class TimelineCrawler

          def initialize
            @index = -1
            @page_no = 1
            @page = nil
            @page_count = 10
            @weibo_dup_counter = 0
            @cooks = []
            @weibos = []
          end

          def get_timeline(uid)
            get_all_cookies
            get_timeline_until_last_page(uid)
            #puts status_code
          end

          private
            def get_timeline_until_last_page(uid)
              big_account = BigAccount.find_by_uid(uid)
              @page_no = 1
              while @page_no <= @page_count do
                puts "Page No.: #{@page_no}/#{@page_count}"
                @page = TimelinePage.new(uid, @page_no, current_cookie)

                # invalid page or empty page or not logged in
                if @page.get < 0 || @page.empty? || !@page.logged?
                  delete_cookie
                  next
                end
                
                return StatusCode::USER_UNEXIST if @page.user_unexist?

                get_page_count if @page_no == 1
                weibos = @page.weibos
                status = save_weibos(weibos, big_account)
                return status if status == StatusCode::DONE 
                @page_no += 1
                sleep 2
              end
              return StatusCode::NORMAL
            end

            def get_page_count
              @page_count = @page.page_count
              puts "page count: #{@page_count}"
            end

            def save_weibos(weibos, big_account)
              #p weibos
              weibos.each do |weibo|
                if !weibo.nil? && !is_deleted?(weibo)
                  puts "来自@#{big_account.screen_name}的微博:"
                  p weibo
                  begin
                    if RepostSource.find_by_wid(weibo[:wid]).nil?
                      repost_source = RepostSource.new(weibo)
                      repost_source.big_account = big_account
                      repost_source.save
                      @weibo_dup_counter = 0
                    else
                      @weibo_dup_counter += 1
                      return StatusCode::DONE if @weibo_dup_counter > 3
                    end
                  rescue Exception => details
                    puts "Error occured when inserting a weibo: #{details}"
                  end
                end
              end
              return StatusCode::NORMAL
            end

            def get_all_cookies
              puts "Get all cookies from db."
              @cooks = Cook.where("page_type = ? and frequent = ? and expired = ? and remark=?", "mobile", false, false, 'update').map{|cook| cook.content}
            end

            def current_cookie
              @cooks.last unless @cooks.nil?
            end

            def delete_cookie
              puts "delete cookie #{current_cookie} at #{Time.now}"
              @cooks.pop
              get_all_cookies if @cooks.length < 10
            end

            def is_deleted?(weibo)
              !weibo[:content].index(ParseRule::InMobileTimelinePage::WEIBO_DELETED).nil?
            end

        end
      end
    end
  end
end
