class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end
    events = client.parse_events_from(body)

    events.each { |event|
      case event
      # メッセージが送信された場合
      when Line::Bot::Event::Message
        case event.type
        # メッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: return_message
          }
          client.reply_message(event['replyToken'], message)
        end

    head :ok
  end
  def return_message
    open("http://www.meigensyu.com/quotations/view/random") do |file|
      page = file.read
      page.scan(/<div class=\"text\">(.*?)<\/div>/).each do |meigen|
        return meigen[0].encode("sjis")
      end
    end
  end
end