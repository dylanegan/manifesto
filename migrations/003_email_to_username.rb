Sequel.migration do
  up do
    alter_table :api_keys do
      rename_column :email, :username
    end
  end

  down do
    alter_table :api_keys do
      rename_column :username, :email
    end
  end
end
