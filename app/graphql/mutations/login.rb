# frozen_string_literal: true

module Mutations
  class Login < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true

    field :token, String, null: false

    def self.requires_authentication?
      false
    end

    def resolve(email:, password:)
      user = User.find_by(email: email)

      unless user&.authenticate(password)
        raise GraphQL::ExecutionError, "Invalid email or password"
      end

      { token: JwtToken.encode({ user_id: user.id }) }
    end
  end
end
