# Changelog

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
