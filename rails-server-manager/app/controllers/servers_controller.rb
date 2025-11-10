class ServersController < ApplicationController
  before_action :set_server, only: [:show, :edit, :update, :destroy, :check_services, :test_connection, :services]

  def index
    @servers = Server.joins(:project).merge(current_user_projects).includes(:project, :services)
  end

  def show
    @services = @server.services
    @renewals = @server.renewals
  end

  def new
    @server = Server.new
    @projects = current_user_projects
  end

  def create
    @server = Server.new(server_params)

    if @server.save
      redirect_to @server, notice: 'Server was successfully created.'
    else
      @projects = current_user_projects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @projects = current_user_projects
  end

  def update
    if @server.update(server_params)
      redirect_to @server, notice: 'Server was successfully updated.'
    else
      @projects = current_user_projects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @server.destroy
    redirect_to servers_url, notice: 'Server was successfully deleted.'
  end

  def test_connection
    result = @server.test_connection

    if result[:success]
      flash[:notice] = "Connection successful: #{result[:message]}"
    else
      flash[:alert] = "Connection failed: #{result[:message]}"
    end

    redirect_to @server
  end

  def check_services
    @server.check_all_services
    redirect_to @server, notice: 'All services have been checked.'
  end

  def services
    @services = @server.services
  end

  private

  def set_server
    @server = Server.joins(:project).merge(current_user_projects).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to servers_path, alert: 'Server not found or you do not have access.'
  end

  def server_params
    params.require(:server).permit(:name, :hostname, :port, :username, :ssh_key, :ssh_key_path, :description, :project_id)
  end
end
