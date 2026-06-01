class AddCreatableByToResourceTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :resource_templates, :creatable_by, :string, default: "gm", null: false
  end
end
