class AddPositionToAssembliesParts < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_assemblies_parts, :position, :integer, default: 0, null: false
    add_index :spree_assemblies_parts, :position
  end
end
