require 'uri'
require 'net/http'

class JobApi

  attr_reader :endpoint, :errors

  def initialize(endpoint, jobs)
    @errors = Hash.new(0)
    @endpoint = endpoint
    @jobs   = jobs
    @errors[:jobs] = 'No jobs found in database' if @jobs.blank?
  end

  def extract_parity
    jobs_parity = {}

    @jobs.each do |job|
      encode_job = URI.encode(job)
      job_api = get(encode_job)

      return unless @errors.blank?

      response = JSON.parse(job_api.body)

      unless response['error'].blank?
        @errors[:response] = response['error']
        return
      end

      jobs_parity = build_parity_response(response['records'], jobs_parity)
    end
    jobs_parity
  end

  private

    def get(job)
      begin
      job_endpoint = parse_uri(job_endpoint(job))

      Net::HTTP::Get.new(job_endpoint).try(&perform)

      rescue SocketError => e
        @errors[:endpoint] = 'Can\'t reach Api endpoint'
      end
    end

    def build_parity_response(response, jobs_parity)
       response.each do |record|

        emplois = record['fields']['emplois']

        if jobs_parity[emplois].blank?
          parity = calcul_parity(record['fields']['nombre_d_hommes'], record['fields']['nombre_de_femmes']) 
          valid_parity = (!parity.is_a?(String) && parity < 15) ? true : false

          jobs_parity[emplois] = {
            'year'             => record['fields']['annee'],
            'nombre_d_hommes'  => record['fields']['nombre_d_hommes'],
            'nombre_de_femmes' => record['fields']['nombre_de_femmes'],
            'parity'           => parity,
            'valid_parity'     => valid_parity
          }
        end

      end
      jobs_parity
    end

    def calcul_parity(men_count, women_count)
      if men_count && women_count && (men_count && women_count) > 0.0
        parity = ((men_count - women_count).abs / ((men_count + women_count) / 2)) * 100
      else
        parity = 'not applicable'
      end

      parity
    end

    def job_endpoint(job)
      @endpoint + "&refine.emplois=#{job}"
    end

    def parse_uri(service_url)
      URI.parse(service_url)
    end

    def http
      @_http ||= begin
        http_instance             = Net::HTTP.new(parse_uri(@endpoint).host, parse_uri(@endpoint).port)
        http_instance.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
        http_instance.use_ssl     = true

        http_instance
      end
    end

    def perform
      lambda do |request|
        http.request(request)
      end
    end

end
