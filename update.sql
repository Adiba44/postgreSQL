CREATE OR REPLACE FUNCTION update_user_data(
    user_id INT,
    update_data JSONB
) RETURNS JSONB AS $$
DECLARE
    authy_updates TEXT := '';   -- Stores updates for authy table
    profile_updates TEXT := ''; -- Stores updates for profile table
    key TEXT;
    value TEXT;
BEGIN
    -- Loop through JSONB keys to determine where each field belongs
    FOR key IN SELECT jsonb_object_keys(update_data) LOOP
        value := quote_literal(update_data->>key);  -- Get value as text with proper quoting

        -- Automatically detect where to update
        CASE 
            WHEN key IN ('user_name', 'user_email', 'user_phone', 'password', 'is_active', 'is_deleted') THEN
                authy_updates := authy_updates || key || ' = ' || value || ', ';
            WHEN key IN ('first_name', 'last_name', 'address') THEN
                profile_updates := profile_updates || key || ' = ' || value || ', ';
        END CASE;
    END LOOP;

    -- Execute update queries dynamically only if there are updates
    IF authy_updates <> '' THEN
        authy_updates := TRIM(TRAILING ', ' FROM authy_updates);
 
        EXECUTE format('UPDATE authy SET %s WHERE user_id = %s', authy_updates, user_id);
    END IF;

    IF profile_updates <> '' THEN
        profile_updates := TRIM(TRAILING ', ' FROM profile_updates);
        EXECUTE format('UPDATE profile SET %s WHERE authy_user_id = %s', profile_updates, user_id);
    END IF;

    RETURN jsonb_build_object('status', 'success', 'message', 'User data updated successfully');
END;
$$ LANGUAGE plpgsql;





SELECT update_user_data(2, '{
    "user_name": "adiba_jahan",
    "user_email": "adiba.jahan@example.com",
    "first_name": "Adiba",
    "last_name": "Jahan",
    "address": "{ \"city\": \"Dhaka\" }"
}'::jsonb);



SELECT update_user_data(3, '{
    "user_name": "adiba_jahan",
    "user_email": "adiba.jahan@example.com",
  
    "address": { "city": "Rangpur",  "country": "bd"}
}'::jsonb);


SELECT * FROM authy WHERE user_id = 3;
SELECT * FROM profile WHERE authy_user_id = 3;

