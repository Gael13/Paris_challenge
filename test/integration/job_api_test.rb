# bundle exec ruby -Itest test/integration/job_api_test.rb

require 'test_helper'
require "#{Rails.root}/lib/job_api"

class JobApiTest < ActionDispatch::IntegrationTest

  def job_api(endpoint, jobs)
    JobApi.new(endpoint, jobs).extract_parity
  end

  def test_api_job
    @staffs = Staff.all
    jobs = @staffs.map { |s| s.job }

    endpoint = "https://opendata.paris.fr/api/records/1.0/search/?dataset=bilan-social-effectifs-non-titulaires-permanents&facet=annee&facet=collectivite&facet=type_de_contrat&facet=emplois&facet=niveau"

    job          = 'CHARGES DE MISSION AGENTS D\'EXECUTION'
    year         = '2018'
    men_count    = 3.0
    women_count  = 0.0
    parity       = 'not applicable'
    valid_parity = false

    VCR.use_cassette('index') do
      response = job_api(endpoint, jobs)

      assert_equal job, response.keys.first
      assert_equal year, response.values.first['year']
      assert_equal men_count, response.values.first['nombre_d_hommes']
      assert_equal women_count, response.values.first['nombre_de_femmes']
      assert_equal parity, response.values.first['parity']
      assert_equal valid_parity, response.values.first['valid_parity']
    end
  end

  def test_api_wrong_endpoint
    @staffs = Staff.all
    jobs = @staffs.map { |s| s.job }

    endpoint = "https://opendata.pariss.fr/api/records/1.0/search/?dataset=bilan-social-effectifs-non-titulaires-permanents&facet=annee&facet=collectivite&facet=type_de_contrat&facet=emplois&facet=niveau"

    VCR.use_cassette('index_error') do
      job_api = JobApi.new(endpoint, jobs)
      job_api.extract_parity
      errors = job_api.errors

      assert_equal 'Can\'t reach Api endpoint', errors[:endpoint]
    end
  end

  def test_api_no_jobs
    jobs = []

    endpoint = "https://opendata.paris.fr/api/records/1.0/search/?dataset=bilan-social-effectifs-non-titulaires-permanents&facet=annee&facet=collectivite&facet=type_de_contrat&facet=emplois&facet=niveau"

    job_api = JobApi.new(endpoint, jobs)
    job_api.extract_parity
    errors = job_api.errors

    assert_equal 'No jobs found in database', errors[:jobs]
  end
end
