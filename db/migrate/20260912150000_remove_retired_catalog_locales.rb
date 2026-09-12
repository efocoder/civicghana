class RemoveRetiredCatalogLocales < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:catalog_translations)

    execute "DELETE FROM catalog_translations WHERE locale IN ('tw', 'ee')"
  end

  def down
    # Retired locale content is intentionally not restored.
  end
end
