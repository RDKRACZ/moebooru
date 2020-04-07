require "securerandom"

module CaptchaHelper
  def captchaGet()
    part = request.cookies["part"]
    v = Rails.cache.read("captcha_" + part)
    if v.nil?
      v = SecureRandom.hex(3)
      Rails.cache.write("captcha_" + part, v)
    end
    v
  end

  def captchaSet()
    part = request.cookies["part"]
    Rails.cache.write("captcha_" + part, SecureRandom.hex(3))
  end
end
