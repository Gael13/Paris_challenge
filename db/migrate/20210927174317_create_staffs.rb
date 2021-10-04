class CreateStaffs < ActiveRecord::Migration[6.0]
  def change
    create_table :staffs do |t|
      t.integer :year
      t.string :community
      t.string :contract
      t.string :job
      t.string :level
      t.string :speciality

      t.timestamps
    end
  end
end
