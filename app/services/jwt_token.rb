# frozen_string_literal: true

class JwtToken
  ALGORITHM = "HS256"

  class << self
    def encode(payload, expires_at: 24.hours.from_now)
      JWT.encode(payload.merge(exp: expires_at.to_i), secret_key, ALGORITHM)
    end

    def decode(token)
      decoded_token = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
      decoded_token.first
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    private

    def secret_key
      Rails.application.secret_key_base
    end
  end
end
