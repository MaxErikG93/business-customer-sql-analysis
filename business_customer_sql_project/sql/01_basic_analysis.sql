-- 01_basic_analysis.sql
-- Business Customer Analytics

-- Aufgabe 1:
-- Wie viele Geschäftskunden befinden sich insgesamt in unserem Datensatz?

SELECT COUNT(customer_id) AS Anzahl_Geschaeftskunden
FROM customers;


-- Aufgabe 2:
-- Welche Geschäftskunden kommen aus der Branche IT Services?

SELECT customer_id, company_name
FROM customers
WHERE industry = 'IT Services';


-- Aufgabe 3:
-- Welche Kunden kommen aus Leipzig, alphabetisch nach Firmennamen sortiert?

SELECT customer_id, company_name
FROM customers
WHERE region = 'Leipzig'
ORDER BY company_name;


-- Aufgabe 4:
-- Wie viele Geschäftskunden haben wir in jedem Kundensegment?

SELECT customer_segment, COUNT(customer_id) AS Anzahl
FROM customers
GROUP BY customer_segment;


-- Aufgabe 5:
-- Welche Branchen haben mindestens 5 Geschäftskunden?

SELECT industry, COUNT(customer_id) AS Anzahl_Geschaeftskunden
FROM customers
GROUP BY industry
HAVING COUNT(customer_id) >= 5;
