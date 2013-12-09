# -*- coding: utf-8 -*-
module Crawler
  module Weibo
    module Mobile
      module Home
        class TagsPage < Page

          module WeiboSetting
            BASE_TAG_URL ="http://weibo.cn/account/privacy/tags/?uid="
          end

          def initialize
          end

          def get(uid, cookie)
            url = WeiboSetting::BASE_TAG_URL + uid.to_s
            #puts "tags_url: #{url}"
            super("utf-8", cookie, url)
          end

          def tags
            sleep 1
            tags = ""
            if !dom.nil?
              parse(ParseRule::InMobileTagsPage::CSS_TAGS).each do |tag|
                tags += "$"+tag.text
              end
            end
            return tags
          end

        end
      end
    end
  end
end

