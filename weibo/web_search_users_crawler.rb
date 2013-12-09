# -*- coding: utf-8 -*-
module Crawler
module Weibo
  module Web
    module Search
      class UserCrawler

        module UrlCondition
          BASE_URL = "http://s.weibo.com/user/"
          AGE = ['18','22','29','39','40']
          GENDER = ['man','woman']
          AUTH = ['ord','vip']
          SEARCH_TYPE = ['&nickname','&tag','&school','&work']
        end

        COOKIE_FAIL_LIMIT = 5
        PAGE_FAIL_LIMIT = 10

        def initialize
          @index = -1
          @page_no = 1
          @s_page = nil
          @page_count = 50
          @search_result_num = 0
          @fail_counter_in_page = 0
          @cook_master = []
          @cities_in_this_province = []
        end

        def get_users_from_keyword(province, city, astart, gstart, vstart, kid, owner)
          kid=0 if kid.nil?
          SearchKeyword.all.each do |sk|
            next if sk.id<kid
            puts " kid: " + sk.id.to_s
            result = get_users_for_one_keyword(province, city, astart, gstart, vstart, kid, sk.id, sk.keyword, owner)
            break if result.nil?       # stop search when error
          end
        end

        def get_users_by_tag(province, city, astart, gstart, vstart, tid, owner)
          @cities_in_this_province = City.select('city_id').where("province_id=?",province.to_i).order("city_id asc").map{|c| c.city_id}
          tid=0 if tid.nil?
          Tag.where("count>10").each do |t|
            next if t.id<tid
            puts " tid: #{t.id}"
            result = get_users_for_one_tag(province, city, astart, gstart, vstart, tid, t.id, t.tag, owner)
            break if result.nil?       # stop search when error
          end
        end

        def get_users_for_one_keyword(province,city,astart,gstart,vstart,kid,skid,word,owner)
          astartindex = astart.nil?? 0: UrlCondition::AGE.index(astart)
          gstartindex = gstart.nil?? 0: UrlCondition::GENDER.index(gstart)
          vstartindex = vstart.nil?? 0: UrlCondition::AUTH.index(vstart)
          UrlCondition::AGE.each_with_index do |age,aindex|
            next if kid == skid && aindex < astartindex
            UrlCondition::GENDER.each_with_index do |gender,gindex|
              next if kid == skid && aindex == astartindex && gindex < gstartindex
              UrlCondition::AUTH.each_with_index do |auth,vindex|
                next if kid == skid && aindex == astartindex && gindex == gstartindex && vindex < vstartindex
                UrlCondition::SEARCH_TYPE.each do |search_type|
                  url = UrlCondition::BASE_URL + search_type + '=' + URI.escape(word)+'&region=custom:'+province+':'+city+'&age='+age+'y'+'&gender='+gender+'&auth='+auth
                  # get cookies every url
                  @cook_master = []
                  Cook.where("page_type = ? and expired = ? and frequent = ? and owner = ?", "web", false, false, owner).each do |cook|
                    @cook_master << {:cook => cook, :fail_counter => 0}
                  end

                  if @cook_master.empty?
                    puts 'no available cookie'
                    return nil
                  end
                  @sleep_time = (10/@cook_master.length.to_f).ceil
                  p 'crawl for a base url'
                  get_users_until_last_page(url, province, city, age, gender, auth)
                end
              end
            end
          end
        end

        def get_users_for_one_tag(province,citystart,astart,gstart,vstart,start_id,current_id,word,owner)
          #p @cities_in_this_province
          astartindex = astart.nil?? 0: UrlCondition::AGE.index(astart)
          gstartindex = gstart.nil?? 0: UrlCondition::GENDER.index(gstart)
          vstartindex = vstart.nil?? 0: UrlCondition::AUTH.index(vstart)
          search_type = UrlCondition::SEARCH_TYPE[1]
          @cities_in_this_province.each do |city|
            next if start_id == current_id && city < citystart
            city = city.to_s  
            UrlCondition::AGE.each_with_index do |age,aindex|
              next if start_id == current_id && aindex < astartindex
              UrlCondition::GENDER.each_with_index do |gender,gindex|
                next if start_id == current_id && aindex == astartindex && gindex < gstartindex
                UrlCondition::AUTH.each_with_index do |auth,vindex|
                  next if start_id == current_id && aindex == astartindex && gindex == gstartindex && vindex < vstartindex      
                  url = UrlCondition::BASE_URL + search_type + '=' + URI.escape(word)+'&region=custom:'+province+':'+city+'&age='+age+'y'+'&gender='+gender+'&auth='+auth
                  # get cookies every url
                  @cook_master = []
                  Cook.where("page_type = ? and expired = ? and frequent = ? and owner = ?", "web", false, false, owner).each do |cook|
                    @cook_master << {:cook => cook, :fail_counter => 0}
                  end

                  if @cook_master.empty?
                    puts 'no available cookie'
                    return nil
                  end
                  @sleep_time = (10/@cook_master.length.to_f).ceil
                  #p url
                  get_users_until_last_page(url, province, city, age, gender, auth)
                end
              end
            end
          end
        end

        def get_users_until_last_page(baseurl, province, city, age, gender, auth)
          @page_no = 1
          reset_page_fail_counter
          while @page_no <= @page_count do
            sleep @sleep_time
            @s_page = UsersPage.new
            next if @s_page.get(baseurl, @page_no, current_cookie) < 0

            if @s_page.dom.nil?
              increase_page_fail_counter
              next
            end
            @s_page.ignore_encode_error

            # expired cookie or wrong cookie
            if @s_page.match?(ParseRule::InWebSearchUsersPage::REG_EX_EXPIRED) || @s_page.match?(ParseRule::InWebSearchUsersPage::REG_EX_WRONG_COOKIE)
              remain_cookie_count = do_expired_cookie
              return -1 if remain_cookie_count == 0
              increase_page_fail_counter
              next
            end

            get_page_count_and_result_num_when_first_page if @page_no == 1
            users = @s_page.get_users(province, city, age, gender, auth, @page_no)

            if (users.is_a? Integer) && users == -1
              increase_page_fail_counter
              next
            end

            if users.is_a? Array 
              if users.empty?
                remain_cookie_count = increase_cookie_fail_counter
                return -1 if remain_cookie_count == 0
              else
                reset_cookie_fail_counter
                reset_page_fail_counter
                @s_page.save_users(users)                                # save users to db
              end
            end
            @page_no += 1
          end
        end



      # 
      # private methods
      # 1. increase_page_fail_counter
      # 2. increase_cookie_fail_counter
      # 3. reset_cookie_fail_counter
      # 4. reset_page_fail_counter
      # 5. get_page_count_and_result_num_when_first_page
      # 6. current_cookie
      # 7. do_expired_cookie
      # 
        private
          def increase_page_fail_counter
            @fail_counter_in_page += 1
            @page_no+=1 if @fail_counter_in_page == PAGE_FAIL_LIMIT     # 每一页最多重复PAGE_FAIL_LIMIT次      
          end

          def increase_cookie_fail_counter
            @cook_master[@index][:fail_counter] += 1              # to judge expired cookie
            puts "fail_counter: #{@cook_master[@index][:fail_counter]}"
            if @cook_master[@index][:fail_counter] == COOKIE_FAIL_LIMIT
              remaining_cookie_count = do_expired_cookie
            end
            remaining_cookie_count
          end

          def reset_cookie_fail_counter
            @cook_master[@index][:fail_counter] = 0      
          end

          def reset_page_fail_counter
            @fail_counter_in_page = 0                                     
          end

          def get_page_count_and_result_num_when_first_page
            if @s_page.is_old_page?
              page_type =  "old"
              @search_result_num = @s_page.get_search_result_num("old")
              @page_count = @s_page.get_page_count("old")
            else
              page_type = "new"
              @search_result_num = @s_page.get_search_result_num("new")
              @page_count = @s_page.get_page_count("new")
            end
            puts "page type: #{page_type}, result_num: #{@search_result_num}, page_num: #{@page_count}"
          end

          def current_cookie
            p "page index:" + @index.to_s + ",cookies length: " + @cook_master.length.to_s
            @index = (@index+1) % @cook_master.length
            puts @cook_master[@index][:cook].username
            @cook_master[@index][:cook].content
          end

          # return remaining count of cookies
          def do_expired_cookie
            puts "Warning:" + @cook_master[@index][:cook].username + "'s cookie expired."
            expired_cookie = @cook_master[@index][:cook]
            expired_cookie.remark = '('+Time.now.to_s+')'+'expired|' + expired_cookie.remark
            expired_cookie.expired = true
            expired_cookie.save
            @cook_master.delete(@cook_master[@index])     #   delete this expired cookie
            @index -= 1

            # check the number of cookie
            if @cook_master.length == 0
              puts "Cookie is used up"
              return 0
            end

            @sleep_time = (10/@cook_master.length.to_f).ceil
            puts 'sleep time reset: ' + @sleep_time.to_s

            if @cook_master.length < 10                     #   reset the sleep time
              puts "Warning:the number of cookies < 10"
            end
            return @cook_master.length
          end

      end

    end
  end
end
end
