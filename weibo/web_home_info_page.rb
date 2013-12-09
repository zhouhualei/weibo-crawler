# -*- coding: utf-8 -*-
module Crawler
module Weibo
  module Web
    module Home
      class InfoPage < Page
       
        def get(base_url, uid, cookie)
          url = base_url + uid.to_s + '/info'
          #puts "url: #{url}"
          super("utf-8", cookie, url)
        end

        def contact(uid)
          begin
            ignore_encode_error

            qq_html = reverse_match(ParseRule::InWebInfoPage::REG_EX_QQ)
            qq = qq_html.empty??nil: qq_html.split('ff1a').last

            email_html = reverse_match(ParseRule::InWebInfoPage::REG_EX_EMAIL)
            email = email_html.empty??nil: email_html.split('ff1a').last

            msn_html = reverse_match(ParseRule::InWebInfoPage::REG_EX_MSN)
            msn = msn_html.empty??nil : msn.split('ff1a').last

            followers = reverse_match(ParseRule::InWebInfoPage::REG_EX_FOLLOW)
            followers_count = followers.to_s.match(/[0-9]+/).to_s.to_i

            fans = reverse_match(ParseRule::InWebInfoPage::REG_EX_FANS)
            fans_count = fans.to_s.match(/[0-9]+/).to_s.to_i

            weibo = reverse_match(ParseRule::InWebInfoPage::REG_EX_WEIBO)
            weibo_count = weibo.to_s.match(/[0-9]+/).to_s.to_i
                     
            qq = email.split('@').first if qq.nil? && !email.nil? && email.split('@').last == 'qq.com' # email as qq
            email = msn if email.nil? && !msn.nil?                                                     # hotmail as email
            email = "#{qq}@qq.com" if email.nil? && !qq.nil?                                           # qq as email

            status_code = get_status_code(followers, fans, weibo, followers_count, fans_count, weibo_count)
            if status_code == StatusCode::NORMAL
              return {
                :uid => uid,
                :qq => qq,
                :email => email,
                :msn => msn,
                :followers_count => followers_count,
                :fans_count => fans_count,
                :weibo_count => weibo_count
              }
            else
              return status_code
            end
          rescue Exception => details
            puts "match error when call contact in InfoPage: #{details}"
            return StatusCode::MATCH_ERROR
          end
        end

        def save_contact(contact)
          user = User.find_by_uid(contact[:uid])
          if !user.nil? && (user.weibo_count.nil? || user.weibo_count.to_i<contact[:weibo_count])
            user.qq = contact[:qq] if user.qq.nil? || user.qq.empty?
            user.email = contact[:email] if user.email.nil? || user.email.empty?
            user.msn = contact[:msn] if user.msn.nil? || user.msn.empty?
            user.followers_count = contact[:followers_count] if user.followers_count.nil? || user.followers_count.to_i < contact[:followers_count]
            user.fans_count = contact[:fans_count] if user.fans_count.nil? || user.fans_count.to_i < contact[:fans_count]
            user.weibo_count = contact[:weibo_count] if user.weibo_count.nil? || user.weibo_count.to_i < contact[:weibo_count]
            user.has_contact = true
            #p user
            user.save
            puts "user with id #{user.uid} saved."
            puts "QQ:#{user.qq} EMAIL:#{user.email} MSN:#{user.msn} Weibo Count:#{user.weibo_count} Fans Count:#{user.fans_count} Followers Count:#{user.followers_count}" 
          end
        end

        def get_status_code(followers, fans, weibo, followers_count, fans_count, weibo_count)
          if match(ParseRule::InWebInfoPage::REG_EX_EXPIRED).nil?
            if (followers.nil?)&&(fans.nil?)&&(weibo.nil?)
              puts "page is uncompleted"
              return StatusCode::INVALID_PAGE
            end
          else
            puts 'cookie_expired'
            return StatusCode::COOKIE_ERROR
          end
          return StatusCode::NORMAL
        end

        #def is_redirect_page?
        #  !reverse_match(ParseRule::InWebInfoPage::REG_EX_REDIRECT).nil?         
        #end

      end

    end
  end
end
end

