class DomainChecker
  attr_reader :domain, :error, :available, :suggestions, :suggestion_results

  DOMAIN_REGEX = /\A[a-zA-Z0-9-]+\.[a-zA-Z]{2,}\z/
  SUGGESTION_PATTERNS = %w[get%s %sapp %shq %sonline try%s %ssite %snow %sweb %spro]
  TLDS = ['.com', '.net', '.org']

  def initialize(domain)
    @domain = domain.to_s.strip.downcase
    @error = nil
    @available = nil
    @suggestions = []
    @suggestion_results = {}
  end

  def valid_format?
    !!(@domain =~ DOMAIN_REGEX)
  end

  def check
    if @domain.blank?
      @error = 'Please enter a domain name.'
      return self
    end
    unless valid_format?
      @error = 'Invalid domain format. Please enter a domain like example.com.'
      return self
    end
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
      return self
    rescue => e
      @error = "Error checking domain: #{e.message}"
      @available = nil
      return self
    end
    generate_suggestions(client)
    self
  end

  def generate_suggestions(client)
    base = @domain.sub(/^www\./, '').sub(/\..*$/, '')
    SUGGESTION_PATTERNS.each do |pattern|
      TLDS.each do |tld|
        sug = pattern % base + tld
        next if sug == @domain
        @suggestions << sug
      end
    end
    @suggestions = @suggestions.uniq.first(10)
    @suggestions.each do |sug|
      begin
        rec = client.lookup(sug)
        sug_parser = rec.parser
        @suggestion_results[sug] = sug_parser.available?
      rescue ArgumentError => e
        @suggestion_results[sug] = nil if e.message.match?(/undefined group name reference/)
      rescue
        @suggestion_results[sug] = nil
      end
    end
  end
end
