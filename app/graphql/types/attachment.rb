module Types
  class Attachment < GraphQL::Schema::Object
    field :id, String, null: false
    field :url, String, null: false
    field :thumbnail_url, String, null: false
    field :blob, BlobType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end