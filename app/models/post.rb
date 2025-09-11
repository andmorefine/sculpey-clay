class Post < ApplicationRecord
  belongs_to :user
  has_many_attached :imag
  # Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 2000 }
  validates :images, presence: true, unless: -> { Rails.env.test? }
  validates :post_type, inclusion: { in: %w[regular tutorial] }
  validates :difficulty_level, inclusion: { in: %w[beginner intermediate advanced expert] },
            allow_nil: true

  # Custom validation for tutorial posts
  validate :tutorial_must_have_difficulty_level

  # Enums
  enum :post_type, { regular: 0, tutorial: 1 }
  enum :difficulty_level, { beginner: 0, intermediate: 1, advanced: 2, expert: 3 }

  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :tutorials, -> { where(post_type: :tutorial) }
  scope :regular_posts, -> { where(post_type: :regular) }

  def comments_count
    comments.count
  end

  def primary_image
    images.attached? ? images.first : nil
  end

  def thumbnail_url
    return nil unless primary_image

    if primary_image.variable?
      Rails.application.routes.url_helpers.rails_representation_url(
        primary_image.variant(resize_to_limit: [300, 300])
      )
    else
      Rails.application.routes.url_helpers.rails_blob_url(primary_image)
    end
  end

  private

  def tutorial_must_have_difficulty_level
    if tutorial? && difficulty_level.blank?
      errors.add(:difficulty_level, "must be specified for tutorial posts")
    end
  end
end
