class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :servers]

  def index
    @projects = current_user_projects.includes(:servers, :user_group)
  end

  def show
    @servers = @project.servers.includes(:services)
  end

  def new
    @project = Project.new
    @user_groups = current_user.admin? ? UserGroup.all : current_user.user_groups
  end

  def create
    @project = current_user.owned_projects.build(project_params)

    if @project.save
      redirect_to @project, notice: 'Project was successfully created.'
    else
      @user_groups = current_user.admin? ? UserGroup.all : current_user.user_groups
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user_groups = current_user.admin? ? UserGroup.all : current_user.user_groups
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      @user_groups = current_user.admin? ? UserGroup.all : current_user.user_groups
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, notice: 'Project was successfully deleted.'
  end

  def servers
    @servers = @project.servers.includes(:services, :renewals)
  end

  private

  def set_project
    @project = current_user_projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: 'Project not found or you do not have access.'
  end

  def project_params
    params.require(:project).permit(:name, :description, :user_group_id)
  end
end
