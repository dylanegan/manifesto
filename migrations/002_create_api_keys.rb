Sequel.migration do
  up do
    create_table :api_keys do
      primary_key :id
      String :email, :null => false
      String :key, :null => false
      Time :expires_at, :null => false
      Time :created_at, :null => false
      Time :updated_at
    end
  end

  down do
    drop_table :api_keys
  end
end
