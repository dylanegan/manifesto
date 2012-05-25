Sequel.migration do
  up do
    alter_table :manifests do
      add_column :followee_id, Integer
      add_column :follower_override, String
    end
  end

  down do
    alter_table :manifests do
      drop_column :followee_id
      drop_column :follower_override
    end
  end
end
