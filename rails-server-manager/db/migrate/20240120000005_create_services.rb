class CreateServices < ActiveRecord::Migration[9.0]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.string :service_type, null: false
      t.string :check_command
      t.string :status, default: "unknown"
      t.text :status_output
      t.datetime :last_checked_at
      t.references :server, null: false, foreign_key: true

      t.timestamps
    end
  end
end
