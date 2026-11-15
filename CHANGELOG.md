# Changelog

## 2026-11-15

### Features
- Intervjun: när Lumia vet nog visas en "Gå vidare"-knapp direkt i samtalet, inte bara Klar-knappen överst.
- Profilpanelen bredvid intervjun är hopfällbar (sammanfattning, livsområden, ramverk, minnen) och får aldrig bli
  högre än sidan; vad som är öppet står kvar när panelen uppdateras (`disclosure`-controllern). (4aa5d9b)

### Fixes
- Chatten (intervju och coach): svaret kunde hamna ovanför det man skrev, eller inte dyka upp utan omladdning.
  Uppdateringarna gick som broadcasts som kan komma fram i fel ordning eller tappas. Nya meddelanden läggs nu till av
  svaret på formuläret, en äldre version av ett meddelande får aldrig skriva över en nyare, och väntar ett svar utan
  att något händer på 8 s (eller när fliken blir synlig igen) hämtas sidan om med morph. (4aa5d9b)
- Intervjuns mätare visade 70 % fast intervjuaren avrundat: den är nu full vid samma gräns som Klar blir aktiv. (4aa5d9b)
- Onboardingintervjun "frös": profilutkastet och mätaren slutade uppdateras. DeepSeek via Nebius resonerade före varje
  svar och tankarna åt upp `max_tokens`, så JSON-svaret kapades och utkastet kastades tyst. Resonerandet är nu avstängt
  för Nebius (`reasoning_effort: "none"`, som `think: false` för Ollama) – utkastet tar ca 5 s i stället för 25 s.
  Kapade JSON-svar och tomma svar ger ett tydligt fel i loggen, och en tom replik visar felmeddelandet i stället för
  en evig "tänker"-snurra. (862996c)

## 2026-11-08

### Features
- Nebius Token Factory som AI-leverantör: `inference: { provider: nebius, api_key: ... }` i credentials räcker;
  standardmodell `deepseek-ai/DeepSeek-V4.1-Flash-1017`. Utan nyckel används lokal Ollama som förut. (008dc27)

## 2026-11-07

### Infrastructure
- Lumia nås publikt på https://lumia.reemove.ai (Cloudflare → Caddy → `localhost:3077`).
- `lumia.service` ger aldrig upp omstarter (`StartLimitIntervalSec=0`) och väntar på `network-online.target` vid boot. (69ee149)

## 2026-10-16

### Features
- Onboardingen är en intervju i stället för formulär och reglage: namn och språk, sedan ställer Lumia frågor i chatten.
  Profilen (sammanfattning, livsområden med skattning och fokusmål, ramverk, coachstil, minnen) växer fram live
  bredvid samtalet med en mätare för hur väl Lumia känner personen, och sparas när man trycker Klar. (6057242)

## 2026-10-15

### Infrastructure
- Lumia körs som systemd-tjänsten `lumia` i production på port 3077 med Solid Queue i Puma; startar vid boot (`config/lumia.service`).
- Production kör över http på lokala nätet (SSL styrs med `RAILS_ASSUME_SSL`/`RAILS_FORCE_SSL`), databasen med peer-autentisering.
- ufw släpper in 192.168.68.0/24 på port 3077. (c8ccbc1)

### Features
- Ny app: Lumia, en holistisk livscoach på Rails 8.1 med strukturen från reemove (Hotwire, Tailwind, Postgres, Solid Queue, stilguide, AiProvider/InferenceConfig).
- Livsområden, ramverk/skolor och mätvärden som kataloger i `config/lumia/*.yml`, med svenska och engelska texter.
- Registrering, inloggning och onboarding i tre steg: profil och coachstil, livsområden med skattning och fokusmål, val av ramverk.
- Översikt med livshjul, snabblogg, veckoreflektion, pågående experiment, mönster och trender.
- Logg som AI-analyseras: områden, mätvärden och minnen plockas ut automatiskt.
- Provsvar (PDF/text) läses av till mätvärden med referensintervall och en neutral sammanfattning.
- Veckoreflektion med coachens återkoppling och små steg för nästa vecka.
- Experiment med hypotes, utvärdering och lärdomar som sparas i minnet.
- "Vad Lumia vet om dig": synligt och redigerbart minne.
- Mönsterletning tvärs över områden (korrelationer + AI-tolkning), varje måndag och på begäran.
- Coachchatt med strömmade svar och full kontext om personen. (6e91289)
