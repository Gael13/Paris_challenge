# bundle exec ruby -Itest test/models/import_test.rb

require 'test_helper'

class ImportTest < ActiveSupport::TestCase

  require 'csv'

  def setup
    Staff.delete_all
  end

  def test_import_good_file_dry_run_on
    file = "#{Rails.root}/tmp/import/effectif_1.csv"

    import = import({file: file})
    import.perform

    assert import.errors.blank?
    assert_equal 0, Staff.all.count
  end

  def test_import_good_file_dry_run_off
    file = "#{Rails.root}/tmp/import/effectif_1.csv"
    row = ["2013", "COMMUNE", "TEMPS INCOMPLET", "CHARGES DE MISSION AGENTS D'EXECUTION", "CHARGE DE MISSION AGENT D'EXECUTION", nil]

    import = import({file: file, dry_run: 'false'})
    import.perform

    assert import.errors.blank?
    assert_equal 139, Staff.all.count

    assert_equal row[0].to_i, Staff.first.year
  end

  def test_import_newest_job
    array = [["Année", "Collectivité", "Type de contrat", "Emplois", "Niveau", "Spécialité"],
             ["2013", "COMMUNE", "TEMPS INCOMPLET", "CHARGES DE MISSION AGENTS D'EXECUTION", "CHARGE DE MISSION AGENT D'EXECUTION", nil],
             ["2015", "COMMUNE", "TEMPS INCOMPLET", "CHARGES DE MISSION AGENTS D'EXECUTION", "CHARGE DE MISSION AGENT D'EXECUTION", nil]  
            ]

    path = "#{Rails.root}/tmp/import"
    filename = 'test_file.csv'
    file = Tempfile.new("#{filename}", "#{path}")

    fill_csv(file, array)

    import = import({file: file, dry_run: 'false'})
    import.perform

    assert import.errors.blank?
    assert_equal 1, Staff.all.count

    assert_equal array[2][0].to_i, Staff.first.year
  end

  ##############################################################################

  def test_import_bad_file
    array = []

    path = "#{Rails.root}/tmp/import"
    filename = 'bad_file.csv'
    file = Tempfile.new("#{filename}", "#{path}")

    errors = [{:wrong_csv => "empty csv file"}]
    fill_csv(file, array)

    import = import({file: file})

    assert_equal errors[0], import.errors

    #########################################
    array = [["Wrong", "Collectivité", "Type de contrat", "Emplois", "Niveau", "Spécialité"],
             ["2013", "COMMUNE", "TEMPS INCOMPLET", "CHARGES DE MISSION AGENTS D'EXECUTION", "CHARGE DE MISSION AGENT D'EXECUTION", nil],
             ["2013", "COMMUNE", "TEMPS INCOMPLET", "COLLABORATEURS D' ELUS", "COLLABORATEUR D ELUS", nil], 
             ["2013", "COMMUNE", "TEMPS INCOMPLET", "ADJOINTS ADMINISTRATIFS", "ANIMATEUR CONTRACTUEL", nil], 
             ["2013", "COMMUNE", "TEMPS INCOMPLET", "PROFESSEURS ATELIERS DES BEAUX ARTS VDP", "PROFESSEUR  ATELIERS  BEAUX ARTS VILLE DE PARIS", nil], 
             ["2013", "COMMUNE", "TEMPS INCOMPLET", "PROFESSEURS DES COURS MUNICIPAUX D'ADULTES", "PROFESSEUR DES COURS MUNICIPAUX D'ADULTES", nil]  
            ]

    path = "#{Rails.root}/tmp/import"
    filename = 'bad_file.csv'
    file = Tempfile.new("#{filename}", "#{path}")

    errors = [{:missing_header => "header matching not found with 'Année'"}]
    fill_csv(file, array)

    import = import({file: file})

    assert_equal errors[0], import.errors

    #########################################
    array[0] = ["Année;Collectivité;Type de contrat;Emplois;Niveau;Wrong"]
    
    path = "#{Rails.root}/tmp/import"
    filename = 'bad_file.csv'
    file = Tempfile.new("#{filename}", "#{path}")

    errors = [{:missing_header => "header matching not found with 'Spécialité'"}]
    fill_csv(file, array)

    import = import({file: file})

    assert_equal errors[0], import.errors
  end

  def import(params)
    Import.new(params)
  end

  def fill_csv(csv, array)
    CSV.open(csv, "w", col_sep: ';') do |csv|
      array.each do |line|
        csv << line
      end
    end
  end

end
