class ServicesController < ApplicationController
  before_action :set_server
  before_action :set_service, only: [:destroy, :check_status]

  def index
    @services = @server.services
  end

  def create
    @service = @server.services.build(service_params)

    if @service.save
      redirect_to server_path(@server), notice: 'Service was successfully added.'
    else
      redirect_to server_path(@server), alert: "Error: #{@service.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @service.destroy
    redirect_to server_path(@server), notice: 'Service was successfully removed.'
  end

  def check_status
    result = @service.check_status

    if result[:success]
      flash[:notice] = "Service status: #{result[:status]}"
    else
      flash[:alert] = "Failed to check service: #{result[:error]}"
    end

    redirect_to server_path(@server)
  end

  private

  def set_server
    @server = Server.joins(:project).merge(current_user_projects).find(params[:server_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to servers_path, alert: 'Server not found or you do not have access.'
  end

  def set_service
    @service = @server.services.find(params[:id])
  end

  def service_params
    params.require(:service).permit(:name, :service_type, :check_command)
  end
end
