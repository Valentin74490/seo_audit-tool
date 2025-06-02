require 'net/http'
require 'json'

class HaloscanApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    input = params[:input]
    return render json: { error: "Domaine manquant" }, status: 400 unless input

    # Headers communs
    headers = {
      "Content-Type" => "application/json",
      "accept" => "application/json",
      "haloscan-api-key" => ENV["HALOSCAN_API_KEY"]
    }

    # 1. Appel à overview
    overview_uri = URI("https://api.haloscan.com/api/domains/overview")
    overview_body = {
      input: input,
      mode: "root",
      requested_data: [
        "metrics", "positions_breakdown", "traffic_value",
        "categories", "best_keywords", "best_pages",
        "gmb_backlinks", "visibility_index_history",
        "positions_breakdown_history", "positions_and_pages_history"
      ]
    }
    overview_response = Net::HTTP.post(overview_uri, overview_body.to_json, headers)
    overview_data = overview_response.code.to_i.in?([200, 201]) ? JSON.parse(overview_response.body) : {}

    # 2. Appel à siteCompetitors
    competitors_uri = URI("https://api.haloscan.com/api/domains/siteCompetitors")
    competitors_body = {
      input: input,
      mode: "auto",
      lineCount: 5,
      order: "desc",
      page: 1
    }
    competitors_response = Net::HTTP.post(competitors_uri, competitors_body.to_json, headers)
    competitors_data = competitors_response.code.to_i.in?([200, 201]) ? JSON.parse(competitors_response.body) : {}

    # 3. Fusion des données
    overview_data["keywords"] = overview_data.dig("best_keywords", "results") || []
    overview_data["competitors"] = competitors_data["results"] || []

    render json: overview_data
  end
end
