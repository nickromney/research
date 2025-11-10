class DashboardController < ApplicationController
  def index
    @projects = current_user_projects.includes(:servers)
    @total_servers = Server.joins(:project).merge(current_user_projects).count
    @online_servers = Server.joins(:project).merge(current_user_projects).online.count
    @total_services = Service.joins(server: :project).merge(current_user_projects).count
    @running_services = Service.joins(server: :project).merge(current_user_projects).running.count
    @pending_renewals = Renewal.joins(server: :project).merge(current_user_projects).due_for_execution.count

    @recent_servers = Server.joins(:project)
                            .merge(current_user_projects)
                            .order(created_at: :desc)
                            .limit(5)
  end
end
