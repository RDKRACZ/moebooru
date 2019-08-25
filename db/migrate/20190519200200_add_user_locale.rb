class AddUserLocale < ActiveRecord::Migration[5.1]
  def self.up
    add_column :users, :locale, :string, :default => "", :null => "" unless column_exists? :users, :locale
  end

  def self.down
    remove_column :users, :locale
  end
end
