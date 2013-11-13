require 'will_paginate'
require 'will_paginate/array'

class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show]

  def index
    page = params[:page] || 1
    perpage = params[:per_page] || 10
    query = params[:query] || ""

    charities = []

    tags = Tag.find(:all, conditions: [ "name LIKE ?", "%#{query}%" ])

    tags.each do |tag|
      charities += tag.charities
    end

    #let's not sqli ourselves in the API
    q = "%#{query}%"
    charity_ids_with_tags = Tags.where("name LIKE ?", q)
    charities = Charity.where("name LIKE ? OR tags.name LIKE ?", q, charity_ids_with_tags)
    results = charities.compact.uniq.paginate(:page => page, :per_page => perpage)

    respond_to do |format|
      if !results.empty?
        format.json { render json: results }
      else
        format.json { render json: {:message => "Not found"}.to_json }
      end
    end
  end

  def show
    charity = Charity.find(params[:id])
    # Return charity.tags in response body
    respond_to do |format|
      if charity
        format.json { render json: charity }
      else
        format.json { head :not_found }
      end
    end
  end
end

