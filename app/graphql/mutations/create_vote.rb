# frozen_string_literal: true

module Mutations
  class CreateVote < BaseMutation
    argument :link_id, ID, required: true

    type Types::VoteType

    def resolve(link_id:)
      Vote.create!(link_id: link_id, user: context[:current_user])
    end
  end
end
