class CreateUserGroups < ActiveRecord::Migration[9.0]
  def change
    create_table :user_groups do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    create_table :user_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_group, null: false, foreign_key: true
      t.string :role, default: "member"

      t.timestamps
    end

    add_index :user_group_memberships, [:user_id, :user_group_id], unique: true, name: 'index_user_group_memberships_unique'
  end
end
