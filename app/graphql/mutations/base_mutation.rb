# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    null false

    def self.requires_authentication?
      true
    end

    def ready?(**_args)
      return true unless self.class.requires_authentication?
      return true if context[:current_user].present?

      raise GraphQL::ExecutionError, (context[:auth_error] || "Authentication required")
    end
  end
end
