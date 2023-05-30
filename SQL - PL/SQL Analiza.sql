--Utworzy³em bazê danych o nazwie Analiza, zaimportowa³em tabelê z pliku Excela dostêpnego w folderze, 
--i nazwa³em j¹ dbo.WyczDane
--Jeœli chcia³byœ uruchomiæ kod, proszê, zrób to samo.

USE Analiza
SELECT * FROM dbo.WyczDane

--UWAGA--
--Aby sprawdziæ dzia³anie ca³ego kodu, zalecam utworzenie nowego pliku SQL, zaimportowanie pliku Excel, a nastêpnie 
--uruchomienie kodu.

--Sprawdzanie typu danych dla wszystkich kolumn
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'WyczDane'

-----Zmiana typu danych kolumn wynagrodzeñ z pieniê¿nych na liczbowe, aby unikn¹æ przysz³ych problemów z obliczeniami-----

--Tworzenie zduplikowanych kolumn
ALTER TABLE dbo.WyczDane
ADD Min_Numeryczny Money NULL,
	Max_Numeryczny Money NULL,
	Œr_Numeryczny Money NULL

--Kopiowanie zawartoœci kolumn
UPDATE dbo.WyczDane SET Min_Numeryczny = RocznaP³acaMin
UPDATE dbo.WyczDane SET Max_Numeryczny = RocznaP³acaMax
UPDATE dbo.WyczDane SET Œr_Numeryczny = ŒredniaRocznaP³aca

--Zmiana typu danych oryginalnych kolumn
ALTER TABLE dbo.WyczDane
ALTER COLUMN RocznaP³acaMin DECIMAL(22,2) NULL

ALTER TABLE dbo.WyczDane
ALTER COLUMN RocznaP³acaMax DECIMAL(22,2) NULL

ALTER TABLE dbo.WyczDane
ALTER COLUMN ŒredniaRocznaP³aca DECIMAL(22,2) NULL

--Liczenie liczby wierszy w celu sprawdzenia, jakie powinny byæ wyniki kolejnej kwerendy
SELECT COUNT(*) as Liczba_wierszy
FROM dbo.WyczDane

--Sprawdzenie czy wartoœci w wierszach s¹ takie same poprzez porównanie oryginalnych kolumn z liczbowym typem danych
--do ich duplikatów z pieniê¿nym typem danych
SELECT 
SUM(CASE WHEN RocznaP³acaMin = Min_Numeryczny THEN 1 ELSE 0 END) AS Porównanie,
SUM(CASE WHEN RocznaP³acaMax = Max_Numeryczny THEN 1 ELSE 0 END) AS Porównanie,
SUM(CASE WHEN ŒredniaRocznaP³aca = Œr_Numeryczny THEN 1 ELSE 0 END) AS Porównanie
FROM dbo.WyczDane

--Zmiana typu danych zakoñczy³a siê sukcesem, st¹d usuniêcie zduplikowanych kolumn
ALTER TABLE dbo.WyczDane
DROP COLUMN Min_Numeryczny, Max_Numeryczny, Œr_Numeryczny


--------KALKULACJE----------


--TOP 3 Sektory z najwy¿sz¹ Œredni¹ Roczn¹ P³ac¹ bez dodatkowych filtrów
SELECT TOP 3 Sektor, CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(22,2)) as ŒredniaRocznaP³aca,
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
GROUP BY Sektor
ORDER BY ŒredniaRocznaP³aca DESC


--TOP 3 Sektory z najwy¿sz¹ Œredni¹ Roczn¹ P³ac¹ z >= 10 ofertami pracy
SELECT TOP 3 Sektor, CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(22,2)) as ŒredniaRocznaP³aca,
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
GROUP BY Sektor
HAVING COUNT(Sektor) >= 10
ORDER BY ŒredniaRocznaP³aca DESC


--Obliczenie, ile mo¿na zarobiæ w TOP 3 sektorach w porównaniu do œredniej dla wszystkich sektorów
--WTIH CTE musi byæ wykonane razem z poni¿sz¹ kwerend¹
WITH 
Sektory_10 (Sektor)
AS
(
	SELECT Sektor
	FROM dbo.WyczDane
	GROUP BY Sektor
	HAVING COUNT(Sektor) >= 10
),
ŒrWsz_10 (Ca³kŒr)
AS
(
	SELECT CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(22,2)) as ŒredniaRocznaP³aca
	FROM dbo.WyczDane
	WHERE Sektor IN (SELECT Sektor FROM Sektory_10)
),
TOP3_Sektory_Œr (Sektor, ŒredniaRocznaP³aca)
AS
(
	SELECT TOP 3 Sektor, CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(22,2)) as ŒredniaRocznaP³aca
	FROM dbo.WyczDane
	GROUP BY Sektor
	HAVING COUNT(Sektor) >= 10
	ORDER BY ŒredniaRocznaP³aca DESC
)

