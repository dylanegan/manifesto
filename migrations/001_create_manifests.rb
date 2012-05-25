Sequel.migration do
  up do
    create_table :manifests do
      primary_key :id
      String :name, :unique => true, :null => false
      Time :created_at, :null => false
      Time :updated_at
    end

    create_table :releases do
      primary_key :id
      foreign_key :manifest_id, :manifests, :null => false
      String :components, :null => false, :text => true
      String :diff
      Integer :version, :null => false
      Time :created_at, :null => false
      Time :updated_at
    end
  end

  down do
    drop_table :releases
    drop_table :manifests
  end
end
