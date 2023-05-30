--Utworzy�em baz� danych o nazwie Analiza, zaimportowa�em tabel� z pliku Excela dost�pnego w folderze, 
--i nazwa�em j� dbo.WyczDane
--Je�li chcia�by� uruchomi� kod, prosz�, zr�b to samo.

USE Analiza
SELECT * FROM dbo.WyczDane

--UWAGA--
--Aby sprawdzi� dzia�anie ca�ego kodu, zalecam utworzenie nowego pliku SQL, zaimportowanie pliku Excel, a nast�pnie 
--uruchomienie kodu.

--Sprawdzanie typu danych dla wszystkich kolumn
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'WyczDane'

-----Zmiana typu danych kolumn wynagrodze� z pieni�nych na liczbowe, aby unikn�� przysz�ych problem�w z obliczeniami-----

--Tworzenie zduplikowanych kolumn
ALTER TABLE dbo.WyczDane
ADD Min_Numeryczny Money NULL,
	Max_Numeryczny Money NULL,
	�r_Numeryczny Money NULL

--Kopiowanie zawarto�ci kolumn
UPDATE dbo.WyczDane SET Min_Numeryczny = RocznaP�acaMin
UPDATE dbo.WyczDane SET Max_Numeryczny = RocznaP�acaMax
UPDATE dbo.WyczDane SET �r_Numeryczny = �redniaRocznaP�aca

--Zmiana typu danych oryginalnych kolumn
ALTER TABLE dbo.WyczDane
ALTER COLUMN RocznaP�acaMin DECIMAL(22,2) NULL

ALTER TABLE dbo.WyczDane
ALTER COLUMN RocznaP�acaMax DECIMAL(22,2) NULL

ALTER TABLE dbo.WyczDane
ALTER COLUMN �redniaRocznaP�aca DECIMAL(22,2) NULL

--Liczenie liczby wierszy w celu sprawdzenia, jakie powinny by� wyniki kolejnej kwerendy
SELECT COUNT(*) as Liczba_wierszy
FROM dbo.WyczDane

--Sprawdzenie czy warto�ci w wierszach s� takie same poprzez por�wnanie oryginalnych kolumn z liczbowym typem danych
--do ich duplikat�w z pieni�nym typem danych
SELECT 
SUM(CASE WHEN RocznaP�acaMin = Min_Numeryczny THEN 1 ELSE 0 END) AS Por�wnanie,
SUM(CASE WHEN RocznaP�acaMax = Max_Numeryczny THEN 1 ELSE 0 END) AS Por�wnanie,
SUM(CASE WHEN �redniaRocznaP�aca = �r_Numeryczny THEN 1 ELSE 0 END) AS Por�wnanie
FROM dbo.WyczDane

--Zmiana typu danych zako�czy�a si� sukcesem, st�d usuni�cie zduplikowanych kolumn
ALTER TABLE dbo.WyczDane
DROP COLUMN Min_Numeryczny, Max_Numeryczny, �r_Numeryczny


--------KALKULACJE----------


--TOP 3 Sektory z najwy�sz� �redni� Roczn� P�ac� bez dodatkowych filtr�w
SELECT TOP 3 Sektor, CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(22,2)) as �redniaRocznaP�aca,
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
GROUP BY Sektor
ORDER BY �redniaRocznaP�aca DESC


--TOP 3 Sektory z najwy�sz� �redni� Roczn� P�ac� z >= 10 ofertami pracy
SELECT TOP 3 Sektor, CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(22,2)) as �redniaRocznaP�aca,
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
GROUP BY Sektor
HAVING COUNT(Sektor) >= 10
ORDER BY �redniaRocznaP�aca DESC


--Obliczenie, ile mo�na zarobi� w TOP 3 sektorach w por�wnaniu do �redniej dla wszystkich sektor�w
--WTIH CTE musi by� wykonane razem z poni�sz� kwerend�
WITH 
Sektory_10 (Sektor)
AS
(
	SELECT Sektor
	FROM dbo.WyczDane
	GROUP BY Sektor
	HAVING COUNT(Sektor) >= 10
),
�rWsz_10 (Ca�k�r)
AS
(
	SELECT CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(22,2)) as �redniaRocznaP�aca
	FROM dbo.WyczDane
	WHERE Sektor IN (SELECT Sektor FROM Sektory_10)
),
TOP3_Sektory_�r (Sektor, �redniaRocznaP�aca)
AS
(
	SELECT TOP 3 Sektor, CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(22,2)) as �redniaRocznaP�aca
	FROM dbo.WyczDane
	GROUP BY Sektor
	HAVING COUNT(Sektor) >= 10
	ORDER BY �redniaRocznaP�aca DESC
)

Select Sektor, CAST(ROUND(((�redniaRocznaP�aca/Ca�k�r) -1)*100, 2) as DECIMAL(22,2)) AS ProcWzrostWyn
from TOP3_Sektory_�r, �rWsz_10



