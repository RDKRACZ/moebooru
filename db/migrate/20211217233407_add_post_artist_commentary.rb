class AddPostArtistCommentary < ActiveRecord::Migration[5.1]
  def self.up
    add_column :posts, :artist_commentary, :string, :default => "", :null => "" unless column_exists? :posts, :artist_commentary
  end

  def self.down
    remove_column :posts, :artist_commentary
  end
end
