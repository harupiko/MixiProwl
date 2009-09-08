#! /opt/local/bin/ruby -w
# -*- mode:ruby; coding:utf-8 -*-
#
# mixi.rb -
#
# Copyright(C) 2007 by mzp
# Author: MIZUNO Hiroki <hiroki1124@gmail.com> 
# http://mzp.sakura.ne.jp/
#
# Timestamp: 2007/08/02 22:17:38
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Ruby itself.
#

require 'openssl'
require 'open-uri'
require 'base64'
require 'rexml/document'
require 'rss'

class Mixi
  def initialize(username,password,member_id=nil)
    @username = username
    @password = password
    @member_id = member_id
    @member_id = get_member_id username,password unless member_id
  end

  def self.entry(*types)
    types.each{|type|
      module_eval <<-END
      def #{type}
        get_entry "#{type}"
      end
      END
    }
  end

  entry :updates,:notify,:tracks,:friends

  private
  def get_entry(type)
    io = open("http://mixi.jp/atom/#{type}/member_id=#{@member_id}",
              'X-WSSE' => wsse(@username,@password))
    REXML::Document.new io
  end

  def get_member_id(username,password)
    io = open('http://mixi.jp/atom/updates',
              'X-WSSE'=>wsse(username,password))
    doc = REXML::Document.new io
    href = doc.elements['/service/workspace/collection'].attributes['href']
    if href =~ /member_id=(\d+)\Z/ then
      $1
    else
      raise "must not happen"
    end
  end

  def wsse(username,password)
    nonce =
      OpenSSL::Digest::SHA1.digest(
        OpenSSL::Digest::SHA1.digest(Time.now.to_s + rand.to_s))
    now = Time.now.utc.iso8601
    digest =
      Base64.encode64(OpenSSL::Digest::SHA1.digest(nonce+now+password)).chop
    %(UsernameToken Username="#{username}", PasswordDigest="#{digest}",)+
      %(Nonce="#{Base64.encode64(nonce).chop}", Created="#{now}")
  end
end

def put_entry(doc)
  doc.elements.each('//entry'){|item|
    puts item.elements['title'].text
  }
end