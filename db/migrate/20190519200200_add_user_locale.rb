class AddShowAdvancedEditing < ActiveRecord::Migration[5.1]
  def self.up
    add_column :users, :locale, :string, :default => "", :null => ""
  end

  def self.down
    remove_column :users, :locale
  end
end
