# frozen_string_literal: true

require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Test User",
      email: "test-user@example.com",
      password: "secret123"
    )

    Link.create!(url: "https://graphql-ruby.org", description: "GraphQL Ruby", user: @user)
  end

  test "login mutation returns a jwt token for valid credentials" do
    post "/graphql", params: {
      query: <<~GRAPHQL,
        mutation Login($email: String!, $password: String!) {
          login(email: $email, password: $password) {
            token
          }
        }
      GRAPHQL
      variables: {
        email: @user.email,
        password: "secret123"
      }
    }

    body = JSON.parse(response.body)
    assert_nil body["errors"]
    assert body.dig("data", "login", "token").present?
  end

  test "login mutation rejects invalid credentials" do
    post "/graphql", params: {
      query: <<~GRAPHQL,
        mutation Login($email: String!, $password: String!) {
          login(email: $email, password: $password) {
            token
          }
        }
      GRAPHQL
      variables: {
        email: @user.email,
        password: "wrong-password"
      }
    }

    body = JSON.parse(response.body)
    assert_equal "Invalid email or password", body.dig("errors", 0, "message")
  end

  test "query requires authentication" do
    post "/graphql", params: {
      query: <<~GRAPHQL
        query {
          allLinks {
            id
          }
        }
      GRAPHQL
    }

    body = JSON.parse(response.body)
    assert_equal "Authentication required", body.dig("errors", 0, "message")
  end

  test "query succeeds with a valid jwt" do
    token = JwtToken.encode({ user_id: @user.id })

    post "/graphql", params: {
      query: <<~GRAPHQL
        query {
          allLinks {
            id
          }
        }
      GRAPHQL
    }, headers: {
      "Authorization" => "Bearer #{token}"
    }

    body = JSON.parse(response.body)
    assert_nil body["errors"]
    assert body.dig("data", "allLinks").is_a?(Array)
  end

  test "me query requires authentication" do
    post "/graphql", params: {
      query: <<~GRAPHQL
        query {
          me {
            id
            email
          }
        }
      GRAPHQL
    }

    body = JSON.parse(response.body)
    assert_equal "Authentication required", body.dig("errors", 0, "message")
  end

  test "me query returns current user with valid jwt" do
    token = JwtToken.encode({ user_id: @user.id })

    post "/graphql", params: {
      query: <<~GRAPHQL
        query {
          me {
            id
            name
            email
          }
        }
      GRAPHQL
    }, headers: {
      "Authorization" => "Bearer #{token}"
    }

    body = JSON.parse(response.body)
    assert_nil body["errors"]
    assert_equal @user.name, body.dig("data", "me", "name")
    assert_equal @user.email, body.dig("data", "me", "email")
  end
end
