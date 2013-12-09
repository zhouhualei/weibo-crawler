# -*- coding: utf-8 -*-
require 'dalli'

module Crawler
module Weibo
  module Web
    module Home
      class ContactCrawler

        module WeiboSetting
          BASE_URL = "http://weibo.com/"
        end

        ZERO_LIMIT = 100
        COOKIE_FAIL_LIMIT = 3
        ALL_COOKIE_FAIL_LIMIT = 3

        def initialize
          @page = nil
          @zeroNum = 0
          @cookie_fail_counter = 0
          @all_cookie_fail_counter = 0
          @cookies = Cook.where("page_type=? and owner=? and frequent=? and expired=?" , "web","contact",false,false)
          @cookie = @cookies.last
        end

        def get_contacts(limitnum, mod_total, mod_num, start, machine)
          options = build_search_option(limitnum, start)
          begin
            User.select("uid").where(
              "(has_contact = ? or has_contact is null) and UNIX_TIMESTAMP(created_at)%?=?", 
              false, mod_total, mod_num
            ).find_in_batches(options) do |users_without_contact|
              # save progress in cache
	      CACHE.set "#{machine}_#{mod_num}_contact_uid", users_without_contact.first.uid
              status_code = parse_and_save_contacts(users_without_contact, limitnum)
              return status_code if status_code < 0
            end
          rescue Timeout::Error => ex
            puts "time out in find_in_batches: #{ex}"
          end
          return StatusCode::NORMAL
        end

        def update_all_contacts_of_a_province(mod_total, mod_num, province_code, start, machine)
          limitnum = 100
          options = build_search_option(limitnum, start)
          begin
            User.select("uid").where("province=? and uid>? and has_contact=? and has_name=? and UNIX_TIMESTAMP(created_at)%?=?", 
              province_code, start, true, true, mod_total, mod_num
            ).find_in_batches(options) do |users_with_old_contact|
            
              CACHE.set("#{machine}_#{mod_num}_update_uid", users_with_old_contact.first.uid, 7.day)
              status_code = parse_and_save_contacts(users_with_old_contact, limitnum)
              return status_code if status_code < 0
            end
          rescue Timeout::Error => ex
            puts "time out in find_in_batches: #{ex}"
          end
          return StatusCode::NORMAL
        end

        # update all_zero users of all province
        def update_zero_contacts_of_all_province(mod_total, mod_num, start, machine)
          limitnum = 50
          options = build_search_option(limitnum, start)
          begin
            User.select("uid").where(
              "uid>? and  has_contact = ? and fans_count = ? and followers_count = ? and weibo_count = ? and UNIX_TIMESTAMP(created_at)%?=?",
              start, true, 0, 0, 0, mod_total, mod_num
            ).find_in_batches(options) do |users_with_zero_contact|
 
              CACHE.set("#{machine}_#{mod_num}_zero_uid", users_with_zero_contact.first.uid, 7.day)
              status_code = parse_and_save_contacts(users_with_zero_contact, limitnum)
              return status_code if status_code < 0
            end
            rescue Timeout::Error => ex
              puts "time out in find_in_batches: #{ex}"
            end
            return StatusCode::NORMAL
        end

        # update all_zero users of a province
        def update_zero_contacts_of_a_province(mod_total, mod_num, province_code, start, machine)
          limitnum = 50
          options = build_search_option(limitnum, start)
          begin
            User.select("uid").where(
              "province=? and uid>? and  has_contact = ? and fans_count = ? and followers_count = ? and weibo_count = ? and UNIX_TIMESTAMP(created_at)%?=?",
              province_code, start, true, 0, 0, 0, mod_total, mod_num
            ).find_in_batches(options) do |users_with_zero_contact|
              
              CACHE.set("#{machine}_#{mod_num}_contact_for_province__uid", users_with_zero_contact.first.uid, 7.day)
              status_code = parse_and_save_contacts(users_with_zero_contact, limitnum)
              return status_code if status_code < 0
            end
            rescue Timeout::Error => ex
              puts "time out in find_in_batches: #{ex}"
            end
            return StatusCode::NORMAL
        end


        #
        # Private methods
        #
        #
        # 
        private
          def parse_and_save_contacts(contacts_todo, limitnum)
            index = 0
            puts "#{contacts_todo.length} contact info need to be completed"
            return StatusCode::NO_ITEMS if contacts_todo.empty?
            return StatusCode::NO_COOKIE if update_cookies == StatusCode::NO_COOKIE
            contacts_todo.each_with_index do |uid_object,index|
              uid = uid_object.uid
              puts "(#{index+1} of #{limitnum}) uid:#{uid}"
              @page = InfoPage.new
              if @page.get(WeiboSetting::BASE_URL, uid, @cookie.content) < 0
                p "fail to get this page"
                next
              end
              contact = @page.contact(uid)
              p contact
              if contact.is_a? Hash
                if all_zero?(contact)
                  increase_zero_counter
                else
                  @page.save_contact(contact)
                  reset_zero_counter
                end
              elsif contact.is_a? Integer
                code = increase_cookie_fail_counter
                return code if code < 0
                change_cookie if contact == StatusCode::COOKIE_ERROR
               # return StatusCode::NO_COOKIE if has_no_cookies?
                next if (contact == StatusCode::INVALID_PAGE) || (contact == StatusCode::MATCH_ERROR)
              end
            end
            return StatusCode::NORMAL         
          end

          def reset_zero_counter
            @zeroNum = 0
            @cookie_fail_counter = 0
            @all_cookie_fail_counter = 0
          end

          def increase_zero_counter
            @zeroNum += 1
            if @zeroNum == ZERO_LIMIT
              return update_cookies if change_cookie == StatusCode::NO_COOKIE
            end
            return StatusCode::NORMAL
          end

          def increase_cookie_fail_counter
            @cookie_fail_counter += 1
            if @cookie_fail_counter == COOKIE_FAIL_LIMIT
              return update_cookies if change_cookie == StatusCode::NO_COOKIE
            end
            return StatusCode::NORMAL
          end

          def build_search_option(limit, start)
            {
              :batch_size => limit,
              :start => start
            }
          end

          def update_cookies
            puts "update cookies, all cookie fail counter: #{@all_cookie_fail_counter}"
            @all_cookie_fail_counter += 1
            #p @all_cookie_fail_counter
            return StatusCode::ALL_COOKIE_ERROR if @all_cookie_fail_counter == ALL_COOKIE_FAIL_LIMIT
            @cookies = Cook.where("page_type=? and owner=? and frequent=? and expired=?" , "web","contact",false,false)
            return StatusCode::NO_COOKIE if @cookies.empty?
            @cookie = @cookies.last
            return StatusCode::NORMAL
          end

          def change_cookie
            puts "change cookie"
            @cookies.pop
            return StatusCode::NO_COOKIE if @cookies.empty?
            @cookie = @cookies.last
            @zeroNum = 0
            @cookie_fail_counter = 0
            return StatusCode::NORMAL
          end

          def has_no_cookies?
            @cookies.empty?
          end

          def all_zero?(contact)
            return (contact[:followers_count]==0) && (contact[:fans_count]==0) && (contact[:weibo_count]==0)
          end
       
      end

    end
  end
end
end