--Znalezienie TOP 3 stan�w z najwi�ksz� liczb� ofert pracy i najwy�szym �rednim wynagrodzeniem dla Information Technology

--Zamiast tworzy� podzapytanie/WITH CTE postanowi�em r�cznie wpisa� nazw� sektora i �rednie wynagrodzenie
--poniewa� s� tylko 3 sektory i dla ka�dego musimy wpisa� 2 warto�ci, st�d
--tworzenie podzapytania/CTE nie wydaje si� najlepszym rozwi�zaniem
SELECT TOP 3 LokacjaStan, CAST(ROUND(AVG(�redniaRocznaP�aca),2) as DECIMAL(22,2)) as �redniaRocznaP�aca, 
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
WHERE Sektor = 'Information Technology'
GROUP BY LokacjaStan
HAVING AVG(�redniaRocznaP�aca) >= 113191.67
ORDER BY OfertyPracy DESC, �redniaRocznaP�aca DESC



--Znalezienie TOP 3 stan�w z najwi�ksz� liczb� ofert pracy i najwy�szym �rednim wynagrodzeniem dla Biotech & Pharmaceuticals
SELECT TOP 3 LokacjaStan, CAST(ROUND(AVG(�redniaRocznaP�aca),2) as DECIMAL(22,2)) as �redniaRocznaP�aca, 
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
WHERE Sektor = 'Biotech & Pharmaceuticals'
GROUP BY LokacjaStan
HAVING AVG(�redniaRocznaP�aca) >= 112441.44
ORDER BY OfertyPracy DESC, �redniaRocznaP�aca DESC



----Znalezienie TOP 3 stan�w z najwi�ksz� liczb� ofert pracy i najwy�szym �rednim wynagrodzeniem dla Insurance
SELECT TOP 3 LokacjaStan, CAST(ROUND(AVG(�redniaRocznaP�aca),2) as DECIMAL(22,2)) as �redniaRocznaP�aca, 
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
WHERE Sektor = 'Insurance'
GROUP BY LokacjaStan
HAVING AVG(�redniaRocznaP�aca) >= 105942.03
ORDER BY OfertyPracy DESC, �redniaRocznaP�aca DESC


--Utworzenie tymczasowe tabeli w celu zmodyfikowania warto�ci przychodu w taki spos�b, aby istnia�y tylko 3 grupy
--pozostawiaj�c oryginaln� tabel� bez zmian
SELECT 
*,
CASE 
	WHEN Przych�d IN ('Less than $1 million (USD)', '$1 to $5 million (USD)', '$5 to $10 million (USD)', 
	'$10 to $25 million (USD)', '$25 to $50 million (USD)', '$50 to $100 million (USD)') 
	THEN 'Below $100 Mil' 
	WHEN Przych�d IN ('$100 to $500 million (USD)', '$500 million to $1 billion (USD)') 
	THEN 'Between $100 Mil - $1B' 
	WHEN Przych�d IN ('$1 to $2 billion (USD)', '$2 to $5 billion (USD)','$5 to $10 billion (USD)',
	'$10+ billion (USD)')
	THEN 'Above $1B'
	ELSE Przych�d 
END AS Przych�dG
INTO #Przych�dGrupy
FROM dbo.WyczDane
WHERE Przych�d != 'Unknown / Non-Applicable'


--Pokazanie wp�ywu przychodu na liczb� miejsc pracy i �rednie wynagrodzenie w 3 najlepszych stanach z 3 najlepszych sektorach--

--Information Technology
SELECT LokacjaStan AS State, Przych�dG as Przych�d, 
CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(10,2)) AS �redniaRocznaP�aca, COUNT(*) AS OfertyPracy
FROM #Przych�dGrupy
WHERE Sektor = 'Information Technology'	AND LokacjaStan IN ('CA', 'NY', 'WA')
GROUP BY LokacjaStan, Przych�dG
ORDER BY LokacjaStan ASC


--Biotech & Pharmaceuticals
SELECT LokacjaStan AS State, Przych�dG as Przych�d, 
CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(10,2)) AS �redniaRocznaP�aca, COUNT(*) AS OfertyPracy
FROM #Przych�dGrupy
WHERE Sektor = 'Biotech & Pharmaceuticals'	AND LokacjaStan IN ('MA', 'CA', 'NY')
GROUP BY LokacjaStan, Przych�dG
ORDER BY LokacjaStan ASC


--Insurance
SELECT LokacjaStan AS State, Przych�dG as Przych�d, 
CAST(ROUND(AVG(�redniaRocznaP�aca),2) AS DECIMAL(10,2)) AS �redniaRocznaP�aca, COUNT(*) AS OfertyPracy
FROM #Przych�dGrupy
WHERE Sektor = 'Insurance'	AND LokacjaStan IN ('NY', 'IL', 'NC')
GROUP BY LokacjaStan, Przych�dG
ORDER BY LokacjaStan ASC
