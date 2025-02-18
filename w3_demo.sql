INSERT INTO cars (brand, model, year)
VALUES
  ('Volvo', 'p1800', 1968),
  ('BMW', 'M1', 1978),
  ('Toyota', 'Celica', 1975);

  SELECT * FROM cars;

  ALTER TABLE cars
ALTER COLUMN year TYPE VARCHAR(4);
SELECT * FROM cars
WHERE brand = 'Volvo';

SELECT * FROM cars
WHERE year::INTEGER < 1975;

SELECT * FROM cars
WHERE year::INTEGER > 1975;

SELECT * FROM cars;

SELECT DISTINCT year FROM cars;

SELECT * FROM cars
WHERE model = 'Volvo';

SELECT * FROM cars
ORDER BY year;

SELECT * FROM cars
ORDER BY year DESC;