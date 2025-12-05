# Projekt Bazy Danych MS SQL - Produkcja Obuwia

**System zarządzania dla firmy produkującej obuwie**

---

## 📋 Opis projektu

Projekt bazy danych MS SQL dla małej firmy zajmującej się produkcją obuwia, zatrudniającej cholewkarzy, szewców, krojczych, handlowców i pomocników (do pakowania, przygotowania wstępnego do produkcji). Zawiera logiki dodawania faktur, zamówień półproduktów, zamówień gotowych produktów firmy itp.

Logika fakturowania prezentuje mechanizmy automatycznego generowania dokumentów finansowych w bazie danych, ilustrując możliwości systemu w zarządzaniu przepływem finansowym firmy. Jest to sam zarys, pokazana logika, jednakże wpisywanie tutaj faktur wystawionych w zewnętrznych programach pozwoliłoby w bazie śledzić finanse firmy.

> **Projekt jest ciągle rozwijany.** Zawiera kompletną bazę danych, która powinna wystarczyć do obsługi programu wykorzystanego w ów firmie. Zawiera logikę samego fakturowania, zamówień półproduktów, zamówień samych produktów, naliczanie wypłat pracownikom, wypłacanie pracownikom B2B wraz z tworzeniem faktur.

Baza danych stworzona do mojego portfolio w CV, pokazująca moją dotychczas zdobytą wiedzę z zakresu T-SQL. Jest to wersja ulepszona względem poprzedniej - teraz jest możliwe rozwijanie bazy o większą ilość pracowników i ich role, jest przejrzystsza i zawiera wiele więcej funkcji i możliwości rozwoju.

Repozytorium zawiera pliki osobno - dla lepszej czytelności - dla każdej sekcji: triggery, procedury, widoki, tabele. W plikach opisano za co dany trigger/procedura odpowiada.

---

## 🔗 Diagram relacji tabel

[![Diagram bazy danych](https://img.shields.io/badge/🗺️_Zobacz_diagram_relacji_tabel-CLICK_HERE-blue?style=for-the-badge&logo=diagrams.net)](https://dbdiagram.io/d/693284b23c4ea889c6a9b6cc)

*Zależności tabel są jako link do strony dbdiagrams.io, gdyż ich liczba uniemożliwiłaby swobodne odczytanie ich w formie graficznej.*

---

## 📁 Struktura plików

### [**tabele.sql**](https://github.com/mkowalik788/ProjektCV_v2/blob/main/tabele.sql)
Definicje wszystkich tabel w systemie wraz z relacjami i ograniczeniami.
- ✅ **Tabele główne**: Employees, Customers, Products, Orders, Production
- ✅ **Tabele pomocnicze**: Materials, Suppliers, Invoices, Payments
- ✅ **Tabele magazynowe**: InventoryTransactions, MaterialOrders
- ✅ **Relacje**: Klucze obce i ograniczenia integralności

### [**triggery.sql**](https://github.com/mkowalik788/ProjektCV_v2/blob/main/triggery.sql)
Automatyczne mechanizmy zarządzające danymi.
- ✅ **Finanse**: Aktualizacja sald pracowników
- ✅ **Magazyn**: Kontrola stanów materiałów
- ✅ **Produkcja**: Walidacja ilości i statusów
- ✅ **Zamówienia**: Automatyczne obliczanie wartości

### [**procedury.sql**](https://github.com/mkowalik788/ProjektCV_v2/blob/main/procedury.sql)
Procedury składowane do operacji biznesowych.
- ✅ **Finanse**: Wypłaty, fakturowanie, płatności
- ✅ **Magazyn**: Dostawy, zamówienia materiałów
- ✅ **Zamówienia**: Tworzenie nowych zamówień
- ✅ **Raporty**: Raporty produkcyjne, sprzedażowe, finansowe

### [**widoki.sql**](https://github.com/mkowalik788/ProjektCV_v2/blob/main/widoki.sql)
Widoki do szybkiego dostępu do danych.
- ✅ **Dashboard**: Aktualne zamówienia, produkcja w toku
- ✅ **Raporty**: Stan magazynu, faktury do zapłaty
- ✅ **Analiza**: Najlepiej sprzedające się produkty
- ✅ **Monitorowanie**: Aktywni pracownicy, dzisiejsze aktywności

### [**funkcje.sql**](https://github.com/mkowalik788/ProjektCV_v2/blob/main/funkcje.sql)
Funkcje użytkowe dla systemu.
- ✅ **Kalkulacyjne**: Obliczanie wartości zamówień
- ✅ **Walidacyjne**: Sprawdzanie dostępności materiałów
- ✅ **Statusy**: Sprawdzanie gotowości zamówień

- ---

## 🛠️ Technologie

![MS SQL Server](https://img.shields.io/badge/MS_SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-004880?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)

---

## ✨ Funkcjonalności systemu

### 📄 **Fakturowanie**
- ✅ Automatyczne generowanie faktur
- ✅ Opłacanie faktur z aktualizacją statusów
- ✅ Faktury sprzedażowe i kosztowe
- ✅ Wystawianie faktur dla B2B

### 🏭 **Produkcja**
- ✅ Zarządzanie etapami produkcji
- ✅ Automatyczne naliczanie wynagrodzeń
- ✅ Kontrola stanów magazynowych
- ✅ Śledzenie postępu produkcji

### 📦 **Magazyn**
- ✅ Automatyczne pobieranie półproduktów
- ✅ Kontrola stanów materiałów
- ✅ Alerty przy braku materiałów
- ✅ Zamówienia do dostawców

### 🔒 **Zabezpieczenia**
- ✅ Walidacja danych wejściowych
- ✅ Blokowanie niepoprawnych operacji
- ✅ Historia wszystkich transakcji

### 📊 **Raporty**
- ✅ Raporty produkcyjne
- ✅ Raporty sprzedażowe
- ✅ Raporty finansowe
- ✅ Analiza stanu konta firmy

### ⚙️ **Automatyzacja**
- ✅ Automatyczne zmiany statusów
- ✅ Naliczanie wartości sprzedaży
- ✅ Wyliczanie pozostałej produkcji
- ✅ Aktualizacja stanów magazynowych


