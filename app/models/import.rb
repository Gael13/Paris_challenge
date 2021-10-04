class Import

  require 'csv'

  attr_reader :file, :errors, :count, :dry_run

  def initialize(params)
    @errors  = Hash.new(0)
    @count   = 0
    # For security purpose dry_run is on by default, set dry_run = 'false' for real import
    @dry_run = params[:dry_run] != 'false'
    @file    = params[:file]
    file_validation
  end

  def perform
    import
  end

  def file_validation
    begin
      csv_read = CSV.read(@file, col_sep: ';')
    rescue CSV::MalformedCSVError => ex
      @errors[:malformed_csv] = ex.message
      return false
    end
    
    if csv_read.blank?
      @errors[:wrong_csv] = 'empty csv file'
      return false
    end

    year_index       = header_index(csv_read[0], 'Année')
    community_index  = header_index(csv_read[0], 'Collectivité')
    contract_index   = header_index(csv_read[0], 'Type de contrat')
    job_index        = header_index(csv_read[0], 'Emplois')
    level_index      = header_index(csv_read[0], 'Niveau')
    speciality_index = header_index(csv_read[0], 'Spécialité')

    return false unless @errors.blank?
    return true
  end

  private

  def header_index(row, source)
    header = row.select { |r| r.downcase == source.downcase }.first

    @errors[:missing_header] = "header matching not found with '#{source}'" if header.blank?
            
    header_index = row.index(header)
    header_index
  end

  def conditions(row)
    {
      community: row[1],
      contract: row[2],
      job: row[3],
      level: row[4],
      speciality: row[5]     
    }
  end

  def insert_row(row)
    staff = Staff.where(conditions(row)).first

    if staff.nil?
      staff = Staff.new
      staff.year       = row[0].to_i
      staff.community  = row[1]
      staff.contract   = row[2]
      staff.job        = row[3]
      staff.level      = row[4]
      staff.speciality = row[5]
      staff.save! unless @dry_run
      @count += 1
    else
      if row[0].to_i > staff.year
        staff.update(year: row[0].to_i) unless @dry_run
      end
    end
  end
  
  def import
    index = 0

    print_time_spent("Csv import") do
      CSV.foreach(@file, col_sep: ';') do |row|
        index += 1
        insert_row(row) unless index == 1
      end
      logger.info " ******************************"
      logger.info " Start import - dry_run #{@dry_run == 'false' ? 'OFF' : 'ON'}"
    end
    logger.info " End - Imported #{@count} lines"
    logger.info " ******************************"
  end

  def logger
    ::Logger.new(STDOUT)
  end

  def print_time_spent(looping)
    time = Benchmark.realtime do
      yield
    end

    logger.info " Time for #{looping}: #{time.round(2)}"
  end

end
