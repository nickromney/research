class UserGroupsController < ApplicationController
  before_action :set_user_group, only: [:show, :edit, :update, :destroy, :add_user, :remove_user]
  before_action :require_admin, except: [:index, :show]

  def index
    @user_groups = current_user.admin? ? UserGroup.all : current_user.user_groups
  end

  def show
    @members = @user_group.user_group_memberships.includes(:user)
  end

  def new
    @user_group = UserGroup.new
  end

  def create
    @user_group = UserGroup.new(user_group_params)

    if @user_group.save
      redirect_to @user_group, notice: 'User group was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user_group.update(user_group_params)
      redirect_to @user_group, notice: 'User group was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user_group.destroy
    redirect_to user_groups_url, notice: 'User group was successfully deleted.'
  end

  def add_user
    user = User.find(params[:user_id])
    role = params[:role] || 'member'

    if @user_group.add_user(user, role: role)
      redirect_to @user_group, notice: 'User was successfully added to the group.'
    else
      redirect_to @user_group, alert: 'Failed to add user to the group.'
    end
  end

  def remove_user
    user = User.find(params[:user_id])
    @user_group.remove_user(user)
    redirect_to @user_group, notice: 'User was successfully removed from the group.'
  end

  private

  def set_user_group
    @user_group = UserGroup.find(params[:id])
  end

  def user_group_params
    params.require(:user_group).permit(:name, :description)
  end

  def require_admin
    unless current_user.admin?
      redirect_to user_groups_path, alert: 'Only administrators can perform this action.'
    end
  end
end
