# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'
require "net/http"
require "uri"

class Page

  def initialize
    @dom = nil
    @dom_str = nil
  end

  def get(charset, cookie, url)
    puts "url: #{url}"
    begin
      response = cookie.nil?? open(url) : open(url, 'Cookie' => cookie)
      @dom = Nokogiri::HTML(response, nil, charset)
      @dom_str = @dom.to_s
      return 1
    rescue OpenURI::HTTPError
      puts "doc not found while openning uri"
      return -1
    rescue Errno::ETIMEDOUT
      puts "timeout occured at open uri"
      return -1
    rescue Errno::ENETUNREACH
      puts "network problem occured at open uri"
      return -1
    rescue Exception => details
      puts "error occured at open uri: #{details}"
      return -1
    end
  end

  def empty?
    @dom.nil?
  end

  def dom
    @dom
  end

  def dom_str
    @dom_str = @dom.to_s if @dom_str.nil?
    @dom_str
  end

  def ignore_encode_error
    @dom_str.encode!('UTF-8', 'UTF-8', :invalid => :replace)
  end

  def delete_end_of_line
    @dom_str.gsub(/\n/,'') #去除所有换行
  end

  def parse(rule)
    (rule.is_a? String) ? parse_by_css(rule) : parse_by_regex(rule)
  end

  def match(rule)
    begin
      return @dom_str.match(rule)
    rescue
      puts "error when call match in Page."
      return nil
    end
  end

  def reverse_match(rule)
    begin
      return rule.match(@dom_str).to_s
    rescue
      puts "error when call reverse_match in Page"
      return ""
    end
  end

  def match?(rule)
    begin
      return !@dom_str.match(rule).nil?
    rescue
      puts "error when call match? in Page."
      return nil
    end      
  end

  def contains?(word)
    !@dom_str.index(word).nil?
  end

  private
    def parse_by_css(css_rule)
      @dom.css(css_rule)
    end

    def parse_by_regex(regex_rule)
      begin
        @dom_str.scan(regex_rule)
      rescue
        puts "error when call parse_by_regex? in Page."
        return nil
      end      
    end

end

