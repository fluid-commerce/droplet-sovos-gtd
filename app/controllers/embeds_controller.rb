class EmbedsController < ApplicationController
  def index
    # hard-coded for now
    params[:company_droplet_uuid] = "cdr_znmpvbr5x7ndkotlhpvnyt5b5qfzvxzf"
    company = Company.find_by(company_droplet_uuid: params[:company_droplet_uuid])
    if company.present? && company.settings.present?
      render :index
    else
      render :initialize
    end
  end
end
