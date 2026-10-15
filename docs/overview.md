# Lumia – översikt

Lumia är en plattform för att bygga sig själv som individ, tvärs över livets områden. Där Bygger/reemove är ett
operativsystem för bolaget är Lumia ett operativsystem för livet.

## Grundidé: ramverk vs innehåll

**Ramverket är samma för alla:**
1. **Nuläge** – hur ser det ut i dag, med egna ord, och en skattning 1–10 per område.
2. **Fokusmål** – ett litet mål per område.
3. **Experiment** – "vad testar jag nu?" med hypotes och slutdatum.
4. **Veckoreflektion** – samma fyra frågor varje vecka: vad gick bra, vad var svårt, vad lärde jag mig, vad är nästa fokus.

**Innehållet är personligt:** användaren markerar vilka skolor och ramverk som resonerar (medelhavskost, LCHF,
stoicism, ACT, Deep Work, Atomic Habits …), vilka man är nyfiken på och vilka man avvisar. Coachen följer valen,
utforskar nyfikenheten och föreslår aldrig det avvisade. Coachstilen (varm, rak, frågande, analytisk) väljs separat.

## Livsområden
Hälsa & kropp · Kost · Sinne & mående · Relationer · Karriär & arbete · Lärande · Ekonomi · Mening & värderingar.
Definieras i `config/lumia/areas.yml`. Användaren kan pausa områden.

## Hur data kommer in
| Källa | Vad händer |
|---|---|
| **Logg** (fri text) | AI:n sorterar in posten under områden, plockar ut mätvärden ("sov 6 h", "humör 4") och sparar bestående fakta som minnen. |
| **Coachchatt** | Det användaren skriver blir också en loggpost och analyseras på samma sätt. |
| **Provsvar** (PDF/text) | Värden med enhet och referensintervall blir mätvärden; avvikande värden flaggas. Sammanfattning utan diagnos. |
| **Mätvärden** | Matas in för hand eller kommer från ovan. |
| **Veckoreflektion** | Skattningar per område uppdaterar livshjulet; coachen svarar med återkoppling och 1–3 små steg. |

## Hur Lumia lär sig vem du är
- **Minne** (`/memories`): korta fakta, preferenser, värderingar och lärdomar. Alltid synligt, redigerbart och raderbart.
- **Mönster** (`/insights`): korrelationer mellan mätvärden och mellan veckoskattningar och mätvärden, tolkade av AI:n
  till insikter med förslag på experiment. Statistiken sparas som bevis på insikten.
- **Coach::Context** samlar profil, områden, ramverk, minnen, experiment, reflektioner, trender och senaste loggposter
  till varje AI-anrop.

## Nästa steg (idéer)
- Fler inflöden: Apple Health/Google Fit, Oura/Garmin, kalender, bildtolkning av provsvar och måltider.
- Vektorsökning (pgvector eller Qdrant som i reemove) när loggen blir för stor för kontextfönstret.
- Påminnelser (veckoreflektion, experiment som löper ut) via mail/push.
- Delning med en mänsklig coach eller partner, med granulär behörighet.
- Superadmin-vy för `AiProvider` (finns i reemove).
