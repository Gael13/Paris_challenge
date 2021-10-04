class UploadController < ApplicationController

  require "#{Rails.root}/lib/job_api"

  def index
    @jobs = []

    if File.exist?(File.join(Rails.root, 'public', 'jobs_parity.json'))
      file_list = File.read(File.join(Rails.root, 'public', 'jobs_parity.json'))

      if !file_list.blank? && file_list.is_a?(String)
        @jobs = JSON.parse(file_list)
 
        @jobs
      end
    end 
  end

  def import
    file   = params[:file]
    import = Import.new({file: file, dry_run: 'false'})

    if import.errors.blank?
      import.perform
      redirect_to root_path, notice: 'File was successfully uploaded.'
    else
      redirect_to root_path, alert: import.errors
    end
  end

  def file_parity
    @staffs = Staff.all
    jobs = @staffs.map { |s| s.job }

    job_api = JobApi.new(endpoint, jobs)
    job_api.extract_parity

    if job_api.errors.blank?
      redirect_to root_path, notice: 'Parity was successfully generated.'
      json_file = 'jobs_parity.json'

      if File.exist?(File.join(Rails.root, 'public', json_file))
        File.open(File.join(Rails.root, 'public', json_file), 'w') {|file| file.truncate(0)}
        File.write(File.join(Rails.root, 'public', json_file), JSON.generate(job_api.extract_parity))
      end
    else
      redirect_to root_path, alert: job_api.errors
    end
  end

  private

  def endpoint
    endpoint = "https://opendata.paris.fr/api/records/1.0/search/?dataset=bilan-social-effectifs-non-titulaires-permanents&facet=annee&facet=collectivite&facet=type_de_contrat&facet=emplois&facet=niveau"
  end

end