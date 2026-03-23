# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user_from_auth_header,
      auth_error: @auth_error
    }
    result = RubyGraphqlTutorialSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end

  def current_user_from_auth_header
    auth_header = request.headers["Authorization"]
    return nil if auth_header.blank?

    scheme, token = auth_header.split(" ", 2)
    unless scheme == "Bearer" && token.present?
      @auth_error = "Authorization header must use Bearer token"
      return nil
    end

    payload = JwtToken.decode(token)
    unless payload
      @auth_error = "Invalid or expired token"
      return nil
    end

    user = User.find_by(id: payload["user_id"])
    unless user
      @auth_error = "Invalid token user"
      return nil
    end

    user
  end
end
