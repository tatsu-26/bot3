class LinebotController < ApplicationController
  require "line/bot"
  require "wikipedia"

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]  
    }
  end

  def callback
    body = request.body.read

    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      error 400 do "Bad Request" end
    end

    events = client.parse_events_from(body)

    events.each { |event|
      if event.message["text"] != nil
        word = event.message["text"]
        Wikipedia.Configure {
          domain "ja.wikipedia.org"
          path "w/api.php"
        }
      end

      page = Wikipedia.find(word)
      response = page.summary + "\n" + page.fullurl + page.images
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: "text",
            text: event.message["text"]
          }
          client.reply_message(event["replyToken"], message)
        end
      end
    }

    head :ok
  end
end
