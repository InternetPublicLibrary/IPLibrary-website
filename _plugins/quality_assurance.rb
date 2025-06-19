require 'yaml'
require 'uri'
require 'net/http'
require 'digest'
require 'json'
require 'fileutils'

module Jekyll
  module QualityAssurance
    # YAML Schema validation for data files
    class YamlValidator
      REQUIRED_FIELDS = %w[title url description tags access rank last_updated].freeze
      OPTIONAL_FIELDS = %w[author featured language alternate_urls].freeze
      TAG_LIMITS = { min: 1, max: 10 }.freeze
      RANK_RANGE = (1..10).freeze
      ACCESS_TYPES = %w[Free Partially\ paid Paid Registration\ required].freeze

      def self.validate_file(file_path)
        errors = []
        
        begin
          data = YAML.load_file(file_path)
          
          unless data.is_a?(Array)
            errors << "File must contain an array of resources"
            return { valid: false, errors: errors }
          end

          data.each_with_index do |item, index|
            item_errors = validate_item(item, index)
            errors.concat(item_errors)
          end

        rescue Psych::SyntaxError => e
          errors << "YAML syntax error: #{e.message}"
        rescue => e
          errors << "Unexpected error: #{e.message}"
        end

        {
          valid: errors.empty?,
          errors: errors,
          items_count: data&.size || 0
        }
      end

      private

      def self.validate_item(item, index)
        errors = []
        position = "Item #{index + 1}"

        # Check required fields
        REQUIRED_FIELDS.each do |field|
          if item[field].nil? || item[field].to_s.strip.empty?
            errors << "#{position}: Missing required field '#{field}'"
          end
        end

        # Validate specific field formats
        validate_url(item['url'], position, errors) if item['url']
        validate_tags(item['tags'], position, errors) if item['tags']
        validate_rank(item['rank'], position, errors) if item['rank']
        validate_access(item['access'], position, errors) if item['access']
        validate_date(item['last_updated'], position, errors) if item['last_updated']
        validate_description(item['description'], position, errors) if item['description']

        errors
      end

      def self.validate_url(url, position, errors)
        begin
          uri = URI.parse(url.to_s)
          unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            errors << "#{position}: Invalid URL format"
          end
        rescue URI::InvalidURIError
          errors << "#{position}: Invalid URL format"
        end
      end

      def self.validate_tags(tags, position, errors)
        unless tags.is_a?(Array)
          errors << "#{position}: Tags must be an array"
          return
        end

        if tags.size < TAG_LIMITS[:min] || tags.size > TAG_LIMITS[:max]
          errors << "#{position}: Must have #{TAG_LIMITS[:min]}-#{TAG_LIMITS[:max]} tags"
        end

        tags.each do |tag|
          unless tag.is_a?(String) && tag.strip.length > 0
            errors << "#{position}: All tags must be non-empty strings"
            break
          end
        end
      end

      def self.validate_rank(rank, position, errors)
        unless rank.is_a?(Integer) && RANK_RANGE.include?(rank)
          errors << "#{position}: Rank must be an integer between #{RANK_RANGE.first} and #{RANK_RANGE.last}"
        end
      end

      def self.validate_access(access, position, errors)
        unless ACCESS_TYPES.include?(access.to_s)
          errors << "#{position}: Access must be one of: #{ACCESS_TYPES.join(', ')}"
        end
      end

      def self.validate_date(date, position, errors)
        begin
          Date.parse(date.to_s)
        rescue ArgumentError
          errors << "#{position}: Invalid date format for last_updated (use YYYY-MM-DD)"
        end
      end

      def self.validate_description(description, position, errors)
        desc = description.to_s.strip
        if desc.length < 10
          errors << "#{position}: Description too short (minimum 10 characters)"
        elsif desc.length > 500
          errors << "#{position}: Description too long (maximum 500 characters)"
        end
      end
    end

    # URL validation and broken link detection
    class LinkValidator
      TIMEOUT = 10
      MAX_REDIRECTS = 5

      def self.validate_url(url)
        begin
          uri = URI.parse(url)
          response = get_response(uri)
          
          {
            url: url,
            valid: response.is_a?(Net::HTTPSuccess),
            status_code: response.code.to_i,
            response_time: measure_response_time(uri),
            redirect_chain: get_redirect_chain(uri),
            ssl_valid: uri.scheme == 'https' ? check_ssl(uri) : nil,
            content_type: response['content-type']
          }
        rescue => e
          {
            url: url,
            valid: false,
            error: e.message,
            status_code: nil,
            response_time: nil
          }
        end
      end

      def self.validate_urls_in_file(file_path)
        results = []
        
        begin
          data = YAML.load_file(file_path)
          
          if data.is_a?(Array)
            data.each do |item|
              if item['url']
                result = validate_url(item['url'])
                result[:title] = item['title']
                result[:file] = file_path
                results << result
              end
            end
          end
        rescue => e
          results << {
            file: file_path,
            error: e.message,
            valid: false
          }
        end

        results
      end

      private

      def self.get_response(uri, redirects = 0)
        raise "Too many redirects" if redirects > MAX_REDIRECTS

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = TIMEOUT
        http.read_timeout = TIMEOUT

        response = http.get(uri.path.empty? ? '/' : uri.path)

        if response.is_a?(Net::HTTPRedirection)
          location = response['location']
          new_uri = location.start_with?('http') ? URI.parse(location) : URI.join(uri, location)
          return get_response(new_uri, redirects + 1)
        end

        response
      end

      def self.measure_response_time(uri)
        start_time = Time.now
        get_response(uri)
        ((Time.now - start_time) * 1000).round(2)
      rescue
        nil
      end

      def self.get_redirect_chain(uri, chain = [], redirects = 0)
        return chain if redirects > MAX_REDIRECTS

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = TIMEOUT
        http.read_timeout = TIMEOUT

        response = http.get(uri.path.empty? ? '/' : uri.path)
        chain << { url: uri.to_s, status: response.code.to_i }

        if response.is_a?(Net::HTTPRedirection)
          location = response['location']
          new_uri = location.start_with?('http') ? URI.parse(location) : URI.join(uri, location)
          return get_redirect_chain(new_uri, chain, redirects + 1)
        end

        chain
      rescue
        chain
      end

      def self.check_ssl(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        
        begin
          http.start { |h| h.get(uri.path.empty? ? '/' : uri.path) }
          true
        rescue OpenSSL::SSL::SSLError
          false
        end
      rescue
        false
      end
    end

    # Content quality scoring system
    class QualityScorer
      WEIGHTS = {
        description_quality: 0.25,
        tag_relevance: 0.20,
        url_accessibility: 0.20,
        metadata_completeness: 0.15,
        freshness: 0.10,
        title_quality: 0.10
      }.freeze

      def self.score_item(item, link_validation_result = nil)
        scores = {}
        
        scores[:description_quality] = score_description(item['description'])
        scores[:tag_relevance] = score_tags(item['tags'])
        scores[:url_accessibility] = score_url_accessibility(link_validation_result)
        scores[:metadata_completeness] = score_metadata_completeness(item)
        scores[:freshness] = score_freshness(item['last_updated'])
        scores[:title_quality] = score_title(item['title'])

        # Calculate weighted total
        total_score = WEIGHTS.map { |key, weight| scores[key] * weight }.sum
        
        {
          total_score: (total_score * 100).round(1),
          component_scores: scores,
          grade: calculate_grade(total_score),
          suggestions: generate_suggestions(scores, item)
        }
      end

      private

      def self.score_description(description)
        return 0 if description.nil? || description.empty?
        
        desc = description.to_s.strip
        length_score = case desc.length
                      when 0..10 then 0.2
                      when 11..50 then 0.6
                      when 51..150 then 1.0
                      when 151..300 then 0.9
                      else 0.7
                      end
        
        # Check for meaningful content
        word_count = desc.split.length
        word_score = [word_count / 20.0, 1.0].min
        
        # Penalize excessive punctuation or capitalization
        punct_score = desc.count('!?') > 3 ? 0.8 : 1.0
        caps_score = desc.count('A-Z') / desc.length.to_f > 0.3 ? 0.8 : 1.0
        
        [length_score * word_score * punct_score * caps_score, 1.0].min
      end

      def self.score_tags(tags)
        return 0 if tags.nil? || !tags.is_a?(Array) || tags.empty?
        
        # Optimal number of tags
        count_score = case tags.length
                     when 1..2 then 0.6
                     when 3..5 then 1.0
                     when 6..8 then 0.8
                     else 0.5
                     end
        
        # Check for tag quality
        quality_score = tags.map do |tag|
          tag = tag.to_s.strip.downcase
          case tag.length
          when 0..2 then 0.3
          when 3..15 then 1.0
          when 16..25 then 0.8
          else 0.5
          end
        end.sum / tags.length.to_f
        
        count_score * quality_score
      end

      def self.score_url_accessibility(link_result)
        return 0.5 if link_result.nil?
        return 1.0 if link_result[:valid]
        
        # Partial credit for specific issues
        case link_result[:status_code]
        when 200..399 then 1.0
        when 400..499 then 0.3
        when 500..599 then 0.5
        else 0.0
        end
      end

      def self.score_metadata_completeness(item)
        required_fields = %w[title url description tags access rank last_updated]
        optional_fields = %w[author featured language alternate_urls]
        
        required_score = required_fields.count { |field| item[field] && !item[field].to_s.strip.empty? } / required_fields.length.to_f
        optional_score = optional_fields.count { |field| item[field] && !item[field].to_s.strip.empty? } / optional_fields.length.to_f
        
        (required_score * 0.8) + (optional_score * 0.2)
      end

      def self.score_freshness(last_updated)
        return 0 if last_updated.nil?
        
        begin
          date = Date.parse(last_updated.to_s)
          days_old = (Date.today - date).to_i
          
          case days_old
          when 0..30 then 1.0
          when 31..90 then 0.9
          when 91..180 then 0.8
          when 181..365 then 0.6
          when 366..730 then 0.4
          else 0.2
          end
        rescue ArgumentError
          0
        end
      end

      def self.score_title(title)
        return 0 if title.nil? || title.empty?
        
        title = title.to_s.strip
        
        # Length scoring
        length_score = case title.length
                      when 0..5 then 0.3
                      when 6..25 then 1.0
                      when 26..50 then 0.9
                      when 51..80 then 0.7
                      else 0.5
                      end
        
        # Avoid all caps or excessive punctuation
        caps_penalty = title == title.upcase ? 0.7 : 1.0
        punct_penalty = title.count('!?') > 2 ? 0.8 : 1.0
        
        length_score * caps_penalty * punct_penalty
      end

      def self.calculate_grade(score)
        case score
        when 0.9..1.0 then 'A'
        when 0.8..0.89 then 'B'
        when 0.7..0.79 then 'C'
        when 0.6..0.69 then 'D'
        else 'F'
        end
      end

      def self.generate_suggestions(scores, item)
        suggestions = []
        
        if scores[:description_quality] < 0.7
          suggestions << "Improve description quality - aim for 50-150 characters with meaningful content"
        end
        
        if scores[:tag_relevance] < 0.7
          suggestions << "Optimize tags - use 3-5 relevant, specific tags"
        end
        
        if scores[:metadata_completeness] < 0.8
          suggestions << "Complete metadata - consider adding author, language, or alternate URLs"
        end
        
        if scores[:freshness] < 0.6
          suggestions << "Update last_updated date to reflect current information"
        end
        
        if scores[:title_quality] < 0.7
          suggestions << "Improve title - make it clear, concise, and avoid excessive capitalization"
        end
        
        suggestions
      end
    end

    # Duplicate content detection
    class DuplicateDetector
      def self.find_duplicates_in_files(file_paths)
        all_items = {}
        duplicates = []
        
        file_paths.each do |file_path|
          begin
            data = YAML.load_file(file_path)
            next unless data.is_a?(Array)
            
            data.each_with_index do |item, index|
              next unless item['url'] && item['title']
              
              # Create signatures for duplicate detection
              url_signature = normalize_url(item['url'])
              title_signature = normalize_text(item['title'])
              desc_signature = normalize_text(item['description'].to_s)
              
              signature = {
                url: url_signature,
                title: title_signature,
                description: desc_signature,
                file: file_path,
                index: index,
                item: item
              }
              
              # Check for URL duplicates
              if all_items[url_signature]
                duplicates << {
                  type: 'url',
                  original: all_items[url_signature],
                  duplicate: signature,
                  similarity: 1.0
                }
              else
                all_items[url_signature] = signature
              end
              
              # Check for title similarity
              all_items.values.each do |existing|
                next if existing[:file] == file_path && existing[:index] == index
                
                title_similarity = calculate_similarity(title_signature, existing[:title])
                if title_similarity > 0.8
                  duplicates << {
                    type: 'title',
                    original: existing,
                    duplicate: signature,
                    similarity: title_similarity
                  }
                end
              end
            end
          rescue => e
            puts "Error processing #{file_path}: #{e.message}"
          end
        end
        
        duplicates.uniq { |d| [d[:original], d[:duplicate]] }
      end

      private

      def self.normalize_url(url)
        # Remove protocol, www, trailing slashes, and common parameters
        normalized = url.to_s.downcase
        normalized = normalized.gsub(/^https?:\/\//, '')
        normalized = normalized.gsub(/^www\./, '')
        normalized = normalized.gsub(/\/$/, '')
        normalized = normalized.gsub(/\?.*$/, '') # Remove query parameters
        normalized
      end

      def self.normalize_text(text)
        # Convert to lowercase, remove punctuation, normalize whitespace
        text.to_s.downcase.gsub(/[^\w\s]/, ' ').squeeze(' ').strip
      end

      def self.calculate_similarity(str1, str2)
        # Simple Jaccard similarity
        return 1.0 if str1 == str2
        return 0.0 if str1.empty? || str2.empty?
        
        words1 = str1.split.to_set
        words2 = str2.split.to_set
        
        intersection = words1 & words2
        union = words1 | words2
        
        intersection.size.to_f / union.size
      end
    end
  end
end