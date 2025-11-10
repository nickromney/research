class RenewalsController < ApplicationController
  before_action :set_renewal, only: [:show, :edit, :update, :destroy, :execute, :test]

  def index
    @renewals = Renewal.joins(server: :project).merge(current_user_projects)
  end

  def show
  end

  def new
    @renewal = Renewal.new
    @servers = Server.joins(:project).merge(current_user_projects)
  end

  def create
    @renewal = Renewal.new(renewal_params)

    if @renewal.save
      redirect_to @renewal, notice: 'Renewal script was successfully created.'
    else
      @servers = Server.joins(:project).merge(current_user_projects)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @servers = Server.joins(:project).merge(current_user_projects)
  end

  def update
    if @renewal.update(renewal_params)
      redirect_to @renewal, notice: 'Renewal script was successfully updated.'
    else
      @servers = Server.joins(:project).merge(current_user_projects)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @renewal.destroy
    redirect_to renewals_url, notice: 'Renewal script was successfully deleted.'
  end

  def execute
    result = @renewal.execute

    if result[:success]
      flash[:notice] = "Renewal executed successfully"
    else
      flash[:alert] = "Renewal execution failed: #{result[:error]}"
    end

    redirect_to @renewal
  end

  def test
    result = @renewal.test_execution

    if result[:success]
      flash[:notice] = "Test successful. Output: #{result[:output]}"
    else
      flash[:alert] = "Test failed: #{result[:error]}"
    end

    redirect_to @renewal
  end

  private

  def set_renewal
    @renewal = Renewal.joins(server: :project).merge(current_user_projects).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to renewals_path, alert: 'Renewal not found or you do not have access.'
  end

  def renewal_params
    params.require(:renewal).permit(:name, :renewal_type, :script, :description, :schedule, :server_id)
  end
end