Select Sektor, CAST(ROUND(((ŒredniaRocznaP³aca/Ca³kŒr) -1)*100, 2) as DECIMAL(22,2)) AS ProcWzrostWyn
from TOP3_Sektory_Œr, ŒrWsz_10



--Znalezienie TOP 3 stanów z najwiêksz¹ liczb¹ ofert pracy i najwy¿szym œrednim wynagrodzeniem dla Information Technology

--Zamiast tworzyæ podzapytanie/WITH CTE postanowi³em rêcznie wpisaæ nazwê sektora i œrednie wynagrodzenie
--poniewa¿ s¹ tylko 3 sektory i dla ka¿dego musimy wpisaæ 2 wartoœci, st¹d
--tworzenie podzapytania/CTE nie wydaje siê najlepszym rozwi¹zaniem
SELECT TOP 3 LokacjaStan, CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) as DECIMAL(22,2)) as ŒredniaRocznaP³aca, 
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
WHERE Sektor = 'Information Technology'
GROUP BY LokacjaStan
HAVING AVG(ŒredniaRocznaP³aca) >= 113191.67
ORDER BY OfertyPracy DESC, ŒredniaRocznaP³aca DESC



--Znalezienie TOP 3 stanów z najwiêksz¹ liczb¹ ofert pracy i najwy¿szym œrednim wynagrodzeniem dla Biotech & Pharmaceuticals
SELECT TOP 3 LokacjaStan, CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) as DECIMAL(22,2)) as ŒredniaRocznaP³aca, 
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
WHERE Sektor = 'Biotech & Pharmaceuticals'
GROUP BY LokacjaStan
HAVING AVG(ŒredniaRocznaP³aca) >= 112441.44
ORDER BY OfertyPracy DESC, ŒredniaRocznaP³aca DESC



----Znalezienie TOP 3 stanów z najwiêksz¹ liczb¹ ofert pracy i najwy¿szym œrednim wynagrodzeniem dla Insurance
SELECT TOP 3 LokacjaStan, CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) as DECIMAL(22,2)) as ŒredniaRocznaP³aca, 
COUNT(*) as OfertyPracy
FROM dbo.WyczDane
WHERE Sektor = 'Insurance'
GROUP BY LokacjaStan
HAVING AVG(ŒredniaRocznaP³aca) >= 105942.03
ORDER BY OfertyPracy DESC, ŒredniaRocznaP³aca DESC


--Utworzenie tymczasowe tabeli w celu zmodyfikowania wartoœci przychodu w taki sposób, aby istnia³y tylko 3 grupy
--pozostawiaj¹c oryginaln¹ tabelê bez zmian
SELECT 
*,
CASE 
	WHEN Przychód IN ('Less than $1 million (USD)', '$1 to $5 million (USD)', '$5 to $10 million (USD)', 
	'$10 to $25 million (USD)', '$25 to $50 million (USD)', '$50 to $100 million (USD)') 
	THEN 'Below $100 Mil' 
	WHEN Przychód IN ('$100 to $500 million (USD)', '$500 million to $1 billion (USD)') 
	THEN 'Between $100 Mil - $1B' 
	WHEN Przychód IN ('$1 to $2 billion (USD)', '$2 to $5 billion (USD)','$5 to $10 billion (USD)',
	'$10+ billion (USD)')
	THEN 'Above $1B'
	ELSE Przychód 
END AS PrzychódG
INTO #PrzychódGrupy
FROM dbo.WyczDane
WHERE Przychód != 'Unknown / Non-Applicable'


--Pokazanie wp³ywu przychodu na liczbê miejsc pracy i œrednie wynagrodzenie w 3 najlepszych stanach z 3 najlepszych sektorach--

--Information Technology
SELECT LokacjaStan AS State, PrzychódG as Przychód, 
CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(10,2)) AS ŒredniaRocznaP³aca, COUNT(*) AS OfertyPracy
FROM #PrzychódGrupy
WHERE Sektor = 'Information Technology'	AND LokacjaStan IN ('CA', 'NY', 'WA')
GROUP BY LokacjaStan, PrzychódG
ORDER BY LokacjaStan ASC


--Biotech & Pharmaceuticals
SELECT LokacjaStan AS State, PrzychódG as Przychód, 
CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(10,2)) AS ŒredniaRocznaP³aca, COUNT(*) AS OfertyPracy
FROM #PrzychódGrupy
WHERE Sektor = 'Biotech & Pharmaceuticals'	AND LokacjaStan IN ('MA', 'CA', 'NY')
GROUP BY LokacjaStan, PrzychódG
ORDER BY LokacjaStan ASC


--Insurance
SELECT LokacjaStan AS State, PrzychódG as Przychód, 
CAST(ROUND(AVG(ŒredniaRocznaP³aca),2) AS DECIMAL(10,2)) AS ŒredniaRocznaP³aca, COUNT(*) AS OfertyPracy
FROM #PrzychódGrupy
WHERE Sektor = 'Insurance'	AND LokacjaStan IN ('NY', 'IL', 'NC')
GROUP BY LokacjaStan, PrzychódG
ORDER BY LokacjaStan ASC
