class DomainsController < ApplicationController
  def new
  end

  def check
    @domain = params[:domain]
    @suggestions = []
    @suggestion_results = {}
    domain_regex = /\A[a-zA-Z0-9-]+\.[a-zA-Z]{2,}\z/
    if @domain.present?
      if @domain.match?(domain_regex)
        require 'whois'
        require 'whois-parser'
        client = Whois::Client.new
        begin
          record = client.lookup(@domain)
          parser = record.parser
          @available = parser.available?
        rescue ArgumentError => e
          if e.message.match?(/undefined group name reference/)
            @error = "Sorry, this domain's WHOIS server is not supported."
          else
            @error = "Error checking domain: #{e.message}"
          end
          @available = nil
        rescue => e
          @error = "Error checking domain: #{e.message}"
          @available = nil
        end

        # Generate suggestions
        base = @domain.sub(/^www\./, '').sub(/\..*$/, '')
        tld = @domain[/\.[^.]+$/] || '.com'
        suggestion_patterns = [
          "get#{base}",
          "#{base}app",
          "#{base}hq",
          "#{base}online",
          "try#{base}",
          "#{base}site",
          "#{base}now",
          "#{base}web",
          "#{base}pro"
        ]
        tlds = ['.com', '.net', '.org']
        suggestion_patterns.each do |s|
          tlds.each do |t|
            next if "#{s}#{t}" == @domain
            @suggestions << "#{s}#{t}"
          end
        end
        # Limit to 10 suggestions
        @suggestions = @suggestions.uniq.first(10)
        @suggestions.each do |sug|
          begin
            rec = client.lookup(sug)
            sug_parser = rec.parser
            @suggestion_results[sug] = sug_parser.available?
          rescue ArgumentError => e
            if e.message.match?(/undefined group name reference/)
              @suggestion_results[sug] = nil
            else
              @suggestion_results[sug] = nil
            end
          rescue
            @suggestion_results[sug] = nil
          end
        end
      else
        @error = "Invalid domain format. Please enter a domain like example.com."
        @available = nil
      end
    else
      @error = "Please enter a domain name."
      @available = nil
    end
    render :new
  end
end
