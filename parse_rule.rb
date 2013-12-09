  # -*- coding: utf-8 -*-
  module ParseRule
    module Common

    end

    module InWebSearchUsersPage
      REG_EX_FRENQUENCY = /\\u60a8\\u641c\\u7d22\\u592a\\u9891\\u7e41\\u4e86\\uff0c\\u4f11\\u606f\\u4e00\\u4e0b\\u5427\\u3002/
      REG_EX_EXPIRED = /location.replace.+s.weibo.com.+retcode=/
      REG_EX_WRONG_COOKIE = /立即注册微博/
      REG_EX_PERSONLIST = /list_person clearfix.+pl_user_interest/
      REG_EX_UID = /uid=.{0,3}[0-9]{6,}/
      REG_NEW_VERSION_SEARCH_RESULT = /\\u627e\\u5230\s[0-9]+/ #find new page search results
      REG_EX_PAGE = /page=[0-9]+/
      #REG_EX_PAGELIST = /search_page.+pl_common_totalshow/

      CSS_USERS_DOM = ".person_info"
      CSS_RESULT_COUNT = ".search_result"
      CSS_PAGE_COUNT = ".W_pages a"
    end

    module InWebInfoPage
      REG_EX_FOLLOW = /node-type.{1,5}follow.{3}[0-9]+/
      REG_EX_FANS = /node-type.{1,5}fans.{3}[0-9]+/
      REG_EX_WEIBO = /node-type.{1,5}weibo.{3}[0-9]+/
      REG_EX_NUM = /[[:digit:]]+/
      REG_EX_QQ = /QQ\\uff1a[[:digit:]]+/
      REG_EX_EMAIL = /\\u90ae.+7bb1\\uff1a\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/
      REG_EX_MSN = /MSN\\uff1a\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/
      #REG_EX_EXPIRED = /location.replace.+s.weibo.com.+retcode=/
      REG_EX_EXPIRED = /location.replace.+weibo.com.+retcode=/
    end

    module InMobileInfoPage
      REG_GET_SCREEN_NAME = /昵称:(.+?)<br>/
      REG_GET_BIRTHDAY = /生日:(.+?)<br>/
      REG_GET_TAG_HTML = /标签:(.+?)<br>/
      REG_GET_INTRODUCE_HTML = /简介:(.+?)<br>/
      REG_GET_SCHOOL_HTML = /学习经历<\/div>.+?>(.+?)<br><\/div>/
      REG_GET_JOB_HTML = /工作经历<\/div>.+?>(.+?)<br><\/div>/
      REG_GET_CERTIFICATION = /认证:(.+?)<br>/
      REG_EX_MSN = /MSN\\uff1a\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/
      REG_GET_DAREN = /达人:(.+?)<br>/
      REG_REGION = /地区:(.+?)<br>/
      WORD_UNEXIST = "用户不存在哦"
    end

    module InMobileTagsPage
      CSS_TAGS = 'a[href^="/search/?keyword"]'
    end

    module InMobileTimelinePage
      REG_PAGE_COUNT = /\/[0-9]+/
      CSS_WEIBOS = 'div.c[id]'
      CSS_WEIBO_CONTENT = 'span.ctt'
      CSS_WEIBO_TIME_AND_SOURCE = 'span.ct'
      WORD_UNEXIST = "User does not exists"
      WEIBO_DELETED = "此微博已被作者删除"
      WORD_QUIT = "退出"
    end
  end
