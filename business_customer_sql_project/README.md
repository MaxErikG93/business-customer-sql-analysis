# Business Customer Analytics – SQL Portfolio Project

## Ziel
Fiktives Geschäftskunden-Szenario zum praktischen Aufbau von SQL-Kenntnissen.
Die Daten sind vollständig künstlich erzeugt.

## Tabellen
- `customers` – Geschäftskunden
- `accounts` – Konten
- `transactions` – Kontobewegungen
- `products` – Produkte
- `customer_products` – Kunden-Produkt-Zuordnung

## Beziehungen
- customers 1:N accounts
- accounts 1:N transactions
- customers N:M products über customer_products

## Lernpfad
1. SELECT / FROM / WHERE
2. ORDER BY
3. Aggregationen
4. GROUP BY
5. HAVING
6. INNER JOIN
7. LEFT JOIN
8. Mehrere JOINs
9. COUNT(DISTINCT)
10. CASE WHEN
11. Datumsfunktionen
12. Subqueries
13. CTEs
14. Window Functions
15. komplexere SQL-Logik
16. Performance / Query-Optimierung

## Business-Fragestellungen
- Wie viele Geschäftskunden gibt es?
- Welche Branchen haben die meisten Kunden?
- Wie viele Konten hat jeder Kunde?
- Wie hoch ist das Transaktionsvolumen je Kunde?
- Welche Branchen generieren das höchste Volumen?
- Wie viele Produkte nutzt ein Kunde?
- Welche Kunden liegen über dem durchschnittlichen Transaktionsvolumen?
- Wie entwickelt sich das Transaktionsvolumen über die Monate?
- Welche Kunden sind innerhalb ihrer Branche besonders umsatzstark?

## Wichtig
Die Lösungen werden im Lernprozess selbst entwickelt. Dieses Repository soll am Ende nicht nur SQL-Code zeigen,
sondern nachvollziehbar machen, welche Business-Frage mit welcher Abfrage beantwortet wird.
