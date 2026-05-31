module Sluggable
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
  end

  private

  def source_for_slug
    respond_to?(:title) ? :title : :name
  end
end
