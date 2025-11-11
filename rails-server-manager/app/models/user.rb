class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :user_group_memberships, dependent: :destroy
  has_many :user_groups, through: :user_group_memberships
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id', dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :role, inclusion: { in: %w[user admin] }
  validates :email, presence: true, uniqueness: true

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :regular_users, -> { where(role: 'user') }

  # Methods
  def admin?
    role == 'admin'
  end

  def member_of?(user_group)
    user_groups.include?(user_group)
  end

  def can_access_project?(project)
    admin? || project.owner == self || (project.user_group && member_of?(project.user_group))
  end
end
