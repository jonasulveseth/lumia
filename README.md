# Lumia

En holistisk livscoach byggd på Rails 8. Se `docs/overview.md` för konceptet och `CLAUDE.md` för arkitekturen.

```
bundle install
bin/rails db:prepare db:seed
bin/dev            # http://localhost:3078 (3077 är produktionstjänsten)
bin/rails test
```

Kräver PostgreSQL och en språkmodell: lokal Ollama (`.env.example`) eller en `AiProvider` i databasen.
