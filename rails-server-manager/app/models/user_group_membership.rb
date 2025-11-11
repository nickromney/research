class UserGroupMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :user_group

  # Validations
  validates :user_id, uniqueness: { scope: :user_group_id }
  validates :role, inclusion: { in: %w[member admin] }

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
end
