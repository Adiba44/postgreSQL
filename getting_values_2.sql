CREATE OR REPLACE FUNCTION log_select_queries(user_id TEXT)
RETURNS VOID AS $$
DECLARE
    query_text TEXT;
    table_name TEXT;
    result JSONB;
BEGIN
    -- Get the most recent valid SELECT query
    SELECT query
    INTO query_text
    FROM pg_stat_activity
    WHERE state = 'active'
          AND query ILIKE 'SELECT%'
          AND query NOT ILIKE '%pg_catalog%'
          AND query NOT ILIKE '%pg_type%'
          AND (query ILIKE '%FROM a%' OR query ILIKE '%FROM b%' OR query ILIKE '%FROM c%' OR query ILIKE '%FROM d%')
    ORDER BY query_start DESC
    LIMIT 1;

    -- Extract table name dynamically
    SELECT CASE 
        WHEN query_text ILIKE '%FROM a%' THEN 'a'
        WHEN query_text ILIKE '%FROM b%' THEN 'b'
        WHEN query_text ILIKE '%FROM c%' THEN 'c'
        WHEN query_text ILIKE '%FROM d%' THEN 'd'
        ELSE NULL
    END INTO table_name;

    IF table_name IS NULL THEN
        RAISE EXCEPTION 'No valid table (a, b, c, d) found in query: %', query_text;
    END IF;

    -- Ensure the query is formatted correctly for EXECUTE
    query_text := regexp_replace(query_text, ';.*$', '', 'g');  -- Remove extra SQL statements

    -- Dynamically execute the SELECT query and convert to JSONB
    EXECUTE format(
        'SELECT coalesce(jsonb_agg(row_to_json(t)), ''[]'') FROM (%s) AS t', query_text
    ) INTO result;

    -- Insert into container
    INSERT INTO container (query_time, user_id, query_text, table_name, query_result)
    VALUES (now(), user_id, query_text, table_name, result);
END;
$$ LANGUAGE plpgsql;





SELECT id, value FROM a WHERE id < 5;
SELECT log_select_queries('user1');
SELECT * FROM container ORDER BY query_time DESC LIMIT 1;




SELECT id, value FROM a WHERE id = 5;
SELECT log_select_queries('bdu');
SELECT * FROM container ORDER BY query_time DESC LIMIT 5;

SELECT id, value FROM c LIMIT 3 ;
SELECT log_select_queries('bdu');
SELECT * FROM container ORDER BY query_time DESC LIMIT 5;