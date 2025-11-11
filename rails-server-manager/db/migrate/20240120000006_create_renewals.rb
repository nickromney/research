class CreateRenewals < ActiveRecord::Migration[9.0]
  def change
    create_table :renewals do |t|
      t.string :name, null: false
      t.string :renewal_type, null: false
      t.text :script
      t.text :description
      t.datetime :last_executed_at
      t.datetime :next_execution_at
      t.string :schedule
      t.string :status, default: "pending"
      t.text :last_output
      t.references :server, null: false, foreign_key: true

      t.timestamps
    end
  end
end
