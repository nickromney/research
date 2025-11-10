class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User'
  belongs_to :user_group, optional: true
  has_many :servers, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :owner, presence: true

  # Scopes
  scope :for_user, ->(user) {
    where(owner: user)
      .or(where(user_group_id: user.user_group_ids))
      .distinct
  }

  # Methods
  def accessible_by?(user)
    user.can_access_project?(self)
  end

  def servers_count
    servers.count
  end

  def servers_status_summary
    {
      online: servers.where(status: 'online').count,
      offline: servers.where(status: 'offline').count,
      unknown: servers.where(status: 'unknown').count
    }
  end
end
