class CreateProjects < ActiveRecord::Migration[9.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.references :user_group, foreign_key: true
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
