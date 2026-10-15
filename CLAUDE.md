# Claude Code-instruktioner för Lumia

Lumia är en holistisk livscoach: ett "operativsystem för ditt liv". Strukturen är lånad från syskonappen
reemove (Bygger), men domänen är individen i stället för bolaget. Läs `docs/overview.md` först.

## Changelog
Uppdatera alltid `CHANGELOG.md` vid ändringar. Lägg posten under dagens datum med rätt kategori (Features, Fixes,
Security, Refactoring); skapa datumrubriken överst om den saknas. Committa sedan och skriv in commit-hashen i posten,
t.ex. `(abc1234)`: commit → hash → uppdatera changelog → amend. Pusha när repot har en remote.

## Git
Jobba gärna i en feature branch, men lämna den aldrig kvar: när uppgiften är klar och testad, merga in i `main`
med `--no-ff`, pusha (om remote finns) och ta bort branchen med `git branch -d`. Force-pusha aldrig och skriv aldrig
om historiken på `main`. Lägg till `[skip ci]` i commit-meddelanden om inte användaren ber om CI.

## Miljö
Miljöspecifika inställningar (port, omstart, loggar, AI-modell) står i `CLAUDE.local.md`. Saknas den: utgå från
development (`bin/rails runner` utan `RAILS_ENV`).

## Stack
- Ruby 3.4, Rails 8.1, PostgreSQL
- Hotwire (Turbo + Stimulus), importmap, Tailwind CSS v4
- Solid Queue / Solid Cable / Solid Cache
- AI: `Ai.chat` / `Ai.json` → `InferenceConfig` → `ChatProviders::Ollama` eller `ChatProviders::OpenaiCompatible`.
  Standardprovidern väljs med en `AiProvider`-rad i databasen (som i reemove), annars credentials, annars lokal Ollama.

## Arkitektur i korthet
- **Kataloger i kod, inte databas:** livsområden (`config/lumia/areas.yml`), ramverk/skolor
  (`config/lumia/approaches.yml`) och mätvärden (`config/lumia/metrics.yml`) läses av `Area`, `Approach`, `Metric`
  (`YamlCatalog`). Namn och beskrivningar ligger i locales under `lumia.*`. Nytt område/ramverk = YAML + sv/en.
- **Ramverk vs innehåll:** strukturen (nuläge, fokusmål, veckoreflektion, experiment) är densamma för alla.
  Det personliga är `ApproachChoice` (resonates / curious / rejected), `Memory` och användarens data.
- **Coach::Context** samlar allt Lumia vet om personen och går in i varje AI-anrop. Ny datakälla som coachen
  ska känna till → lägg till en sektion där.
- **Inflöde:** `Entry` (fri text, chatt) → `EntryProcessingJob`/`EntryAnalyzer` (områden, mätvärden, minnen).
  `Document` (provsvar) → `DocumentAnalysisJob`/`DocumentAnalyzer` → `Measurement`.
- **Mönster:** `PatternFinder` räknar korrelationer (dagliga mätvärden, veckoskattningar) och låter AI:n
  formulera `Insight`s. Körs måndagar via `config/recurring.yml` och på begäran.
- **Analyser ska vara idempotenta:** en omkörning ersätter det den skapat tidigare i stället för att dubblera.

## Behörighet
All data hämtas via `current_user` (`current_user.entries.find(...)`), aldrig `Model.find` direkt.
Det finns inga delade resurser mellan användare i dag; `AiProvider` hanteras via konsolen.

## Design och UI — följ stilguiden
Öppna `/style_guide` (källa: `app/helpers/style_guide_helper.rb`) innan du skriver en vy.
- Hämta klasser via `ui_button`, `ui_field`, `ui_surface`, `ui_table`, `ui_badge`, `ui_notice`.
- **Teal är reserverat för den enda huvudhandlingen i en vy.** Allt annat är zinc.
- Områdesfärger går via `area_color(area, :dot|:text|:soft)` – Tailwind måste se hela klassnamnen.
- Dölj aldrig knappar med klassen `hidden` (använd `hidden`-attributet). Upprepa aldrig samma utility på ett element.
- Modaler är `<dialog>` med `showModal()`. Breda tabeller ligger i `overflow-x-auto`.
- Varje färg behöver sin `dark:`-variant. Layouten ska fungera i 390 px bredd utan sidledsscroll.
- Avvik bara när användaren ber om det, och lägg då varianten i stilguiden.

## Frontend
Använd Stimulus-controllers och Turbo Frames/Streams (inkl. broadcasts och `turbo-refresh-method: morph`).
Ingen inline-JS, jQuery eller fristående fetch-anrop. Ikoner: `icon("namn")` (Lucide, ritas av `icons`-controllern).

## i18n — alltid svenska + engelska
All användartext går via i18n med nycklar i **både** `config/locales/sv.yml` och `config/locales/en.yml` i samma
commit. `raise_on_missing_translations` är på i development och test. Text till AI:n (prompts, `principles`) är på
engelska; AI:n svarar på användarens språk via `Coach::Context#language_instruction`.

## Tester
`bin/rails test`. Språkmodellen ersätts av `FakeAi` (`test/test_helpers/fake_ai.rb`): köa svar med
`FakeAi.respond_with(...)`. Integrationstestet `life_flow_test.rb` renderar alla sidor på båda språken – lägg till nya
sidor där.

## Säkerhet och ansvar
Lumia är inte vård. Prompten instruerar coachen att hänvisa till professionell hjälp vid avvikande provvärden eller
tecken på allvarlig psykisk ohälsa – behåll det. Användaren ska alltid kunna se och radera det Lumia minns (`/memories`).
