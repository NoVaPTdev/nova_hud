# nova_hud

HUD minimalista do NOVA Framework: vida, armadura, fome, sede, estado do veículo (velocidade, combustível, cinto), minimapa e compasso.

## Dependências

- **nova_core** (obrigatório)

## Instalação

1. Coloca a pasta `nova_hud` em `resources/[nova]/`.
2. No `server.cfg`:

```cfg
ensure nova_core
ensure nova_hud
```

## Configuração

Em `config/shared.lua`: framework (nova, esx, qb, ox, custom), compasso (top/bottom/hidden), cinto e debug. Dados do mapa em `data/mapData.lua`.

## Exports (client)

- `toggleHud(visible)` — mostrar/ocultar HUD
- `showServerLabel(text)` — etiqueta do servidor
- `hideServerLabel()` — esconder etiqueta

## Estrutura

- `client/main.lua`, `commands.lua`, `nuicb.lua`
- `config/shared.lua`, `config/functions.lua`
- `modules/` — threads (vida, veículo), seatbelt, frameworks
- `dist/` — UI compilada
- `stream/` — reticle e minimap (opcional)

## Documentação

[NOVA Framework Docs](https://github.com/NoVaPTdev) — guia HUD.

## Licença

Parte do ecossistema NOVA Framework.
