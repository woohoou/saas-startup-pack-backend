class Notifications::NotifyWhatsapp < Aldous::Service
  attr_reader :phone_number
  attr_reader :message

  def initialize phone_number, message
    @phone_number = phone_number
    @message = message
  end

  def perform
    TWILIO.messages.create(
      body: message,
      from: "whatsapp:#{TWILIO_PHONE_NUMBER}",
      to: "whatsapp:#{phone_number}"
    )
    return Result::Success.new
  end
end