-- final function
DROP FUNCTION IF EXISTS log_select_queries(TEXT);
DROP TABLE IF EXISTS container;

CREATE TABLE container (
    id SERIAL PRIMARY KEY,
    query_time TIMESTAMP DEFAULT now(),
    user_id TEXT,
    query_text TEXT,
    table_name TEXT,
    query_result JSONB
);

CREATE OR REPLACE FUNCTION log_select_queries(user_id TEXT)
RETURNS VOID AS $$
DECLARE
    query_text TEXT;
    table_name TEXT;
    result JSONB;
BEGIN
    -- 🛑 Fix: Get the last SELECT query for this session
    SELECT query
    INTO query_text
    FROM pg_stat_activity
    WHERE state = 'active'  -- Only active queries
          AND query ILIKE 'SELECT%'
          AND query NOT ILIKE '%pg_catalog%'  -- Ignore system queries
          AND query NOT ILIKE '%pg_type%'
          AND (query ILIKE '%FROM a%' OR query ILIKE '%FROM b%' OR query ILIKE '%FROM c%' OR query ILIKE '%FROM d%')
    ORDER BY query_start DESC
    LIMIT 1;

    -- ✅ Extract the correct table name
    SELECT CASE 
        WHEN query_text ILIKE '%FROM a%' THEN 'a'
        WHEN query_text ILIKE '%FROM b%' THEN 'b'
        WHEN query_text ILIKE '%FROM c%' THEN 'c'
        WHEN query_text ILIKE '%FROM d%' THEN 'd'
        ELSE NULL
    END INTO table_name;

    -- 🛑 Fix: Ensure we log only valid table queries
    IF table_name IS NULL THEN
        RAISE EXCEPTION 'No valid table (a, b, c, d) found in query: %', query_text;
    END IF;

    -- ✅ Get the actual query result as JSON
    EXECUTE format(
        'SELECT coalesce(jsonb_agg(row_to_json(t)), ''[]'') FROM %I t', table_name
    ) INTO result;

    -- ✅ Insert into container table
    INSERT INTO container (query_time, user_id, query_text, table_name, query_result)
    VALUES (now(), user_id, query_text, table_name, result);
END;
$$ LANGUAGE plpgsql;




SELECT * FROM d LIMIT 2;  -- Should store table_name as 'd'
SELECT log_select_queries('user1');
SELECT * FROM container ORDER BY query_time DESC LIMIT 5;


SELECT * FROM b LIMIT 3;  
SELECT log_select_queries('abir');
SELECT * FROM container ORDER BY query_time DESC LIMIT 5;




