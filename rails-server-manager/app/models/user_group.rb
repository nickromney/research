class UserGroup < ApplicationRecord
  # Associations
  has_many :user_group_memberships, dependent: :destroy
  has_many :users, through: :user_group_memberships
  has_many :projects, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true

  # Methods
  def add_user(user, role: 'member')
    user_group_memberships.create(user: user, role: role)
  end

  def remove_user(user)
    user_group_memberships.find_by(user: user)&.destroy
  end

  def has_user?(user)
    users.include?(user)
  end

  def admin_users
    user_group_memberships.where(role: 'admin').map(&:user)
  end
end
