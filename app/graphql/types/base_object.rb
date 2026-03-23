# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    private

    def authenticate_user!
      return if context[:current_user].present?

      raise GraphQL::ExecutionError, (context[:auth_error] || "Authentication required")
    end
  end
end
