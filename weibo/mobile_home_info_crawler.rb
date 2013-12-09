# -*- coding: utf-8 -*-
module Crawler
  module Weibo
    module Mobile
      module Home
        class InfoCrawler
          COOKIE_FAIL_LIMIT = 30

          def initialize
            @info_page = nil
            @cooks = []
            @index = 0
            @cookie_index = 0
            @cookie_fail_count = 0
            @provincename_to_id_hash = {}
            @cityname_to_id_hash = {}
          end
          
          def get_infos(limit_num, mod_total, mod_num, owner, mode, start, machine)
            load_region_to_cache
            update_cookies(owner)
            options = build_search_option(limit_num.to_i, start.to_i)
            begin
              User.select("uid").where(
                "(has_name = false or has_name is null) and UNIX_TIMESTAMP(created_at)%?=?", mod_total, mod_num
              ).find_in_batches(options) do |infos_todo|   
                CACHE.set("#{machine}_#{mod_num}_mobile_uid" , infos_todo.last.uid, 7.day)
                status_code = parse_and_save_infos(infos_todo, limit_num, owner, mode)
                return status_code if status_code < 0
              end
            rescue Timeout::Error
              puts "time out in find_in_batches"
            end
            return StatusCode::NORMAL
          end

          def update_empty_infos(limit_num, mod_total, mod_num, owner, mode, start, machine)
            load_region_to_cache
            update_cookies(owner)
            options = build_search_option(limit_num.to_i, start.to_i)
            begin
              User.select("uid").where(
                "(screen_name is null or screen_name=?) and UNIX_TIMESTAMP(created_at)%?=?", "", mod_total, mod_num
              ).find_in_batches(options) do |infos_todo|   
                CACHE.set("#{machine}_#{mod_num}_empty_uid" , infos_todo.last.uid, 7.day)
                status_code = parse_and_save_infos(infos_todo, limit_num, owner, mode)
                return status_code if status_code < 0
              end
            rescue Timeout::Error
              puts "time out in find_in_batches"
            end
            return StatusCode::NORMAL
          end

          private
            def build_search_option(limit, start)
              {
                :batch_size => limit,
                :start => start
              }
            end

            def parse_and_save_infos(infos_todo, limit_num, owner, mode)
              @index = -1
              puts "#{infos_todo.length} uids is in the mission."
              return StatusCode::NO_ITEMS if infos_todo.length == 0
              while(@index < infos_todo.length-1)
                @index += 1
                uid_object = infos_todo[@index]
                uid = uid_object.uid
                update_cookies(owner) if @cooks.length < 4
                return StatusCode::NO_COOKIE if @cooks.empty?
                @cookie_index = (@index) % (@cooks.length)
                puts "(#{@index} of #{limit_num})    uid: #{uid}     cookie: #{@cookie_index}/#{@cooks.length}"
                @info_page = InfoPage.new(@provincename_to_id_hash, @cityname_to_id_hash)
                if @info_page.get(uid, get_cookie) < 0
                  delete_cookie
                  @index += 1
                  next
                end
                @info_page.delete_end_of_line
                info = @info_page.get_info(uid)
                if info.is_a? Integer
                  if info == StatusCode::USER_UNEXIST
                    reset_cookie_fail_counter
                    puts "user with uid #{uid} is not existed."
                    sleep 2
                  elsif info == StatusCode::COOKIE_ERROR               
                    return StatusCode::COOKIE_ERROR if increase_fail_counter == StatusCode::COOKIE_ERROR
                  end
                elsif info.is_a? Hash
                  reset_cookie_fail_counter
                  @info_page.save_info(info)
                  puts "info hash: #{info}"
                end
                sleep 1 if mode.to_s != 'wild'
              end
              return StatusCode::NORMAL
            end

            def get_cookie
              @cooks[@cookie_index]
            end

            def delete_cookie
              @cooks.delete(get_cookie)
              @index -= 1
              puts "delete cookie at #{Time.now}"
            end

            def update_cookies(cookie_owner)
              puts "Get all cookies from db."
              @cooks = []
              Cook.where("page_type = ? and frequent = ? and expired = ? and owner = ? and remark=?", "mobile", false, false, cookie_owner, 'update').each do |cook|
                @cooks.push(cook.content.to_s)
              end
            end

            def reset_cookie_fail_counter
              @cookie_fail_count = 0
            end

            def increase_fail_counter
              delete_cookie
              @cookie_fail_count += 1
              puts "increase fail counter to: #{@cookie_fail_count}"
              return StatusCode::COOKIE_ERROR if @cookie_fail_count >= COOKIE_FAIL_LIMIT
              return StatusCode::NORMAL
            end

            def load_region_to_cache
              Province.all.each do |province|
                @provincename_to_id_hash[province.name] = province.id
                province.cities.each do |city|
                  key = "#{province.id} #{city.name}"
                  @cityname_to_id_hash[key] = city.city_id
                end
              end
            end

        end
      end
    end
  end
end

