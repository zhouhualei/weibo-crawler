# -*- coding: utf-8 -*-
module Crawler
module Weibo
  module Web
    module Search
      class UsersPage < Page

        def initialize
        end

        def get_users(province, city, age, gender, auth, page)
          is_old_page? ? users_in_old_page(users_dom, province, city, age, gender, auth, page) : users_in_new_page(province, city, age, gender, auth, page)
        end

        def users_dom
          parse(ParseRule::InWebSearchUsersPage::CSS_USERS_DOM)
        end

        def is_old_page?
          !users_dom.empty?
        end

        def save_users(users_array)
          count = 0
          users_array.each do |user_h|
            user = User.new
            user.uid = user_h[:uid]
            user.province = user_h[:province]
            user.city = user_h[:city]
            user.age = user_h[:age]
            user.gender = user_h[:gender]
            user.v = user_h[:auth]

            if User.find_by_uid(user.uid).nil?
              begin
                user.save
                count += 1
              rescue Exception => details
                puts 'error when insert a user to db: ' + details.to_s
              end
            end
          end
          puts users_array.count.to_s + " users in old page, " + count.to_s + " users saved."
          return count
        end

        def users_in_old_page(user_htmls, province, city, age, gender, auth, page)
          user_htmls.map{|user_html| {
            :uid => user_html.css('.tit a')[0]['uid'].to_i,
            :province => province.to_i,
            :city => city.to_i,
            :age => age.to_i,
            :gender => gender,
            :v => auth
          }}
        end

        def get_search_result_num(page_type)
          if page_type == "old"
            return parse(ParseRule::InWebSearchUsersPage::CSS_RESULT_COUNT).text.match(/[0-9]+/).to_s.to_i
          else
            begin
              return search_result_num = match(ParseRule::InWebSearchUsersPage::REG_NEW_VERSION_SEARCH_RESULT).to_s.split[1].to_i
            rescue Exception => details
              puts "match error when get result count: " + details.to_s
            end          
          end
        end

        def get_page_count(page_type)
          if page_type == "old"
            page_urls = parse(ParseRule::InWebSearchUsersPage::CSS_PAGE_COUNT)
            return page_urls.empty? ? 1 : page_urls[-2]["href"].split('=').last.to_i
            #p "page count:" + @page_count.to_s
          else
            begin
              page_strs = parse(ParseRule::InWebSearchUsersPage::REG_EX_PAGE)
              if page_strs.empty?
                return 1
              else
                pages = []
                page_strs.each do |page_str|
                  pages << page_str.split('=').last.to_i
                end
                return pages.max
              end
              #p "page count:" + @page_count.to_s
            rescue Exception => details
              puts "match error when get page count: " + details.to_s
            end
          end
        end

        # 
        def users_in_new_page(province, city, age, gender, auth, page)
          uids = []
          begin
            ignore_encode_error

            begin
              person_list = parse(ParseRule::InWebSearchUsersPage::REG_EX_PERSONLIST)
            rescue Exception => details
              puts 'match error when person_list:' + details.to_s
            end

            if !person_list.nil? && !person_list.empty?
              uid_strs = person_list.first.to_s.scan(ParseRule::InWebSearchUsersPage::REG_EX_UID)
              uid_strs.each do |uid_str|
                uids << uid_str.split("\"").last.to_i
              end
            end
          rescue Exception => details
            puts 'ERROR: match error: ' + details.to_s
            return -1
          end
          uids.uniq!
          uids.map{|uid| {
            :uid => uid.to_i,
            :province => province.to_i,
            :city => city.to_i,
            :age => age.to_i,
            :gender => gender,
            :v => auth
          }}
        end

        def get(base_url, page, cookie)
          url = base_url + '&page=' + page.to_s
          #puts "url: #{url}"
          super("utf-8", cookie, url)
        end

      end

    end
  end
end
end