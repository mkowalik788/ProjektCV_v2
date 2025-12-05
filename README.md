# Projekt CV MS SQL
Projekt bazy danych MS SQL dla małej firmy zajmującej się produkcją obuwia, zatrudniającą cholewkarzy, szewców, krojczych, handlowców i pomocników (do pakowania, przygotowanie wstępne do produkcji). Zawiera logiki dodawania faktur, zamówień półproduktów, zamówień gotowych produktów firmy itp. 

Projekt jest ciągle rozwijany. Zawiera kompletną bazę danych, która powinna wystarczyć do obsługi programu wykorzystanego w ów firmie. Zawiera logikę samego fakturowania (dodawanie faktur do zamówień, generowanie ich jako rekordy w odpowiednich tabelach), zamówień półproduktów, zamówień samych produktów, naliczanie wypłat pracownikom, wypłacanie pracownikom B2B wraz z tworzeniem faktur. Same pola faktur są zrobione do niezbędnego śledzenia stanu konta firmowego, co pozwoli na generowanie raportów finansowych.

Baza danych stworzona do mojego portfolio w CV, pokazująca moją dotychczas zdobytą wiedzę z zakresu T-SQL. Jest to wersja ulepszona względem poprzedniej - teraz jest możliwe rozwijanie bazy o większa ilość pracowników i ich role, jest przejrzystsza i zawiera wiele więcej funkcji i możliwości rozwoju.

Repozytorium zawiera pliki osobno - dla lepszej czytelności - dla każdej sekcji - triggery, procedury, widoki, tabele. W plikach opisano za co dany trigger/procedura odpowiada. 

##Lista funkcjonalności w bazie to:
- Automatyczne generowanie prostych faktur poprzez triggery,
- dodawanie opłacania faktur sprzedażowych i kosztowych poprzez procedury, zmienianie statusów faktur na "opłacone" lub "częściowo opłacone",
- wystawianie faktur sprzedażowej do danego zamówienia (procedura),
- wypłaty dla pracowników B2B poprzez procedurę, z automatycznym wystawianiem faktury przy wypłacie,
- zapis wszystkich ruchów magazynowych, np. poprzez wydanie materiałów do produkcji (trigger), lub dodawanie dostawy materiałów (procedura) z generowaniem faktur kosztowych w przypadku wpisania wartości w odpowiednie pole, lub też przy aktualizacji produkcji o ilość wydawanego towaru,
- alert (trigger) w przypadku przydzielenia produkcji ze zbyt małym stanem magazynowym półproduktów,
- zabezpieczenia przed niepoprawnymi danymi w procedurach i triggerach,
- automatyczne zmiany statusów zamówień przy zleceniu produkcji (triggery),
- automatyczne naliczanie wartości sprzedaży na podstawie zamówionych towarów (trigger),
- konta pracowników i klientów(loginy, hasła) do możliwej rozbudowy systemu o działający interfejs użytkownika w przyszłości,
- automatyczne wyliczanie ile towaru zostało do wyprodukowania z danego zamówienia (trigger),
- automatyczne naliczanie wynagrodzenia pracowników (B2B) na podstawie ich roli i ilości wyprodukowanego towaru (trigger),
- automatyczne pobieranie półproduktów z magazynu po wydaniu zamówiania do produkcji, aktualizacja pobranego stanu w przypadku zmiany ilości przypisanej produkcji, czy zwrot materiałów w przypadku zmiany statusu na 'Anulowane' (triggery),
- blokowanie usuwania produkcji, zamiast tego automatyczna zmiana statusu na anulowane i ustawienie pracownikom poprawnego stanu konta,
- blokowanie wydania produkcji jeśli nie ma wystarczającej ilości materiałów w magazynie (trigger),
- blokowanie wydania zamówienia do produkcji większej ilości niż jest w zamówieniu,
- zapisywanie wszystkich ruchów, faktur w Payments, dzięki czemu możemy kontrolować stan konta firmy,
- tabele z kontami bankowymi do łatwiejszego rozliczania płatności w przyszłości, jak i z rolami i etapami produkcji (możliwość rozbudowy systemu w przyszłości, lecz wymaga to interfejsu użytkownika),
- śledzenie historii zmian cenów materiałów,
- dodawanie zamówień do dostawców wraz z ilościami materiałów i cenami (procedura), automatyczne naliczanie wartości zamówienia (trigger).
- raporty produkcji, sprzedaży, zamówień, finansowy.
