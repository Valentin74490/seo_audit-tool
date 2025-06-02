
require 'ferrum'
require 'nokogiri'
require 'open-uri'

class AuditController < ApplicationController


  skip_before_action :verify_authenticity_token

  def create
    domain = params[:input]&.strip
    return render json: { error: "Domaine manquant" }, status: 400 unless domain

    base_url = "https://#{domain}"
    browser = Ferrum::Browser.new(timeout: 15)
    browser.go_to(base_url)
    html = Nokogiri::HTML(browser.body)

    links = html.css("a").map { |a| a["href"] }.compact.uniq
    internal_links = links.select { |link|
      link.start_with?("/") || link.include?(domain)
    }.map { |link|
      URI.join(base_url, link).to_s rescue nil
    }.compact.uniq.first(5)

    result = []

    internal_links.each do |url|
      begin
        browser.go_to(url)
        sleep 2
        html = Nokogiri::HTML(browser.body)

        h1 = html.at('h1')&.text&.strip || "Non détecté"
        meta_description = html.at('meta[name="description"]')&.[]('content')&.strip || "Non détectée"
        meta_title = html.at('title')&.text&.strip || "Non détecté"

        result << {
          url: url,
          h1: h1,
          meta_description: meta_description,
          meta_title: meta_title
        }
      rescue => e
        result << { url: url, error: e.message }
      end
    end

    browser.quit

    render json: { pages: result }
  end
end
