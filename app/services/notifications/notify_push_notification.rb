class Notifications::NotifyPushNotification < Aldous::Service
  attr_reader :to, :body, :options

  def initialize to, body, options={}
    @to = to.is_a?(Array) ? to : [to]
    @body = body
    @options = options
  end

  def perform
    client = Exponent::Push::Client.new
    to.each_slice(100) do |recipients|
      messages = recipients.map do |to|
        {
          to: to,
          body: @body,
        }.merge(options)
      end

      puts messages
      client.send_messages(messages)
    end

    return Result::Success.new
  end
end