class CreateServers < ActiveRecord::Migration[9.0]
  def change
    create_table :servers do |t|
      t.string :name, null: false
      t.string :hostname, null: false
      t.integer :port, default: 22
      t.string :username
      t.text :ssh_key
      t.string :ssh_key_path
      t.text :description
      t.string :status, default: "unknown"
      t.datetime :last_checked_at
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
